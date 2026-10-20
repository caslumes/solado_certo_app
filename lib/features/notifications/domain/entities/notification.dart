import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';

/// An in-app notification (RF-020); there are no push notifications.
class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  final String? orderId;
  final bool read;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    required this.read,
    required this.createdAt,
  });

  NotificationEntity copyWith({bool? read}) => NotificationEntity(
    id: id,
    type: type,
    title: title,
    body: body,
    orderId: orderId,
    read: read ?? this.read,
    createdAt: createdAt,
  );
}

class NotificationsPageEntity {
  final List<NotificationEntity> items;
  final int currentPage;
  final bool hasNext;

  final int unreadCount;

  const NotificationsPageEntity({
    required this.items,
    required this.currentPage,
    required this.hasNext,
    required this.unreadCount,
  });
}
