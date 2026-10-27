import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';

class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.isDiscount = false,
  });

  final String label;
  final double value;
  final bool emphasized;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.bodyMedium : textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          isDiscount && value > 0
              ? '- ${formatCurrency(value)}'
              : formatCurrency(value),
          style: style,
        ),
      ],
    );
  }
}
