import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';

class ShoeSearchBar extends StatelessWidget {
  const ShoeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ShoeTextFormField(
      hintText: 'pesquise algo...',
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          decoration: BoxDecoration(color: AppColors.tertiaryColor),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.search, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
