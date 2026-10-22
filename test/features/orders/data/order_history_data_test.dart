import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/data/repositories/api_order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

import 'order_data_test.dart' show MockClient, orderJson, pageJson;

void main() {
  group('OrderFilter', () {
    final today = DateTime(2026, 10, 21, 15, 30);

    test('sends nothing when empty', () {
      expect(const OrderFilter().isEmpty, isTrue);
      expect(const OrderFilter().query(today), '');
    });

    test('sends the status and the first day of the period', () {
      expect(
        const OrderFilter(
          status: OrderStatus.delivered,
          period: OrderPeriod.last30Days,
        ).query(today),
        '&status=delivered&from=2026-09-22',
      );
      expect(
        const OrderFilter(period: OrderPeriod.last12Months).query(today),
        '&from=2025-10-22',
      );
    });

    test('a tab replaces the status and keeps the period', () {
      const filter = OrderFilter(
        status: OrderStatus.paid,
        period: OrderPeriod.last3Months,
      );

      expect(
        filter.withStatus(OrderStatus.shipped),
        const OrderFilter(
          status: OrderStatus.shipped,
          period: OrderPeriod.last3Months,
        ),
      );
    });
  });

  group('models', () {
    test("reads an item's id and its review", () {
      final order = orderFromJson({
        ...orderJson(),
        'items': [
          {
            ...(orderJson()['items'] as List).single as Map<String, dynamic>,
            'id': 'i1',
            'review': {
              'product_rating': 5,
              'seller_rating': 4,
              'comfort_rating': null,
              'comment': 'Boa',
              'adaptation_feedback': null,
              'created_at': '2026-10-21T13:00:00Z',
            },
          },
        ],
      });

      final item = order.items.single;
      expect(item.id, 'i1');
      expect(item.review!.productRating, 5);
      expect(item.review!.sellerRating, 4);
      expect(item.review!.comfortRating, isNull);
      expect(item.review!.comment, 'Boa');
    });

    test('an item not reviewed yet has no review', () {
      expect(orderFromJson(orderJson()).items.single.review, isNull);
    });
  });

  group('ShipmentEntity', () {
    ShipmentEntity shipment(String carrier) => ShipmentEntity(
      carrier: carrier,
      trackingCode: 'AA123456789BR',
      status: 'posted',
    );

    test('links the Correios tracking page', () {
      expect(
        shipment('Correios (PAC)').trackingUrl.toString(),
        'https://rastreamento.correios.com.br/app/index.php?objetos=AA123456789BR',
      );
    });

    test('has no link for other carriers', () {
      expect(shipment('Jadlog').trackingUrl, isNull);
    });
  });

  group('ApiOrderRepository', () {
    late MockClient client;
    late ApiOrderRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiOrderRepository(
        client,
        now: () => DateTime(2026, 10, 21, 9),
      );
    });

    test('filters the purchases and the sales', () async {
      when(() => client.get(any())).thenAnswer((_) async => pageJson());

      await repository.getOrders(
        1,
        filter: const OrderFilter(
          status: OrderStatus.cancelled,
          period: OrderPeriod.last30Days,
        ),
      );
      await repository.getSellerOrders(
        1,
        filter: const OrderFilter(
          status: OrderStatus.paid,
          period: OrderPeriod.last3Months,
        ),
      );

      verify(
        () => client.get(
          '/orders?page=1&limit=10&status=cancelled&from=2026-09-22',
        ),
      ).called(1);
      verify(
        () => client.get(
          '/seller/orders?page=1&limit=10&status=paid&from=2026-07-24',
        ),
      ).called(1);
    });

    test('confirms the delivery', () async {
      when(() => client.post(any())).thenAnswer(
        (_) async => {...orderJson(), 'status': 'delivered', 'history': []},
      );

      final detail = await repository.confirmDelivery('o1');

      expect(detail.order.status, OrderStatus.delivered);
      verify(() => client.post('/orders/o1/delivered')).called(1);
    });
  });
}
