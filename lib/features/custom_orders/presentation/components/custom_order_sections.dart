import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/measurements_fields.dart';

class MeasurementsSummary extends StatelessWidget {
  const MeasurementsSummary({super.key, required this.measurements});

  final Measurements measurements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String foot(FootMeasurement foot) =>
        '${formatCentimeters(foot.lengthCm)} × ${formatCentimeters(foot.widthCm)}';
    final rows = [
      ('Pé esquerdo', foot(measurements.left)),
      ('Pé direito', foot(measurements.right)),
      ('Numeração', '${measurements.shoeSize}'),
      ('Arco', measurements.archType.label),
    ];

    return Column(
      spacing: 4.0,
      children: [
        for (final (label, value) in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ),
              Expanded(child: Text(value, style: textTheme.bodyLarge)),
            ],
          ),
      ],
    );
  }
}

class CustomOrderHistoryEntry extends StatelessWidget {
  const CustomOrderHistoryEntry({
    super.key,
    required this.change,
    required this.isLatest,
    this.seller = false,
  });

  final CustomOrderChangeEntity change;
  final bool isLatest;

  final bool seller;

  String? get _actor => switch (change.changedBy) {
    CustomOrderActor.system => null,
    CustomOrderActor.buyer => seller ? 'Comprador' : 'Você',
    CustomOrderActor.seller => seller ? 'Você' : 'Vendedor',
  };

  String? get _reason {
    final reason = change.reason;
    if (reason == null) return null;
    return switch (change.to) {
      CustomOrderStatus.needsInfo => 'Pergunta: $reason',
      CustomOrderStatus.underReview
          when change.from == CustomOrderStatus.needsInfo =>
        'Resposta: $reason',
      CustomOrderStatus.rejected ||
      CustomOrderStatus.cancelled => 'Motivo: $reason',
      _ => reason,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actor = _actor;
    final reason = _reason;

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
                  actor == null
                      ? formatDateTime(change.createdAt)
                      : '${formatDateTime(change.createdAt)} · $actor',
                  style: textTheme.bodySmall,
                ),
                if (reason != null) Text(reason, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
