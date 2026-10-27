import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

Future<OrderFilter?> showOrderFilterSheet(
  BuildContext context, {
  required OrderFilter current,
  bool withStatus = true,
}) => showModalBottomSheet<OrderFilter>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _OrderFilterSheet(current: current, withStatus: withStatus),
);

class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({required this.current, required this.withStatus});

  final OrderFilter current;
  final bool withStatus;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late OrderStatus? _status = widget.current.status;
  late OrderPeriod _period = widget.current.period;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0,
          children: [
            Text('Filtrar'.toUpperCase(), style: textTheme.bodyMedium),
            if (widget.withStatus) ...[
              const SizedBox(height: 8),
              Text('Situação', style: textTheme.bodyMedium),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final status in [null, ...OrderStatus.values])
                    ChoiceChip(
                      label: Text(status?.label ?? 'Todas'),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text('Período', style: textTheme.bodyMedium),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final period in OrderPeriod.values)
                  ChoiceChip(
                    label: Text(period.label),
                    selected: _period == period,
                    onSelected: (_) => setState(() => _period = period),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ShoeTextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(OrderFilter(status: _status, period: _period)),
              text: 'Aplicar',
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(const OrderFilter()),
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    super.key,
    required this.filter,
    required this.onClear,
  });

  final OrderFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (filter.status case final status?) status.label,
      if (filter.period != OrderPeriod.any) filter.period.label,
    ];

    return Container(
      color: AppColors.secondaryColor,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Limpar')),
        ],
      ),
    );
  }
}

class OrderFilterButton extends StatelessWidget {
  const OrderFilterButton({
    super.key,
    required this.filter,
    required this.onChanged,
    this.withStatus = true,
  });

  final OrderFilter filter;
  final ValueChanged<OrderFilter> onChanged;
  final bool withStatus;

  Future<void> _open(BuildContext context) async {
    final chosen = await showOrderFilterSheet(
      context,
      current: filter,
      withStatus: withStatus,
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filtrar',
      onPressed: () => _open(context),
      icon: Badge(
        isLabelVisible: !filter.isEmpty,
        smallSize: 8,
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}
