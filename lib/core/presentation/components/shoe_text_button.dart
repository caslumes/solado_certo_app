import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_button.dart';

class ShoeTextButton extends StatelessWidget {
  const ShoeTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.textStyle,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String text;
  final TextStyle? textStyle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style =
        (textStyle ??
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white))
            ?.copyWith(height: 2);

    return ShoeButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox.square(
              dimension: (style?.fontSize ?? 14) * 2,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : Text(text.toUpperCase(), style: style),
    );
  }
}
