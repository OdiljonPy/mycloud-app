import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/secure_storage.dart';

class ProfileRepository {
  final Dio _dio = DioClient.instance;

  String _extractError(dynamic data) {
    if (data == null) return 'Неизвестная ошибка';
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

  Future<Map<String, dynamic>> getMe() async {
    try {
      final r = await _dio.get('/authentication/users/me/');
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    try {
      final userId = await SecureStorage.getUserId();
      if (userId == null) throw const AppException(message: 'User ID not found');
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone_number'] = phone;
      await _dio.patch('/authentication/users/$userId/', data: data);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> changePassword({
    required String current,
    required String newPass,
  }) async {
    try {
      final userId = await SecureStorage.getUserId();
      if (userId == null) throw const AppException(message: 'User ID not found');
      await _dio.patch('/authentication/users/$userId/', data: {
        'old_password': current,
        'new_password': newPass,
        'confirm_password': newPass,
      });
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getStorageUsed() async {
    try {
      final r = await _dio.get('/storage/used/');
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final r = await _dio.get('/storage/usage/');
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getContentStatistics() async {
    try {
      final r = await _dio.get('/content/statistics/');
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getContentInfo({
    required String id,
    required String type,
  }) async {
    try {
      final r = await _dio.post('/content/info/', data: {'id': id, 'type': type});
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> disableAccount() async {
    try {
      await _dio.patch('/authentication/users/disable/', data: {'verified': true});
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> sendContact({
    required String email,
    required String theme,
    required String message,
  }) async {
    try {
      final r = await _dio.post('/base/contact/', data: {
        'email': email,
        'theme': theme,
        'message': message,
      });
      return r.data is Map<String, dynamic> ? r.data : {};
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    try {
      final me = await getMe();
      final userId = me['id']?.toString();
      if (userId == null) {
        throw const AppException(message: 'Не удалось получить ID пользователя');
      }
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      await _dio.patch('/authentication/users/$userId/', data: formData);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }
}