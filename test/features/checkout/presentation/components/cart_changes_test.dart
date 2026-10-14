import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';
import 'package:solado_certo_app/features/checkout/presentation/components/cart_changes.dart';

import '../../../../support/builders.dart';

void main() {
  setUpAll(initializeFormatting);

  test('lists stock problems, price changes and items that left', () {
    final before = buildCart({
      's1': [
        buildCartItem(id: '601', quantity: 3),
        buildCartItem(id: '602', price: 10),
        buildCartItem(id: '603'),
        buildCartItem(id: '604'),
      ],
    });
    final after = buildCart({
      's1': [
        buildCartItem(
          id: '601',
          quantity: 3,
          stock: 1,
          problem: CartItemProblem.insufficientStock,
        ),
        buildCartItem(id: '602', price: 12.5),
        buildCartItem(id: '603'),
      ],
    });

    expect(describeCartChanges(before, after), [
      'Palmilha 601: Só há 1 unidade disponível',
      'Palmilha 602: de ${formatCurrency(10)} por ${formatCurrency(12.5)}',
      'Palmilha 604: saiu do carrinho',
    ]);
  });

  test(
    'a price already changed in the cart is compared with the added one',
    () {
      final before = buildCart({
        's1': [buildCartItem(price: 89.9, addedPrice: 79.9)],
      });
      final after = buildCart({
        's1': [buildCartItem(price: 89.9)],
      });

      expect(describeCartChanges(before, after), [
        'Palmilha 601: de ${formatCurrency(79.9)} por ${formatCurrency(89.9)}',
      ]);
    },
  );

  test('nothing changed', () {
    final cart = buildCart({
      's1': [buildCartItem()],
    });

    expect(describeCartChanges(cart, cart), isEmpty);
  });
}
