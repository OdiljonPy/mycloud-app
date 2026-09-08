import 'package:flutter/foundation.dart';
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

  // Кэш токенов в памяти процесса. Без него каждый onRequest/refresh дёргает
  // платформенное secure storage заново; при таймауте/гонке параллельных
  // чтений (несколько запросов при старте home-страницы) это давало false
  // "токена нет" → ложный 401 → ложный auto-logout с рабочими токенами.
  // Кэшируем только успешные непустые чтения — null (таймаут/ошибка) не
  // кэшируется, чтобы не закрепить случайный сбой на весь сеанс.
  static String? _accessTokenCache;
  static String? _refreshTokenCache;
  static bool get hasCachedAccessToken => _accessTokenCache != null;

  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] read($key) failed: $e');
      return null;
    }
  }

  static Future<void> saveFullName(String name) async {
    try {
      await _storage.write(key: _fullNameKey, value: name);
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] saveFullName failed: $e');
    }
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
      _accessTokenCache = accessToken;
      _refreshTokenCache = refreshToken;
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
    if (_accessTokenCache != null) return _accessTokenCache;
    final token = await _safeRead(_accessTokenKey);
    if (token != null) _accessTokenCache = token;
    return token;
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshTokenCache != null) return _refreshTokenCache;
    final token = await _safeRead(_refreshTokenKey);
    if (token != null) _refreshTokenCache = token;
    return token;
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    _accessTokenCache = null;
    _refreshTokenCache = null;
  }
}
