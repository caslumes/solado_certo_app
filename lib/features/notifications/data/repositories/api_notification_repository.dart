import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/notifications/data/models/notification_model.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/repositories/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepositoryInterface {
  static const pageSize = 20;

  final ClientInterface client;

  ApiNotificationRepository(this.client);

  @override
  Future<NotificationsPageEntity> getNotifications(int page) async {
    final response = await client.get(
      '/notifications?page=$page&limit=$pageSize',
    );
    return notificationsPageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> markRead(String id) => client.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() => client.post('/notifications/read-all');
}
