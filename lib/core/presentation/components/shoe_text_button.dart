import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_button.dart';

class ShoeTextButton extends StatelessWidget {
  const ShoeTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.textStyle,
  });

  final VoidCallback onPressed;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ShoeButton(
      onPressed: onPressed,
      child: Text(
        text.toUpperCase(),
        style:
            (textStyle ??
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white))
                ?.copyWith(height: 2),
      ),
    );
  }
}
