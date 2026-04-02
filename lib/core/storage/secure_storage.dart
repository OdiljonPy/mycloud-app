import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFullName(String name) async {
    try {
      await _storage.write(key: _fullNameKey, value: name);
    } catch (_) {}
  }

  static Future<String?> getFullName() async {
    return _safeRead(_fullNameKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {}
  }

  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (_) {}
  }

  static Future<String?> getUserId() async {
    return _safeRead(_userIdKey);
  }

  static Future<String?> getAccessToken() async {
    return _safeRead(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _safeRead(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
