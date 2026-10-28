import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  final String? orderId;
  final String? customOrderId;
  final bool sentToSeller;
  final bool read;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.customOrderId,
    this.sentToSeller = false,
    required this.read,
    required this.createdAt,
  });

  bool get forSeller => type.forSeller || sentToSeller;

  NotificationEntity copyWith({bool? read}) => NotificationEntity(
    id: id,
    type: type,
    title: title,
    body: body,
    orderId: orderId,
    customOrderId: customOrderId,
    sentToSeller: sentToSeller,
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
