class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> body;
  final bool isRead;
  final String priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.body,
    required this.isRead,
    required this.priority,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: (json['type'] ?? '').toString(),
      body: json['body'] is Map
          ? Map<String, dynamic>.from(json['body'] as Map)
          : const {},
      isRead: json['is_read'] as bool? ?? false,
      priority: (json['priority'] ?? 'normal').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      body: body,
      isRead: isRead ?? this.isRead,
      priority: priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Результат постраничного запроса — не путать с виджетом-экраном
/// NotificationsPage (presentation/notifications_page.dart).
class PaginatedNotifications {
  final List<NotificationModel> items;
  final bool hasNext;
  final int totalCount;

  const PaginatedNotifications({
    required this.items,
    required this.hasNext,
    required this.totalCount,
  });
}
