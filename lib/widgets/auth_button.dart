import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = isPrimary
        ? ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: AppTextStyles.button,
            elevation: 6,
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: AppColors.accent,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            side: const BorderSide(color: AppColors.accent, width: 1.8),
            textStyle: AppTextStyles.button,
          );

    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
              onPressed: enabled && !isLoading ? onPressed : null,
              style: style,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(label),
            )
          : OutlinedButton(
              onPressed: enabled && !isLoading ? onPressed : null,
              style: style,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text(label),
            ),
    );
  }
}
