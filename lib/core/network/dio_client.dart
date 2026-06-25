import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  // Сброс при logout — чтобы новый пользователь получил чистый инстанс
  static void reset() => _dio = null;

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

    dio.interceptors.add(_AuthInterceptor(dio));
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          await SecureStorage.clearTokens();
          handler.next(err);
          return;
        }

        final refreshDio = Dio(
          BaseOptions(baseUrl: AppConfig.instance.baseUrl),
        );

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

        err.requestOptions.headers['Authorization'] =
        'Bearer $newAccessToken';

        final retryResponse = await dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (refreshErr) {
        // Only clear tokens if the refresh endpoint itself rejected them (401/403).
        // Network errors or server errors should NOT wipe valid tokens.
        if (refreshErr is DioException &&
            (refreshErr.response?.statusCode == 401 ||
                refreshErr.response?.statusCode == 403)) {
          await SecureStorage.clearTokens();
        }
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}