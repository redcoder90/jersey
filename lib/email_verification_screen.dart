import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'common/widgets/auth_background.dart';
import 'common/widgets/auth_card.dart';
import 'core/exceptions/auth_exception_handler.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'widgets/auth_button.dart';
import 'auth_screen.dart';
import 'email_verification_success_screen.dart';
import 'services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.userEmail});

  final String userEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
    });
    try {
      await _authService.reloadCurrentUser();
      if (_authService.isEmailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmailVerificationSuccessScreen(),
          ),
        );
      } else {
        _showMessage(
          'Email is still not verified. Please click the link again.',
          Colors.orange,
        );
      }
    } catch (error) {
      final message = error is Exception
          ? AuthExceptionHandler.getMessage(error)
          : 'Verification check failed. Please try again.';
      _showMessage(message, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });
    try {
      await _authService.sendEmailVerification();
      _showMessage('Verification email resent.', Colors.green);
      _startCooldown();
    } catch (error) {
      final message = error is Exception
          ? AuthExceptionHandler.getMessage(error)
          : 'Unable to resend verification email. Please try again.';
      _showMessage(message, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _cooldownSeconds -= 1;
        });
      }
    });
  }

  void _showMessage(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 96,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Verify your email',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.deepBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Open the verification email and tap the link to activate your account.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          widget.userEmail,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.deepBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AuthButton(
                          label: 'I have verified',
                          onPressed: _checkVerification,
                          isLoading: _isChecking,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthButton(
                          label: _cooldownSeconds > 0
                              ? 'Resend Email ($_cooldownSeconds)s'
                              : 'Resend Email',
                          onPressed: _resendVerificationEmail,
                          isLoading: _isResending,
                          isPrimary: false,
                          enabled: _cooldownSeconds == 0 && !_isResending,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Please open the verification email and click the link. When complete, tap "I have verified".',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _logout,
                            child: const Text('Back to Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
