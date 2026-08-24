import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import 'models/notification_model.dart';

class NotificationsRepository {
  final Dio _dio = DioClient.instance;

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

  Future<PaginatedNotifications> getNotifications({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/notifications/',
        queryParameters: {'page': page},
      );

      final dynamic responseData = response.data;
      final List<dynamic> results = responseData is List
          ? responseData
          : (responseData['results'] ?? []);

      final bool hasNext = responseData is Map &&
          responseData['next'] != null &&
          responseData['next'].toString().isNotEmpty;

      final int totalCount = responseData is Map
          ? (responseData['count'] as int? ?? results.length)
          : results.length;

      return PaginatedNotifications(
        items: results
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasNext: hasNext,
        totalCount: totalCount,
      );
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось загрузить уведомления'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count/');
      final data = response.data;
      if (data is Map) {
        return (data['unread_count'] ?? data['count'] ?? 0) as int;
      }
      return 0;
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось получить количество непрочитанных'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/mark-all-read/');
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось отметить все как прочитанные'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read/');
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось отметить как прочитанное'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id/');
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось удалить уведомление'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _unwrapNotification(dynamic data) {
    if (data is Map && data['result'] is Map) {
      return Map<String, dynamic>.from(data['result'] as Map);
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<NotificationModel> getNotificationDetail(String id) async {
    try {
      final response = await _dio.get('/notifications/$id/');
      return NotificationModel.fromJson(_unwrapNotification(response.data));
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось загрузить уведомление'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Поля подтверждены реальной Swagger-схемой (DeviceRegister):
  /// token*, device_id, platform (android|ios|web), language (en|ru|uz).
  Future<void> registerDevice({
    required String token,
    String? deviceId,
    required bool isAndroid,
    required String language,
  }) async {
    try {
      await _dio.post(
        '/notifications/devices/register/',
        data: {
          'token': token,
          if (deviceId != null) 'device_id': deviceId,
          'platform': isAndroid ? 'android' : 'ios',
          'language': language,
        },
        options: Options(extra: {'silentAuth': true}),
      );
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось зарегистрировать устройство для push'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Подтверждено Swagger-схемой (DeviceDelete): тело содержит только token.
  Future<void> unregisterDevice({required String token}) async {
    try {
      await _dio.post(
        '/notifications/devices/unregister/',
        data: {'token': token},
        options: Options(extra: {'silentAuth': true}),
      );
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data) == 'Unknown error'
            ? 'Не удалось отписать устройство от push'
            : _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
