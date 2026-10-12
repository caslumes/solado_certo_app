import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';

class FeaturedItems extends StatelessWidget {
  const FeaturedItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Em alta",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.black),
            textAlign: TextAlign.start,
          ),
        ),
        SingleChildScrollView(
          physics: ScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 16.0,
            children: [
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
              Container(
                width: 200,
                height: 200,
                color: AppColors.secondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
