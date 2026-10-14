import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/checkout/data/models/checkout_model.dart';
import 'package:solado_certo_app/features/checkout/data/repositories/api_checkout_repository.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

import '../../../support/builders.dart';
import '../../cart/data/cart_data_test.dart' show cartJson;

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> addressJson() => {
  'label': 'Casa',
  'receiver': 'Maria Souza',
  'zip_code': '13010111',
  'street': 'Rua das Flores',
  'number': '10',
  'complement': null,
  'district': 'Centro',
  'city': 'Campinas',
  'state': 'SP',
  'country': 'BR',
};

Map<String, dynamic> itemJson() => {
  'advertisement_id': '601',
  'title': 'Palmilha',
  'cover_image_url': null,
  'quantity': 2,
  'unit_price': '89.90',
  'subtotal': '179.80',
  'shipping_option': {
    'id': 'sedex',
    'name': 'SEDEX',
    'carrier': 'Correios',
    'price': '29.90',
    'delivery_days': 3,
  },
};

Map<String, dynamic> previewJson() => {
  'address': addressJson(),
  'orders': [
    {
      'seller': {'id': 's1', 'name': 'João Pereira'},
      'items': [itemJson()],
      'subtotal': '179.80',
      'shipping_total': '29.90',
      'discount_total': '0.00',
      'total': '209.70',
    },
  ],
  'subtotal': '179.80',
  'shipping_total': '29.90',
  'discount_total': '0.00',
  'total': '209.70',
};

Map<String, dynamic> checkoutJson() => {
  'id': 'checkout-1',
  'orders': [
    {
      'id': 'o1',
      'number': 'SC-20261014-564NZP',
      'status': 'awaiting_payment',
      'seller': {'id': 's1', 'name': 'João Pereira'},
      'address': addressJson(),
      'items': [itemJson()],
      'subtotal': '179.80',
      'shipping_total': '29.90',
      'discount_total': '0.00',
      'total': '209.70',
      'created_at': '2026-10-14T12:00:00Z',
      'updated_at': '2026-10-14T12:00:00Z',
    },
  ],
  'total': '209.70',
};

void main() {
  const selection = CheckoutSelection(
    addressId: 'a1',
    shipping: {'601': 'sedex', '602': 'pac'},
  );

  group('models', () {
    test('writes the selection as the checkout body', () {
      expect(checkoutSelectionToJson(selection), {
        'address_id': 'a1',
        'shipping': [
          {'advertisement_id': '601', 'shipping_option_id': 'sedex'},
          {'advertisement_id': '602', 'shipping_option_id': 'pac'},
        ],
      });
    });

    test('reads the preview with its orders and totals', () {
      final plan = checkoutPlanFromJson(previewJson());

      expect(plan.address.receiver, 'Maria Souza');
      expect(plan.address.complement, isNull);
      expect(plan.total, 209.7);
      expect(plan.shippingTotal, 29.9);
      final order = plan.orders.single;
      expect(order.sellerName, 'João Pereira');
      expect(order.discountTotal, 0);
      final item = order.items.single;
      expect(item.quantity, 2);
      expect(item.subtotal, 179.8);
      expect(item.shippingOption.name, 'SEDEX');
      expect(item.shippingOption.price, 29.9);
      expect(item.shippingOption.deliveryDays, 3);
    });

    test('reads the created orders', () {
      final result = checkoutResultFromJson(checkoutJson());

      expect(result.id, 'checkout-1');
      expect(result.total, 209.7);
      final order = result.orders.single;
      expect(order.number, 'SC-20261014-564NZP');
      expect(order.status, OrderStatus.awaitingPayment);
      expect(order.sellerId, 's1');
      expect(order.createdAt, DateTime.utc(2026, 10, 14, 12));
    });
  });

  group('ApiCheckoutRepository', () {
    late MockClient client;
    late ApiCheckoutRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiCheckoutRepository(client);
    });

    test('previews without an idempotency key', () async {
      when(
        () => client.post('/checkout/preview', data: any(named: 'data')),
      ).thenAnswer((_) async => previewJson());

      final plan = await repository.preview(selection);

      expect(plan.total, 209.7);
      verify(
        () => client.post(
          '/checkout/preview',
          data: checkoutSelectionToJson(selection),
        ),
      ).called(1);
    });

    test('checks out with the Idempotency-Key header', () async {
      when(
        () => client.post(
          '/checkout',
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => checkoutJson());

      final result = await repository.checkout(selection, 'key-1');

      expect(result.orders.single.number, 'SC-20261014-564NZP');
      verify(
        () => client.post(
          '/checkout',
          data: checkoutSelectionToJson(selection),
          headers: {'Idempotency-Key': 'key-1'},
        ),
      ).called(1);
    });

    test('a 409 with the cart becomes a CheckoutConflict', () async {
      when(
        () => client.post(
          '/checkout',
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(
        buildDioException(
          statusCode: 409,
          data: {
            'error': 'out of stock',
            'items': [
              {'advertisement_id': '603', 'requested': 3, 'available': 1},
            ],
            'cart': cartJson(),
          },
        ),
      );

      await expectLater(
        repository.checkout(selection, 'key-1'),
        throwsA(
          isA<CheckoutConflict>()
              .having((c) => c.failure, 'failure', isA<OutOfStockFailure>())
              .having((c) => c.cart.id, 'cart', 'cart-1'),
        ),
      );
    });

    test('reads the prices changed conflict', () async {
      when(
        () => client.post('/checkout/preview', data: any(named: 'data')),
      ).thenThrow(
        buildDioException(
          statusCode: 409,
          data: {'error': 'prices changed', 'cart': cartJson()},
        ),
      );

      await expectLater(
        repository.preview(selection),
        throwsA(
          isA<CheckoutConflict>().having(
            (c) => c.failure,
            'failure',
            isA<PricesChangedFailure>(),
          ),
        ),
      );
    });

    test('other errors pass through', () async {
      when(
        () => client.post('/checkout/preview', data: any(named: 'data')),
      ).thenThrow(
        buildDioException(
          statusCode: 404,
          data: {'error': 'address not found'},
        ),
      );

      await expectLater(
        repository.preview(selection),
        throwsA(isA<DioException>()),
      );
    });
  });
}
