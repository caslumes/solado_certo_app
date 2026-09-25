import 'package:flutter/material.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';

class ShoeButton extends StatelessWidget {
  const ShoeButton({
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          text.toUpperCase(),
          style:
              (textStyle ??
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white))
                  ?.copyWith(height: 2),
        ),
      ),
    );
  }
}
