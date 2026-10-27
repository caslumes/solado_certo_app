import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';

List<String> describeCartChanges(CartEntity before, CartEntity after) => [
  for (final item in before.items)
    if (_change(item, after.item(item.advertisementId)) case final change?)
      '${item.title}: $change',
];

String? _change(CartItemEntity before, CartItemEntity? after) {
  if (after == null) return 'saiu do carrinho';
  if (after.problemDescription case final problem?) return problem;
  if (after.unitPrice != before.addedUnitPrice) {
    return 'de ${formatCurrency(before.addedUnitPrice)} '
        'por ${formatCurrency(after.unitPrice)}';
  }
  return null;
}
