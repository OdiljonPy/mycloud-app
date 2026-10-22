import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

enum AppExceptionType { network, timeout, cancelled }

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? messageKey;
  final Map<String, dynamic>? errors;
  final AppExceptionType? type;
  final String? requestPath;

  const AppException({
    required this.message,
    this.statusCode,
    this.messageKey,
    this.errors,
    this.type,
    this.requestPath,
  });

  /// Keeps transport and validation information when a repository wraps Dio.
  /// The original response is diagnostic data, never a ready-made UI string.
  factory AppException.fromDio(
    DioException error, {
    required String fallbackMessage,
  }) {
    final data = error.response?.data;
    final body = data is Map ? data : const {};
    final rawMessage = body['detail'] ?? body['message'];
    final rawKey = body['message_key'] ?? body['code'];
    final validation = body['errors'];
    final fields =
        Map<Object?, dynamic>.from(validation is Map ? validation : body);
    if (validation is! Map) {
      fields.removeWhere((key, _) => const {
            'detail',
            'message',
            'message_key',
            'code',
            'status',
            'status_code',
            'result',
          }.contains(key));
    }
    AppExceptionType? type;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        type = AppExceptionType.timeout;
      case DioExceptionType.connectionError:
        type = AppExceptionType.network;
      case DioExceptionType.cancel:
        type = AppExceptionType.cancelled;
      default:
        if (error.error is SocketException) type = AppExceptionType.network;
        if (error.error is TimeoutException) type = AppExceptionType.timeout;
    }
    return AppException(
      message: rawMessage is String && rawMessage.trim().isNotEmpty
          ? rawMessage
          : fallbackMessage,
      statusCode: error.response?.statusCode,
      messageKey: rawKey is String ? rawKey : null,
      errors: fields.isEmpty
          ? null
          : {
              for (final entry in fields.entries)
                if (entry.key is String) entry.key as String: entry.value,
            },
      type: type,
      requestPath: error.requestOptions.uri.path,
    );
  }

  @override
  String toString() => 'AppException($statusCode): $message';
}
