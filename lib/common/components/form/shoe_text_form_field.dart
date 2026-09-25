import 'package:flutter/material.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';

class ShoeTextFormField extends StatelessWidget {
  const ShoeTextFormField({
    super.key,
    this.hintText,
    this.controller,
    this.obscureText,
  });

  final String? hintText;
  final TextEditingController? controller;
  final bool? obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText ?? false,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        fillColor: AppColors.secondaryColor,
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        filled: true,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
