import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../services/navigation_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../l10n/app_localizations.dart';

class DioClient {
  static Dio? _dio;

  // Предотвращает параллельные редиректы на login при нескольких 401 одновременно.
  static bool _isLoggingOut = false;

  // Ключ маркера "тот же юзер, форс-релогин" — пишется в _forceLogout()
  // перед clearTokens(), читается в AuthRepository.login()/verifyOtp(),
  // чтобы не гонять AutoSyncService().onLogout() при релогине того же
  // аккаунта после истечения сессии.
  static const kLastKnownUserIdBeforeForcedLogoutKey =
      'last_known_user_id_before_forced_logout';

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  // Сброс при logout — чтобы новый пользователь получил чистый инстанс
  static void reset() => _dio = null;

  // Вызывается после успешного логина, чтобы следующий 401 в новой сессии
  // снова мог триггернуть auto-logout.
  static void resetLogoutFlag() => _isLoggingOut = false;

  @visibleForTesting
  static Dio createForTesting(HttpClientAdapter adapter) =>
      _createDio(adapter: adapter);

  static Dio _createDio({HttpClientAdapter? adapter}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.instance.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Логгер добавлен ДО _AuthInterceptor: он видит headers раньше, чем
    // туда попадёт Authorization — токен физически не печатается в лог.
    // Только debug — в release логгер выключен полностью.
    if (kDebugMode && adapter == null) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ));
    }
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(_AuthInterceptor(dio, refreshAdapter: adapter));

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  final HttpClientAdapter? refreshAdapter;
  Future<String?>? _refreshFuture;
  int? _refreshRevision;

  static const _revisionKey = 'cloudSessionRevision';
  static const _retryKey = 'cloudAuthRetried';
  static const _publicPaths = {
    'login/',
    'register/',
    'otp/verify/',
    'otp/resend/',
    'password/forgot/',
    'password/resend/',
    'password/verify/',
    'password/reset/',
    'token-refresh/',
  };

  _AuthInterceptor(this.dio, {this.refreshAdapter});

  bool _isPublic(RequestOptions options) => _publicPaths.any(
        (path) => options.uri.path.endsWith('/authentication/users/$path'),
      );

  bool _isCurrent(int revision) => revision == SecureStorage.sessionRevision;

  DioException _staleRequest(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        message: 'Authentication session changed',
      );

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublic(options)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final revision =
        options.extra[_revisionKey] as int? ?? SecureStorage.sessionRevision;
    options.extra[_revisionKey] = revision;
    try {
      final token = await SecureStorage.getAccessToken();
      if (!_isCurrent(revision)) {
        handler.reject(_staleRequest(options));
        return;
      }
      options.headers.remove('Authorization');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final revision = response.requestOptions.extra[_revisionKey] as int?;
    if (revision != null && !_isCurrent(revision)) {
      handler.reject(_staleRequest(response.requestOptions));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isPublic(err.requestOptions)) {
      handler.next(err);
      return;
    }
    final revision = err.requestOptions.extra[_revisionKey] as int?;
    if (revision == null || !_isCurrent(revision)) {
      handler.next(_staleRequest(err.requestOptions));
      return;
    }
    final silent = err.requestOptions.extra['silentAuth'] == true;
    try {
      if (err.requestOptions.extra[_retryKey] == true) {
        await _forceLogout(silent: silent, revision: revision);
        handler.next(err);
        return;
      }

      // A late 401 may belong to the token that another request has already
      // refreshed. Reuse the current token rather than rotate it again.
      var newToken = await SecureStorage.getAccessToken();
      if (newToken == null ||
          err.requestOptions.headers['Authorization'] == 'Bearer $newToken') {
        if (_refreshFuture == null || _refreshRevision != revision) {
          _refreshRevision = revision;
          final pending = _refreshToken(revision);
          _refreshFuture = pending;
          try {
            newToken = await pending;
          } finally {
            if (identical(_refreshFuture, pending)) _refreshFuture = null;
          }
        } else {
          newToken = await _refreshFuture;
        }
      }
      if (!_isCurrent(revision)) {
        handler.next(_staleRequest(err.requestOptions));
        return;
      }
      if (newToken == null) {
        await _forceLogout(silent: silent, revision: revision);
        handler.next(err);
        return;
      }
      err.requestOptions.extra[_retryKey] = true;
      err.requestOptions.headers.remove('Authorization');
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      // Propagate refresh transport/5xx failures as such, not as the original
      // 401: the splash must not erase a session merely because it is offline.
      handler.next(DioException(
        requestOptions: err.requestOptions,
        response: error.response,
        type: error.type,
        error: error.error,
        message: error.message,
      ));
    } catch (error) {
      handler
          .next(DioException(requestOptions: err.requestOptions, error: error));
    }
  }

  Future<String?> _refreshToken(int revision) async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (!_isCurrent(revision) || refreshToken == null) return null;
    final refreshDio = Dio(BaseOptions(
      baseUrl: AppConfig.instance.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    if (refreshAdapter != null) refreshDio.httpClientAdapter = refreshAdapter!;
    try {
      final response = await refreshDio.post(
        '/authentication/users/token-refresh/',
        data: {'refresh_token': refreshToken},
      );
      if (!_isCurrent(revision)) return null;
      final data = response.data;
      final result =
          data is Map && data['result'] is Map ? data['result'] : data;
      final access = result is Map
          ? result['access_token'] ??
              result['access'] ??
              (data is Map ? data['access_token'] ?? data['access'] : null)
          : null;
      final refresh = result is Map
          ? result['refresh_token'] ??
              result['refresh'] ??
              (data is Map ? data['refresh_token'] ?? data['refresh'] : null)
          : null;
      // Refresh rotates both tokens according to MD/swagger.md. A partial pair
      // is not safe to persist or to treat as an expired session.
      if (access is! String ||
          access.trim().isEmpty ||
          refresh is! String ||
          refresh.trim().isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: Response(
              requestOptions: response.requestOptions, statusCode: 502),
          type: DioExceptionType.badResponse,
          message: 'Invalid token refresh response',
        );
      }
      final saved = await SecureStorage.saveRefreshedTokens(
        accessToken: access,
        refreshToken: refresh,
        expectedRevision: revision,
      );
      return saved ? access : null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    } finally {
      // Tests share an adapter; production owns this short-lived client.
      if (refreshAdapter == null) refreshDio.close();
    }
  }

  Future<void> _forceLogout(
      {required bool silent, required int revision}) async {
    if (silent || !_isCurrent(revision) || DioClient._isLoggingOut) return;
    final lastUserId = await SecureStorage.getUserId();
    if (!_isCurrent(revision)) return;
    if (lastUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      if (!_isCurrent(revision)) return;
      await prefs.setString(
          DioClient.kLastKnownUserIdBeforeForcedLogoutKey, lastUserId);
    }
    if (!_isCurrent(revision) || DioClient._isLoggingOut) return;
    DioClient._isLoggingOut = true;
    final bool cleared;
    try {
      cleared = await SecureStorage.clearTokens(expectedRevision: revision);
    } catch (_) {
      DioClient._isLoggingOut = false;
      rethrow;
    }
    if (!cleared || SecureStorage.sessionRevision != revision + 1) return;
    DioClient.reset();

    final navigator = NavigationService.navigatorKey.currentState;
    final context = NavigationService.navigatorKey.currentContext;
    if (navigator == null || context == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
    if (l10n != null) {
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.errorSessionExpiredRelogin)),
      );
    }
  }
}
