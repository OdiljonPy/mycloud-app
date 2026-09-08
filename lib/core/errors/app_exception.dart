class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? messageKey;
  final Map<String, dynamic>? errors;

  const AppException({
    required this.message,
    this.statusCode,
    this.messageKey,
    this.errors,
  });

  @override
  String toString() => 'AppException($statusCode): $message';
}