import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/notifications/data/models/notification_model.dart';
import 'package:solado_certo_app/features/notifications/data/repositories/api_notification_repository.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> notificationJson({
  String type = 'order_shipped',
  Map<String, dynamic>? data = const {'order_id': 'o1'},
  bool read = false,
}) => {
  'id': 'n1',
  'type': type,
  'title': 'Pedido enviado',
  'body': 'O pedido SC-1 foi enviado por Correios.',
  'data': data,
  'read': read,
  'read_at': read ? '2026-10-20T13:00:00Z' : null,
  'created_at': '2026-10-20T12:00:00Z',
};

Map<String, dynamic> pageJson() => {
  'items': [notificationJson()],
  'current_page': 1,
  'total_pages': 2,
  'total_items': 21,
  'has_next': true,
  'has_previous': false,
  'unread_count': 7,
};

void main() {
  group('models', () {
    test('reads a notification', () {
      final notification = notificationFromJson(notificationJson());

      expect(notification.id, 'n1');
      expect(notification.type, NotificationType.orderShipped);
      expect(notification.title, 'Pedido enviado');
      expect(notification.orderId, 'o1');
      expect(notification.read, isFalse);
      expect(notification.createdAt, DateTime.utc(2026, 10, 20, 12));
    });

    test('reads one without data, of a type it does not know', () {
      final notification = notificationFromJson(
        notificationJson(type: 'support_reply', data: null, read: true),
      );

      expect(notification.type, NotificationType.other);
      expect(notification.orderId, isNull);
      expect(notification.read, isTrue);
    });

    test('reads a page with the unread count', () {
      final page = notificationsPageFromJson(pageJson());

      expect(page.items, hasLength(1));
      expect(page.hasNext, isTrue);
      expect(page.unreadCount, 7);
    });

    test('knows which types are about sales', () {
      const sales = {'order_paid', 'order_cancelled', 'order_delivered'};
      for (final type in [
        'order_paid',
        'order_cancelled',
        'order_delivered',
        'order_processing',
        'order_shipped',
        'order_refunded',
        'delivery_deadline',
      ]) {
        expect(
          NotificationType.fromApi(type).forSeller,
          sales.contains(type),
          reason: type,
        );
      }
    });
  });

  group('ApiNotificationRepository', () {
    late MockClient client;
    late ApiNotificationRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiNotificationRepository(client);
    });

    test('asks for a page of 20 notifications', () async {
      when(() => client.get(any())).thenAnswer((_) async => pageJson());

      final page = await repository.getNotifications(2);

      expect(page.unreadCount, 7);
      verify(() => client.get('/notifications?page=2&limit=20')).called(1);
    });

    test('marks one and all as read', () async {
      when(() => client.post(any())).thenAnswer((_) async => null);

      await repository.markRead('n1');
      await repository.markAllRead();

      verify(() => client.post('/notifications/n1/read')).called(1);
      verify(() => client.post('/notifications/read-all')).called(1);
    });
  });
}
