import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepositoryInterface {
  Future<NotificationsPageEntity> getNotifications(int page);
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
