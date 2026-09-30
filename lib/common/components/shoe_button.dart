import 'package:flutter/material.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';

class ShoeButton extends StatelessWidget {
  const ShoeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: child,
            )
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onPressed, child: child),
            ),
    );
  }
}
