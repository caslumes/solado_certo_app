import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';

final primaryTheme = ThemeData(
  primaryColor: AppColors.primaryColor,
  iconTheme: IconThemeData(color: AppColors.primaryColor),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: AppColors.primaryColor,
    secondary: AppColors.secondaryColor,
  ),
  textTheme: TextTheme(
    headlineSmall: TextStyle(
      color: AppColors.primaryColor,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
      fontSize: 36,
    ),
    bodyMedium: TextStyle(
      color: AppColors.primaryColor,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
      fontSize: 20,
    ),
    bodySmall: TextStyle(
      color: AppColors.primaryColor,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
      fontSize: 16,
    ),
  ),
);
