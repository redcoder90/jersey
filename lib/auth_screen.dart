import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/exceptions/auth_exception_handler.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/validators/validators.dart';
import 'common/widgets/auth_background.dart';
import 'common/widgets/auth_card.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'forgot_password_screen.dart';
import 'home.dart';
import 'otp_verification_screen.dart';
import 'providers/auth_otp_controller.dart';
import 'services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateFormValidity);
    _emailController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfAuthenticated();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _redirectIfAuthenticated() async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _authService.reloadCurrentUser();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showMessage(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String? _passwordValidator(String? value) {
    return _isLogin ? null : Validators.validatePassword(value);
  }

  void _updateFormValidity() {
    final emailValid = _isLogin
        ? _emailController.text.trim().isNotEmpty
        : Validators.validateEmail(_emailController.text) == null;
    final passwordValid = _isLogin
        ? _passwordController.text.trim().isNotEmpty
        : Validators.validatePassword(_passwordController.text) == null;
    final nameValid = _isLogin
        ? true
        : Validators.validateName(_nameController.text) == null;

    final valid = emailValid && passwordValid && nameValid;
    if (valid != _isFormValid) {
      setState(() {
        _isFormValid = valid;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await _authService.signIn(email, password);
        await _authService.reloadCurrentUser();
        await _navigateToHome();
      } else {
        final verificationId = await ref
            .read(authOtpControllerProvider.notifier)
            .sendSignupOtp(email: email);
        _showMessage('OTP sent. Check your inbox.', Colors.green);
        await _navigateToOtp(
          OtpVerificationArgs.signup(
            email: email,
            verificationId: verificationId,
            name: name,
            password: password,
          ),
        );
      }
    } catch (error) {
      final otpError = ref.read(authOtpControllerProvider).error;
      final message = otpError != null && otpError.isNotEmpty
          ? otpError
          : error is Exception
          ? AuthExceptionHandler.getMessage(error)
          : 'Something went wrong. Please try again.';
      _showMessage(message, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToForgotPassword() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('[AuthScreen] _signInWithGoogle tapped');
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      debugPrint('[AuthScreen] Google sign-in result: ${result.user?.email}');
      await _authService.reloadCurrentUser();
      await _navigateToHome();
    } catch (error, stackTrace) {
      debugPrint('[AuthScreen] Google sign-in failed: $error');
      debugPrint(stackTrace.toString());
      final message = error is Exception
          ? AuthExceptionHandler.getMessage(error)
          : 'Google sign in failed. Please try again.';
      _showMessage(message, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _passwordController.clear();
      if (_isLogin) {
        _nameController.clear();
      }
    });
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _navigateToOtp(OtpVerificationArgs args) async {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      OTPVerificationScreen.routeName,
      arguments: args,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Jersey Drip',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isLogin
                        ? 'Sign in to continue shopping'
                        : 'Join Jersey Drip and explore premium sportswear',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 64,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AuthHeader(
                          title: _isLogin
                              ? 'Welcome back'
                              : 'Create your account',
                          subtitle: _isLogin
                              ? 'Sign in to continue shopping.'
                              : 'Join Jersey Drip and explore premium sportswear.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Form(
                          key: _formKey,
                          autovalidateMode: _isLogin
                              ? AutovalidateMode.disabled
                              : AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              if (!_isLogin) ...[
                                AuthTextField(
                                  controller: _nameController,
                                  label: 'Full name',
                                  hintText: 'e.g. Jordan Miles',
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.validateName,
                                  focusNode: _nameFocusNode,
                                  nextFocusNode: _emailFocusNode,
                                  onChanged: (_) => _updateFormValidity(),
                                  autofillHints: const [AutofillHints.name],
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hintText: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.validateEmail,
                                focusNode: _emailFocusNode,
                                nextFocusNode: _passwordFocusNode,
                                onChanged: (_) => _updateFormValidity(),
                                autofillHints: const [AutofillHints.email],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hintText: _isLogin
                                    ? 'Enter your password'
                                    : 'Enter a secure password',
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: _passwordValidator,
                                focusNode: _passwordFocusNode,
                                onChanged: (_) => _updateFormValidity(),
                                autofillHints: const [AutofillHints.password],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AuthButton(
                                label: _isLogin ? 'Sign In' : 'Continue',
                                onPressed: _submit,
                                isLoading: _isLoading,
                                enabled: _isFormValid && !_isLoading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _goToForgotPassword,
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTextStyles.link.copyWith(
                                        color: AppColors.deepBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              AuthButton(
                                label: _isLogin
                                    ? 'Continue with Google'
                                    : 'Create account with Google',
                                onPressed: _signInWithGoogle,
                                isLoading: _isLoading,
                                isPrimary: false,
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                child: Text(
                                  _isLogin
                                      ? 'New to Jersey Drip? Sign up today'
                                      : 'Already have an account? Sign In',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.link.copyWith(
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
