import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepositoryInterface notificationRepository;

  GetNotificationsUseCase(this.notificationRepository);

  Future<NotificationsPageEntity> execute(int page) =>
      notificationRepository.getNotifications(page);
}

class MarkNotificationReadUseCase {
  final NotificationRepositoryInterface notificationRepository;

  MarkNotificationReadUseCase(this.notificationRepository);

  Future<void> execute(String id) => notificationRepository.markRead(id);
}

class MarkAllNotificationsReadUseCase {
  final NotificationRepositoryInterface notificationRepository;

  MarkAllNotificationsReadUseCase(this.notificationRepository);

  Future<void> execute() => notificationRepository.markAllRead();
}
