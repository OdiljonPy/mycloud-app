import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/language_notifier.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../sync/auto_sync_service.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  void _ensureCurrentSession(int revision) {
    if (revision != SecureStorage.sessionRevision) {
      throw const AppException(message: 'Authentication session changed');
    }
  }

  Future<int> _saveAuthenticationResponse(
      dynamic data, int expectedRevision) async {
    _ensureCurrentSession(expectedRevision);
    final result = data is Map && data['result'] is Map ? data['result'] : data;
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
    if (access is! String ||
        access.trim().isEmpty ||
        refresh is! String ||
        refresh.trim().isEmpty) {
      throw const AppException(message: 'Invalid authentication response');
    }
    final saved =
        SecureStorage.saveTokens(accessToken: access, refreshToken: refresh);
    final revision = SecureStorage.sessionRevision;
    await saved;
    _ensureCurrentSession(revision);
    DioClient.resetLogoutFlag();
    return revision;
  }

  static Future<void>? _registerInFlight;

  /// Регистрирует текущий FCM-токен устройства на бэкенде. Вызывается
  /// после успешного логина, при onTokenRefresh и при смене языка. Не
  /// критично — сбой не должен ронять экран или логин-флоу.
  ///
  /// Single-flight: конкурентные вызовы (логин + refresh токена + смена
  /// языка могут сработать одновременно) переиспользуют один и тот же
  /// in-flight запрос вместо дублирования POST /notifications/devices/register/.
  static Future<void> registerCurrentDevice() {
    final inFlight = _registerInFlight;
    if (inFlight != null) return inFlight;

    final future = _registerCurrentDeviceInternal();
    _registerInFlight = future;
    future.whenComplete(() => _registerInFlight = null);
    return future;
  }

  static Future<void> _registerCurrentDeviceInternal() async {
    try {
      final accessToken = await SecureStorage.getAccessToken();
      if (accessToken == null) return;

      final token = await PushNotificationService.ensureToken();
      if (token == null) {
        debugPrint(
            '[AuthRepository] registerCurrentDevice: FCM token is null, skipping registration');
        return;
      }
      debugPrint(
          '[AuthRepository] registerCurrentDevice: token=${token.substring(0, 20)}...');

      final deviceId = await PushNotificationService.getDeviceId();
      final language = LanguageNotifier.instance.locale.languageCode;

      await NotificationsRepository().registerDevice(
        token: token,
        deviceId: deviceId,
        isAndroid: Platform.isAndroid,
        language: language,
      );
      debugPrint('[AuthRepository] registerCurrentDevice: success');
    } catch (e) {
      debugPrint('[AuthRepository] registerCurrentDevice failed: $e');
    }
  }

  /// Отписывает текущий FCM-токен устройства. Вызывается при логауте, до
  /// очистки токенов доступа (запрос должен быть аутентифицирован).
  static Future<void> unregisterCurrentDevice() async {
    try {
      final token = PushNotificationService.currentToken;
      if (token == null) return;
      await NotificationsRepository().unregisterDevice(token: token);
    } catch (e) {
      debugPrint('[AuthRepository] unregisterCurrentDevice failed: $e');
    }
  }

  String _extractError(dynamic data) {
    if (data == null) return 'Unknown error';
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('non_field_errors')) {
        final errs = data['non_field_errors'];
        return errs is List ? errs.join(', ') : errs.toString();
      }
      return data.values.join(', ');
    } else if (data is List) {
      return data.join(', ');
    }
    return data.toString();
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    final requestRevision = SecureStorage.sessionRevision;
    try {
      final response = await _dio.post(
        'authentication/users/login/',
        data: {'phone_number': phoneNumber, 'password': password},
      );

      final revision =
          await _saveAuthenticationResponse(response.data, requestRevision);

      final me = await _dio.get('authentication/users/me/');
      _ensureCurrentSession(revision);
      final meData = me.data is Map && (me.data as Map).containsKey('result')
          ? me.data['result']
          : me.data;
      if (meData is! Map || meData['id'] == null) {
        throw const AppException(message: 'Invalid user profile response');
      }
      final newUserId = meData['id'].toString();
      await SecureStorage.saveUserId(newUserId, expectedRevision: revision);
      final fullName = meData['full_name']?.toString();
      if (fullName != null) {
        await SecureStorage.saveFullName(fullName, expectedRevision: revision);
      }

      // Форс-релогин того же аккаунта (сессия протухла в dio_client.dart) —
      // не сбрасываем sync_queue/coldStart/watermark, иначе получаем
      // повторный cold-start скан и риск дублей при fail-open реаплоаде.
      final prefs = await SharedPreferences.getInstance();
      _ensureCurrentSession(revision);
      final lastUserIdBeforeForcedLogout =
          prefs.getString(DioClient.kLastKnownUserIdBeforeForcedLogoutKey);
      await prefs.remove(DioClient.kLastKnownUserIdBeforeForcedLogoutKey);
      if (lastUserIdBeforeForcedLogout == null ||
          lastUserIdBeforeForcedLogout != newUserId) {
        await AutoSyncService().onLogout();
      }

      _ensureCurrentSession(revision);
      AutoSyncService().initialize().then((_) async {
        if (revision != SecureStorage.sessionRevision) return;
        final enabled = await AutoSyncService().isAutoSyncEnabled();
        if (enabled && revision == SecureStorage.sessionRevision) {
          AutoSyncService().startAutoSync().catchError((_) {});
        }
      }).catchError((_) {});
      unawaited(registerCurrentDevice());
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  String _otpKeyFromResponse(dynamic data) {
    final result = data is Map && data['result'] is Map ? data['result'] : data;
    final key = result is Map ? result['otp_key'] : null;
    if (key is! String || key.trim().isEmpty) {
      throw const AppException(message: 'Invalid verification response');
    }
    return key;
  }

  // REGISTER → returns otp_key
  Future<String> register({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'authentication/users/register/',
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'password': password,
        },
      );
      return _otpKeyFromResponse(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  // VERIFY OTP (registration flow only — saves tokens and starts sync)
  Future<void> verifyOtp({required String otpKey, required int otpCode}) async {
    final requestRevision = SecureStorage.sessionRevision;
    try {
      final response = await _dio.post(
        'authentication/users/otp/verify/',
        data: {'otp_key': otpKey, 'otp_code': otpCode},
      );

      final revision =
          await _saveAuthenticationResponse(response.data, requestRevision);

      final me = await _dio.get('authentication/users/me/');
      _ensureCurrentSession(revision);
      final meData = me.data is Map && (me.data as Map).containsKey('result')
          ? me.data['result']
          : me.data;
      if (meData is! Map || meData['id'] == null) {
        throw const AppException(message: 'Invalid user profile response');
      }
      final newUserId = meData['id'].toString();
      await SecureStorage.saveUserId(newUserId, expectedRevision: revision);
      final fullName = meData['full_name']?.toString();
      if (fullName != null) {
        await SecureStorage.saveFullName(fullName, expectedRevision: revision);
      }

      // Форс-релогин того же аккаунта (сессия протухла в dio_client.dart) —
      // не сбрасываем sync_queue/coldStart/watermark, иначе получаем
      // повторный cold-start скан и риск дублей при fail-open реаплоаде.
      final prefs = await SharedPreferences.getInstance();
      _ensureCurrentSession(revision);
      final lastUserIdBeforeForcedLogout =
          prefs.getString(DioClient.kLastKnownUserIdBeforeForcedLogoutKey);
      await prefs.remove(DioClient.kLastKnownUserIdBeforeForcedLogoutKey);
      if (lastUserIdBeforeForcedLogout == null ||
          lastUserIdBeforeForcedLogout != newUserId) {
        await AutoSyncService().onLogout();
      }

      _ensureCurrentSession(revision);
      AutoSyncService().initialize().then((_) async {
        if (revision != SecureStorage.sessionRevision) return;
        final enabled = await AutoSyncService().isAutoSyncEnabled();
        if (enabled && revision == SecureStorage.sessionRevision) {
          AutoSyncService().startAutoSync().catchError((_) {});
        }
      }).catchError((_) {});
      unawaited(registerCurrentDevice());
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  Future<String> resendOtp({required String phoneNumber}) async {
    try {
      final response = await _dio.post(
        'authentication/users/otp/resend/',
        data: {'phone_number': phoneNumber},
      );
      return _otpKeyFromResponse(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  // FORGOT PASSWORD → sends OTP, returns otp_key
  Future<String> forgotPassword({required String phoneNumber}) async {
    try {
      final response = await _dio.post(
        'authentication/users/password/forgot/',
        data: {'phone_number': phoneNumber},
      );
      return _otpKeyFromResponse(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  // RESEND PASSWORD OTP → returns new otp_key
  Future<String> resendPasswordOtp({required String phoneNumber}) async {
    try {
      final response = await _dio.post(
        'authentication/users/password/resend/',
        data: {'phone_number': phoneNumber},
      );
      return _otpKeyFromResponse(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  Future<void> resetPassword({
    required String otpKey,
    required int otpCode,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _dio.patch(
        'authentication/users/password/reset/',
        data: {
          'otp_key': otpKey,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  Future<String> verifyPasswordOtp(
      {required String otpKey, required int otpCode}) async {
    try {
      final response = await _dio.post(
        'authentication/users/password/verify/',
        data: {'otp_key': otpKey, 'otp_code': otpCode},
      );
      return _otpKeyFromResponse(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e,
          fallbackMessage: _extractError(e.response?.data));
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearTokens();
  }
}
