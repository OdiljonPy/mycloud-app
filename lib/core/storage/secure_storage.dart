import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _fullNameKey = 'full_name';

  // Кэш токенов в памяти процесса. Без него каждый onRequest/refresh дёргает
  // платформенное secure storage заново; при таймауте/гонке параллельных
  // чтений (несколько запросов при старте home-страницы) это давало false
  // "токена нет" → ложный 401 → ложный auto-logout с рабочими токенами.
  // Кэшируем только успешные непустые чтения — null (таймаут/ошибка) не
  // кэшируется, чтобы не закрепить случайный сбой на весь сеанс.
  static String? _accessTokenCache;
  static String? _refreshTokenCache;
  static bool get hasCachedAccessToken => _accessTokenCache?.isNotEmpty == true;

  // Login/logout changes the owner of pending requests. Refresh keeps this
  // revision, so concurrent requests in the same session can share its result.
  static int _sessionRevision = 0;
  static int get sessionRevision => _sessionRevision;
  static Future<void> _writes = Future<void>.value();

  static Future<T> _write<T>(Future<T> Function() action) {
    final operation = _writes.then((_) => action());
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  static Future<String?> _safeRead(String key) async {
    await _writes;
    try {
      return await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] read($key) failed: $e');
      return null;
    }
  }

  static Future<void> saveFullName(String name, {int? expectedRevision}) =>
      _write(() async {
        if (expectedRevision != null && expectedRevision != _sessionRevision) {
          return;
        }
        try {
          await _storage.write(key: _fullNameKey, value: name);
        } catch (e) {
          if (kDebugMode) debugPrint('[SecureStorage] saveFullName failed: $e');
        }
      });

  static Future<String?> getFullName() async {
    return _safeRead(_fullNameKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) {
      return Future<void>.error(
        const AppException(message: 'Invalid authentication response'),
      );
    }
    final revision = ++_sessionRevision;
    _accessTokenCache = null;
    _refreshTokenCache = null;
    return _write(() async {
      if (revision != _sessionRevision) return;
      await _storeTokens(accessToken, refreshToken, revision);
    });
  }

  static Future<bool> saveRefreshedTokens({
    required String accessToken,
    required String refreshToken,
    required int expectedRevision,
  }) =>
      _write(() async {
        if (expectedRevision != _sessionRevision) return false;
        await _storeTokens(accessToken, refreshToken, expectedRevision);
        return expectedRevision == _sessionRevision;
      });

  static Future<void> _storeTokens(
    String accessToken,
    String refreshToken,
    int revision,
  ) async {
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) {
      throw const AppException(message: 'Invalid authentication response');
    }
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Do not leave a partially rotated pair available after a failed write.
      _accessTokenCache = null;
      _refreshTokenCache = null;
      try {
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      } catch (_) {}
      throw const AppException(
          message: 'Could not save authentication session');
    }
    if (revision == _sessionRevision) {
      _accessTokenCache = accessToken;
      _refreshTokenCache = refreshToken;
    }
  }

  static Future<void> saveUserId(String userId, {int? expectedRevision}) =>
      _write(() async {
        if (expectedRevision != null && expectedRevision != _sessionRevision) {
          return;
        }
        try {
          await _storage.write(key: _userIdKey, value: userId);
        } catch (_) {
          throw const AppException(
              message: 'Could not save authentication session');
        }
      });

  static Future<String?> getUserId() async {
    return _safeRead(_userIdKey);
  }

  static Future<String?> _readToken(String key, int revision) async {
    await _writes;
    if (revision != _sessionRevision) return null;
    try {
      final token =
          await _storage.read(key: key).timeout(const Duration(seconds: 8));
      if (revision != _sessionRevision) return null;
      return token == null || token.trim().isEmpty ? null : token;
    } catch (_) {
      throw const AppException(
          message: 'Could not read authentication session');
    }
  }

  static Future<String?> getAccessToken() async {
    if (_accessTokenCache != null) return _accessTokenCache;
    final revision = _sessionRevision;
    final token = await _readToken(_accessTokenKey, revision);
    if (revision == _sessionRevision) _accessTokenCache = token;
    return token;
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshTokenCache != null) return _refreshTokenCache;
    final revision = _sessionRevision;
    final token = await _readToken(_refreshTokenKey, revision);
    if (revision == _sessionRevision) _refreshTokenCache = token;
    return token;
  }

  static Future<bool> clearTokens({int? expectedRevision}) {
    if (expectedRevision != null && expectedRevision != _sessionRevision) {
      return Future<bool>.value(false);
    }
    final revision = ++_sessionRevision;
    _accessTokenCache = null;
    _refreshTokenCache = null;
    return _write(() async {
      if (revision != _sessionRevision) return false;
      try {
        await _storage.deleteAll();
      } catch (_) {
        throw const AppException(
            message: 'Could not clear authentication session');
      }
      return revision == _sessionRevision;
    });
  }
}
