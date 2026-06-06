import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
    this.suffixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      style: AppTextStyles.input,
      cursorColor: AppColors.deepBlue,
      onChanged: onChanged,
      onFieldSubmitted:
          onFieldSubmitted ??
          (_) {
            if (nextFocusNode != null) {
              nextFocusNode!.requestFocus();
            }
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary.withAlpha((0.72 * 255).round()),
        ),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
