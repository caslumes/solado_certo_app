import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_quantity_stepper.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';

const maxCartItemQuantity = 99;

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.busy,
    required this.enabled,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onOpen,
  });

  final CartItemEntity item;

  final bool busy;

  final bool enabled;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final problem = item.problem;
    final canChange = enabled && !busy;
    final max = item.isAvailable
        ? item.stock.clamp(1, maxCartItemQuantity)
        : item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Opacity(
              opacity: item.isAvailable ? 1 : 0.5,
              child: SizedBox.square(
                dimension: 72,
                child: ProductImage(
                  url: item.coverImageUrl,
                  semanticLabel: item.title,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                GestureDetector(
                  onTap: onOpen,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                ),
                Wrap(
                  spacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatCurrency(item.unitPrice),
                      style: textTheme.bodyMedium,
                    ),
                    if (item.priceChanged)
                      Text(
                        formatCurrency(item.addedUnitPrice),
                        style: textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                if (item.priceChanged)
                  Text(
                    'O preço mudou desde que você adicionou.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.warningColor,
                    ),
                  ),
                if (problem != null) _ProblemChip(item: item),
                Row(
                  children: [
                    if (busy)
                      const SizedBox(
                        height: 40,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      ShoeQuantityStepper(
                        value: item.quantity,
                        max: max,
                        onChanged: canChange ? onQuantityChanged : null,
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remover do carrinho',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: canChange ? onRemove : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemChip extends StatelessWidget {
  const _ProblemChip({required this.item});

  final CartItemEntity item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.warningBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          item.problemDescription!,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.warningColor),
        ),
      ),
    );
  }
}
