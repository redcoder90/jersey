import 'dart:async';

import 'package:flutter/material.dart';

import 'common/widgets/auth_background.dart';
import 'common/widgets/auth_card.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_spacing.dart';
import 'home.dart';

class EmailVerificationSuccessScreen extends StatefulWidget {
  const EmailVerificationSuccessScreen({super.key});

  @override
  State<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends State<EmailVerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _autoRedirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _autoRedirectTimer = Timer(
      const Duration(milliseconds: 2400),
      _navigateToHome,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoRedirectTimer.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDeep,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(
                              (0.28 * 255).round(),
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Email Verified Successfully!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your Jersey Drip account is now active and ready to use.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'You can now browse products, place orders, and enjoy the full Jersey Drip experience.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
