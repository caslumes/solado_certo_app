import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';

NotificationEntity notificationFromJson(Map<String, dynamic> json) {
  final data = json['data'] as Map<String, dynamic>?;
  return NotificationEntity(
    id: json['id'] as String,
    type: NotificationType.fromApi(json['type'] as String),
    title: json['title'] as String,
    body: json['body'] as String,
    orderId: data?['order_id'] as String?,
    customOrderId: data?['custom_order_id'] as String?,
    sentToSeller: data?['recipient'] == 'seller',
    read: json['read'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

NotificationsPageEntity notificationsPageFromJson(Map<String, dynamic> json) =>
    NotificationsPageEntity(
      items: [
        for (final notification in json['items'] as List? ?? const [])
          notificationFromJson(notification),
      ],
      currentPage: json['current_page'] as int,
      hasNext: json['has_next'] as bool,
      unreadCount: json['unread_count'] as int,
    );
