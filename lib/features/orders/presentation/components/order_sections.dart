import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';

/// One item of an order: photo, quantity, price and shipping option.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final option = item.shippingOption;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          SizedBox.square(
            dimension: 56,
            child: ProductImage(url: item.coverImageUrl),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: textTheme.bodyLarge),
                Text(
                  '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                  style: textTheme.bodySmall,
                ),
                Text(
                  '${shippingOptionName(option)} · '
                  '${deliveryTime(option.deliveryDays)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(formatCurrency(item.subtotal), style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// One status change in the order's timeline.
class OrderHistoryEntry extends StatelessWidget {
  const OrderHistoryEntry({
    super.key,
    required this.change,
    required this.isLatest,
    this.seller = false,
  });

  final OrderStatusChangeEntity change;
  final bool isLatest;

  /// Words the reasons for the seller.
  final bool seller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reason = change.reasonLabelFor(seller: seller);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Icon(
            isLatest ? Icons.radio_button_checked : Icons.circle_outlined,
            size: 18,
            color: isLatest ? AppColors.primaryColor : AppColors.tertiaryColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change.to.label, style: textTheme.bodyLarge),
                Text(
                  reason == null
                      ? formatDateTime(change.createdAt)
                      : '${formatDateTime(change.createdAt)} · $reason',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
