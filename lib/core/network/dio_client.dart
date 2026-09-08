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

  static Dio _createDio() {
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
    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ));
    }
    dio.interceptors.add(_AuthInterceptor(dio));

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;

  // Один физический refresh на всю "бурю" параллельных 401 — конкурентные
  // запросы ждут этот же Future и ретраятся с его результатом вместо
  // немедленного провала (раньше только первый запрос ретраился, остальные
  // сразу проваливались 401-кой, даже если refresh секундой позже был успешен).
  Future<String?>? _refreshFuture;

  _AuthInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final silent = err.requestOptions.extra['silentAuth'] == true;
    final newToken = await (_refreshFuture ??=
        _refreshToken(silent).whenComplete(() => _refreshFuture = null));

    if (newToken == null) {
      handler.next(err);
      return;
    }

    try {
      // Не подставляем newToken в headers напрямую — тогда PrettyDioLogger
      // (идёт в цепочке раньше onRequest) залогировал бы новый токен на
      // ретрае. Убираем старый и даём onRequest подставить свежий из
      // SecureStorage уже после логгера.
      err.requestOptions.headers.remove('Authorization');
      final retryResponse = await dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refreshToken(bool silent) async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        await _forceLogout(silent: silent);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.instance.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Только debug — иначе refresh-запрос (единственный, который решает,
      // разлогинить юзера или нет) был полностью невидим в логах, и по факту
      // 401-штормов было невозможно понять, что ответил бэкенд на refresh.
      // Заголовков тут нет (refresh шлёт только тело), так что requestHeader
      // ничего чувствительного не печатает.
      if (kDebugMode) {
        refreshDio.interceptors.add(PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ));
      }

      final response = await refreshDio.post(
        '/authentication/users/token-refresh/',
        data: {'refresh_token': refreshToken},
      );

      final result = response.data is Map &&
              response.data.containsKey('result')
          ? response.data['result']
          : response.data;

      final newAccessToken = (result['access_token'] ??
              result['access'] ??
              response.data['access_token'] ??
              response.data['access'])
          ?.toString();

      final newRefreshToken = (result['refresh_token'] ??
              result['refresh'] ??
              response.data['refresh_token'] ??
              response.data['refresh'])
          ?.toString();

      if (newAccessToken == null) throw Exception('No access token in refresh response');

      await SecureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );

      return newAccessToken;
    } catch (_) {
      await _forceLogout(silent: silent);
      return null;
    }
  }

  // refreshToken() провалился → сессия невалидна.
  // silentAuth (проверка на сплэше) — экран сам чистит токены и решает, что
  // показать пользователю: здесь трогать глобальный logout-стейт нельзя,
  // иначе конкурентный silent-запрос может обнулить токены живой сессии.
  Future<void> _forceLogout({required bool silent}) async {
    if (silent) return;
    if (DioClient._isLoggingOut) return;
    DioClient._isLoggingOut = true;

    final lastUserId = await SecureStorage.getUserId();
    if (lastUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        DioClient.kLastKnownUserIdBeforeForcedLogoutKey,
        lastUserId,
      );
    }

    await SecureStorage.clearTokens();
    DioClient.reset();

    final navigator = NavigationService.navigatorKey.currentState;
    final context = NavigationService.navigatorKey.currentContext;
    if (navigator == null || context == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );

    // context приходит от GlobalKey (NavigationService), а не от State —
    // используется сразу после null-проверки, без промежуточных await.
    // ignore: use_build_context_synchronously
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.errorSessionExpiredRelogin)),
      );
    }
  }
}