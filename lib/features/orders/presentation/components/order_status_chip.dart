import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OrderStatus.awaitingPayment => (
        AppColors.warningBackgroundColor,
        AppColors.warningColor,
      ),
      OrderStatus.cancelled || OrderStatus.returned => (
        AppColors.secondaryColor,
        AppColors.tertiaryColor,
      ),
      _ => (AppColors.primaryColor, Colors.white),
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          status.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
