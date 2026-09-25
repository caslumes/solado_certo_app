import 'package:flutter/material.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';

final primaryTheme = ThemeData(
  primaryColor: AppColors.primaryColor,
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
  ),
);
