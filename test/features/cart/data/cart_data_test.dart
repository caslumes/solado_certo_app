import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/cart/data/models/cart_model.dart';
import 'package:solado_certo_app/features/cart/data/repositories/api_cart_repository.dart';
import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> cartJson() => {
  'id': 'cart-1',
  'groups': [
    {
      'seller': {'id': 's1', 'name': 'João Pereira'},
      'subtotal': '179.80',
      'items': [
        {
          'advertisement_id': '601',
          'title': 'Palmilha',
          'cover_image_url': '/files/public/ads/a.png',
          'quantity': 2,
          'unit_price': '89.90',
          'added_unit_price': '79.90',
          'price_changed': true,
          'stock': 25,
          'available': true,
          'problem': null,
          'subtotal': '179.80',
          'shipping_options': [
            {
              'id': 'pac',
              'name': 'PAC',
              'carrier': 'Correios',
              'price': '19.90',
              'delivery_days': 7,
            },
          ],
        },
        {
          'advertisement_id': '603',
          'title': 'Meia',
          'cover_image_url': null,
          'quantity': 3,
          'unit_price': '10.00',
          'added_unit_price': '10.00',
          'price_changed': false,
          'stock': 1,
          'available': false,
          'problem': 'insufficient_stock',
          'subtotal': '30.00',
          'shipping_options': <Map<String, dynamic>>[],
        },
      ],
    },
  ],
  'item_count': 2,
  'subtotal': '179.80',
  'has_problems': true,
  'has_price_changes': true,
};

Map<String, dynamic> emptyCartJson() => {
  'id': null,
  'groups': <Map<String, dynamic>>[],
  'item_count': 0,
  'subtotal': '0.00',
  'has_problems': false,
  'has_price_changes': false,
};

void main() {
  group('cartFromJson', () {
    test('reads groups, items, prices and problems', () {
      final cart = cartFromJson(cartJson());

      expect(cart.id, 'cart-1');
      expect(cart.subtotal, 179.8);
      expect(cart.itemCount, 2);
      expect(cart.hasProblems, isTrue);
      expect(cart.hasPriceChanges, isTrue);
      expect(cart.unitCount, 5);

      final group = cart.groups.single;
      expect(group.sellerName, 'João Pereira');
      expect(group.subtotal, 179.8);

      final insoles = cart.item('601')!;
      expect(insoles.quantity, 2);
      expect(insoles.unitPrice, 89.9);
      expect(insoles.addedUnitPrice, 79.9);
      expect(insoles.priceChanged, isTrue);
      expect(insoles.isAvailable, isTrue);
      expect(insoles.coverImageUrl, '/files/public/ads/a.png');
      expect(insoles.shippingOptions.single.price, 19.9);

      final socks = cart.item('603')!;
      expect(socks.problem, CartItemProblem.insufficientStock);
      expect(socks.isAvailable, isFalse);
      expect(cart.item('999'), isNull);
    });

    test('reads an empty cart', () {
      final cart = cartFromJson(emptyCartJson());

      expect(cart.id, isNull);
      expect(cart.isEmpty, isTrue);
      expect(cart.unitCount, 0);
    });

    test('maps every problem code', () {
      expect(
        CartItemProblem.fromApi('unavailable'),
        CartItemProblem.unavailable,
      );
      expect(
        CartItemProblem.fromApi('out_of_stock'),
        CartItemProblem.outOfStock,
      );
      expect(CartItemProblem.fromApi(null), isNull);
      expect(CartItemProblem.fromApi('other'), isNull);
    });
  });

  group('ApiCartRepository', () {
    late MockClient client;
    late ApiCartRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiCartRepository(client);
    });

    test('getCart', () async {
      when(() => client.get('/cart')).thenAnswer((_) async => cartJson());

      expect((await repository.getCart()).id, 'cart-1');
    });

    test('addItem sends the ad and the quantity', () async {
      when(
        () => client.post('/cart/items', data: any(named: 'data')),
      ).thenAnswer((_) async => cartJson());

      await repository.addItem('601', 2);

      verify(
        () => client.post(
          '/cart/items',
          data: {'advertisement_id': '601', 'quantity': 2},
        ),
      ).called(1);
    });

    test('changeQuantity sends the new quantity', () async {
      when(
        () => client.patch('/cart/items/601', data: any(named: 'data')),
      ).thenAnswer((_) async => cartJson());

      await repository.changeQuantity('601', 4);

      verify(
        () => client.patch('/cart/items/601', data: {'quantity': 4}),
      ).called(1);
    });

    test('removeItem returns the cart', () async {
      when(
        () => client.delete('/cart/items/601'),
      ).thenAnswer((_) async => emptyCartJson());

      expect((await repository.removeItem('601')).isEmpty, isTrue);
    });
  });
}
