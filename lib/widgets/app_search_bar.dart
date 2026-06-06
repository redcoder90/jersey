import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.search, color: AppColors.backgroundDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search jerseys, teams, brands...',
                hintStyle: AppTextStyles.body,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
