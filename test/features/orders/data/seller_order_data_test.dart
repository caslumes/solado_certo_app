import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/data/repositories/api_order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

import 'order_data_test.dart' show MockClient, orderJson, pageJson;

Map<String, dynamic> sellerDetailJson() => {
  ...orderJson(),
  'status': 'shipped',
  'buyer': {'id': 'b1', 'name': 'Maria Souza'},
  'paid_at': '2026-10-14T13:30:00Z',
  'delivered_at': null,
  'history': [
    {
      'from': 'processing',
      'to': 'shipped',
      'reason': 'seller_shipped',
      'created_at': '2026-10-15T11:00:00Z',
    },
  ],
  'shipment': {
    'carrier': 'Correios',
    'tracking_code': 'AA123456789BR',
    'status': 'posted',
    'posted_at': '2026-10-15T11:00:00Z',
    'delivered_at': null,
  },
  'can_start_processing': false,
  'can_ship': false,
};

void main() {
  group('models', () {
    test("reads the seller's view with buyer, dates and shipment", () {
      final detail = orderDetailFromJson(sellerDetailJson());

      expect(detail.order.buyerName, 'Maria Souza');
      expect(detail.order.paidAt, DateTime.utc(2026, 10, 14, 13, 30));
      expect(detail.order.deliveredAt, isNull);
      final shipment = detail.shipment!;
      expect(shipment.carrier, 'Correios');
      expect(shipment.trackingCode, 'AA123456789BR');
      expect(shipment.isCorreios, isTrue);
      expect(shipment.postedAt, DateTime.utc(2026, 10, 15, 11));
      expect(detail.canStartProcessing, isFalse);
      expect(detail.canShip, isFalse);
    });

    test('reads the actions the backend allows', () {
      final detail = orderDetailFromJson({
        ...sellerDetailJson(),
        'status': 'processing',
        'shipment': null,
        'can_ship': true,
        'can_confirm_delivery': false,
      });

      expect(detail.shipment, isNull);
      expect(detail.canShip, isTrue);
    });

    test('a buyer order has no buyer name or shipment', () {
      final detail = orderDetailFromJson({...orderJson(), 'history': const []});

      expect(detail.order.buyerName, isNull);
      expect(detail.shipment, isNull);
      expect(detail.canConfirmDelivery, isFalse);
    });

    test('every status goes back to the API value it came from', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromApi(status.apiValue), status);
      }
    });

    test('words the reasons for the buyer or the seller', () {
      OrderStatusChangeEntity change(String reason) => OrderStatusChangeEntity(
        to: OrderStatus.cancelled,
        reason: reason,
        createdAt: DateTime(2026),
      );

      expect(change('buyer_cancelled').reasonLabel, 'Cancelado por você');
      expect(
        change('buyer_cancelled').reasonLabelFor(seller: true),
        'Cancelado pelo comprador',
      );
      for (final reason in [
        'seller_started_processing',
        'seller_shipped',
        'buyer_confirmed_delivery',
      ]) {
        expect(change(reason).reasonLabel, isNotNull);
        expect(change(reason).reasonLabelFor(seller: true), isNotNull);
        expect(
          change(reason).reasonLabel,
          isNot(change(reason).reasonLabelFor(seller: true)),
        );
      }
    });
  });

  group('ApiOrderRepository for sellers', () {
    late MockClient client;
    late ApiOrderRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiOrderRepository(client);
    });

    test('asks for a page of sales, with or without a status', () async {
      when(() => client.get(any())).thenAnswer((_) async => pageJson());

      await repository.getSellerOrders(1);
      await repository.getSellerOrders(
        2,
        filter: const OrderFilter(status: OrderStatus.paid),
      );

      verify(() => client.get('/seller/orders?page=1&limit=10')).called(1);
      verify(
        () => client.get('/seller/orders?page=2&limit=10&status=paid'),
      ).called(1);
    });

    test('gets one sale and starts preparing it', () async {
      when(() => client.get(any())).thenAnswer((_) async => sellerDetailJson());
      when(
        () => client.post(any()),
      ).thenAnswer((_) async => sellerDetailJson());

      await repository.getSellerOrder('o1');
      await repository.startProcessing('o1');

      verify(() => client.get('/seller/orders/o1')).called(1);
      verify(() => client.post('/seller/orders/o1/processing')).called(1);
    });

    test('ships with the carrier and the code', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => sellerDetailJson());

      final detail = await repository.shipOrder(
        'o1',
        carrier: 'Correios',
        trackingCode: 'AA123456789BR',
      );

      expect(detail.order.status, OrderStatus.shipped);
      verify(
        () => client.post(
          '/seller/orders/o1/shipment',
          data: {'carrier': 'Correios', 'tracking_code': 'AA123456789BR'},
        ),
      ).called(1);
    });
  });
}
