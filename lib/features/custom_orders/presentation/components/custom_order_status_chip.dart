import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';

class CustomOrderStatusChip extends StatelessWidget {
  const CustomOrderStatusChip({super.key, required this.status});

  final CustomOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      CustomOrderStatus.needsInfo || CustomOrderStatus.approved => (
        AppColors.warningBackgroundColor,
        AppColors.warningColor,
      ),
      CustomOrderStatus.rejected || CustomOrderStatus.cancelled => (
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
