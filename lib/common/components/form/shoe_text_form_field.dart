import 'package:flutter/material.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';

class ShoeTextFormField extends StatelessWidget {
  const ShoeTextFormField({
    super.key,
    this.hintText,
    this.controller,
    this.obscureText,
    this.labelText,
  });

  final String? hintText;
  final TextEditingController? controller;
  final bool? obscureText;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        labelText != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labelText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : SizedBox.shrink(),
        TextFormField(
          controller: controller,
          obscureText: obscureText ?? false,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            fillColor: AppColors.secondaryColor,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            filled: true,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
