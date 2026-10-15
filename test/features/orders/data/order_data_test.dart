import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/data/repositories/api_order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

import '../../checkout/data/checkout_data_test.dart' show checkoutJson;

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> orderJson() =>
    (checkoutJson()['orders'] as List).single as Map<String, dynamic>;

Map<String, dynamic> pageJson() => {
  'items': [orderJson()],
  'current_page': 2,
  'total_pages': 3,
  'total_items': 21,
  'has_next': true,
  'has_previous': true,
};

Map<String, dynamic> detailJson() => {
  ...orderJson(),
  'status': 'cancelled',
  'history': [
    {
      'from': null,
      'to': 'awaiting_payment',
      'reason': 'checkout',
      'created_at': '2026-10-14T12:00:00Z',
    },
    {
      'from': 'awaiting_payment',
      'to': 'cancelled',
      'reason': 'buyer_cancelled',
      'created_at': '2026-10-14T13:30:00Z',
    },
  ],
  'can_cancel': false,
};

void main() {
  group('models', () {
    test('reads a page of orders', () {
      final page = ordersPageFromJson(pageJson());

      expect(page.currentPage, 2);
      expect(page.hasNext, isTrue);
      expect(page.items.single.number, 'SC-20261014-564NZP');
    });

    test('reads an empty page', () {
      final page = ordersPageFromJson({
        'items': <Map<String, dynamic>>[],
        'current_page': 1,
        'has_next': false,
      });

      expect(page.items, isEmpty);
    });

    test('reads the detail with its history', () {
      final detail = orderDetailFromJson(detailJson());

      expect(detail.order.status, OrderStatus.cancelled);
      expect(detail.canCancel, isFalse);
      final [created, cancelled] = detail.history;
      expect(created.from, isNull);
      expect(created.to, OrderStatus.awaitingPayment);
      expect(created.reasonLabel, 'Pedido criado');
      expect(created.createdAt, DateTime.utc(2026, 10, 14, 12));
      expect(cancelled.from, OrderStatus.awaitingPayment);
      expect(cancelled.to, OrderStatus.cancelled);
      expect(cancelled.reasonLabel, 'Cancelado por você');
    });

    test('every backend status has a label', () {
      for (final status in [
        'awaiting_payment',
        'paid',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        'returned',
      ]) {
        expect(OrderStatus.fromApi(status).label, isNotEmpty);
      }
    });
  });

  group('ApiOrderRepository', () {
    late MockClient client;
    late ApiOrderRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiOrderRepository(client);
    });

    test('asks for a page of 10 orders', () async {
      when(() => client.get(any())).thenAnswer((_) async => pageJson());

      final page = await repository.getOrders(2);

      expect(page.items, hasLength(1));
      verify(() => client.get('/orders?page=2&limit=10')).called(1);
    });

    test('gets one order', () async {
      when(() => client.get(any())).thenAnswer((_) async => detailJson());

      final detail = await repository.getOrder('o1');

      expect(detail.history, hasLength(2));
      verify(() => client.get('/orders/o1')).called(1);
    });

    test('cancels an order', () async {
      when(() => client.post(any())).thenAnswer((_) async => detailJson());

      final detail = await repository.cancelOrder('o1');

      expect(detail.order.status, OrderStatus.cancelled);
      verify(() => client.post('/orders/o1/cancel')).called(1);
    });
  });
}
