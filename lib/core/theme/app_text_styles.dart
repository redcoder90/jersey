import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headingLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.18,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle input = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );
}
