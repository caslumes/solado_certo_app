import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';

/// − value +, within [min] and [max]. A null [onChanged] disables it.
class ShoeQuantityStepper extends StatelessWidget {
  const ShoeQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    required this.max,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir quantidade',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: onChanged != null && value > min
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            tooltip: 'Aumentar quantidade',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: onChanged != null && value < max
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
