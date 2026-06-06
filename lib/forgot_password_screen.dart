import 'package:flutter/material.dart';

import 'core/exceptions/auth_exception_handler.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/validators/validators.dart';
import 'common/widgets/auth_background.dart';
import 'common/widgets/auth_card.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';
import 'services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    try {
      await _authService.sendPasswordReset(email);
      _showMessage('Password reset email sent.', Colors.green);
    } catch (error) {
      final message = error is Exception
          ? AuthExceptionHandler.getMessage(error)
          : 'Unable to reset password. Please try again.';
      _showMessage(message, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Reset your password and get back to Jersey Drip quickly.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Send reset link',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.deepBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Enter your registered email and we will send a link with instructions.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hintText: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                validator: Validators.validateEmail,
                                focusNode: _emailFocusNode,
                                autofillHints: const [AutofillHints.email],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AuthButton(
                                label: 'Send Reset Link',
                                onPressed: _submit,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : Navigator.of(context).pop,
                                child: const Text('Back to Sign In'),
                              ),
                            ],
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
