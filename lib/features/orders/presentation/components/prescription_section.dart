import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';

class PrescriptionSection extends StatelessWidget {
  const PrescriptionSection({
    super.key,
    required this.item,
    this.onView,
    this.actions = const [],
  });

  final OrderItemEntity item;
  final VoidCallback? onView;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final prescription = item.prescription;
    final status = prescription?.status;
    final color = status == DocumentStatus.approved
        ? AppColors.primaryColor
        : AppColors.warningColor;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2.0,
        children: [
          Row(
            spacing: 6.0,
            children: [
              Icon(Icons.medical_information_outlined, size: 18, color: color),
              Expanded(
                child: Text(switch (status) {
                  null => 'Receita pendente',
                  final status => 'Receita ${status.label.toLowerCase()}',
                }, style: textTheme.bodySmall?.copyWith(color: color)),
              ),
            ],
          ),
          if (prescription?.rejectionReason case final reason?
              when status == DocumentStatus.rejected)
            Text('Motivo: $reason', style: textTheme.bodySmall),
          if (prescription != null)
            Text(
              'Enviada em ${formatDateTime(prescription.createdAt)}',
              style: textTheme.bodySmall,
            ),
          if ((onView != null && prescription != null) || actions.isNotEmpty)
            Wrap(
              spacing: 16.0,
              children: [
                if (onView != null && prescription != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: onView,
                    child: const Text('Ver receita'),
                  ),
                ...actions,
              ],
            ),
        ],
      ),
    );
  }
}
