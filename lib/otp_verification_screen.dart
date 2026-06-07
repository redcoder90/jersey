import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'home.dart';
import 'models/checkout_session.dart';
import 'payment_success_page.dart';
import 'providers/auth_otp_controller.dart';
import 'services/otp_service.dart';

class OtpVerificationArgs {
  const OtpVerificationArgs.signup({
    required this.email,
    required this.verificationId,
    required this.name,
    required this.password,
  }) : purpose = OtpPurpose.signup,
       paymentSessionId = null,
       paymentResult = null;

  const OtpVerificationArgs.payment({
    required this.email,
    required this.verificationId,
    required this.paymentSessionId,
    required this.paymentResult,
  }) : purpose = OtpPurpose.payment,
       name = null,
       password = null;

  final String email;
  final String verificationId;
  final OtpPurpose purpose;
  final String? name;
  final String? password;
  final String? paymentSessionId;
  final PaymentResult? paymentResult;
}

class OTPVerificationScreen extends ConsumerStatefulWidget {
  const OTPVerificationScreen({super.key, required this.args});

  static const String routeName = '/otp-verification';

  final OtpVerificationArgs args;

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authOtpControllerProvider.notifier).startCooldown();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    final notifier = ref.read(authOtpControllerProvider.notifier);
    final args = widget.args;
    final success = args.purpose == OtpPurpose.signup
        ? await notifier.verifySignupOtp(
            verificationId: args.verificationId,
            email: args.email,
            otp: otp,
            name: args.name ?? '',
            password: args.password ?? '',
          )
        : await notifier.verifyPaymentOtp(
            verificationId: args.verificationId,
            email: args.email,
            otp: otp,
            paymentSessionId: args.paymentSessionId ?? '',
          );

    if (!success || !mounted) return;

    if (args.purpose == OtpPurpose.signup) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          result: args.paymentResult!,
          paymentSessionId: args.paymentSessionId!,
        ),
      ),
    );
  }

  Future<void> _resend() async {
    _otpController.clear();
    await ref
        .read(authOtpControllerProvider.notifier)
        .resendOtp(
          verificationId: widget.args.verificationId,
          email: widget.args.email,
          purpose: widget.args.purpose,
        );
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.length <= 2) return email;
    final name = parts.first;
    final hidden = List.filled(name.length - 2, '*').join();
    return '${name.substring(0, 2)}$hidden@${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authOtpControllerProvider);
    final otpLength = _otpController.text.trim().length;
    final isInvalidated = state.invalidated;
    final verifyEnabled =
        otpLength == 6 && !state.loading && !state.invalidated;
    final resendEnabled =
        !state.loading && (isInvalidated || state.countdownSeconds == 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        leading: IconButton(
          tooltip: 'Go Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: state.loading ? null : () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.password_outlined,
                        color: AppColors.accent,
                        size: 54,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        widget.args.purpose == OtpPurpose.signup
                            ? 'Verify Your Signup'
                            : 'Confirm Payment',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Enter the 6-digit OTP sent to ${_maskedEmail(widget.args.email)}.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _otpController,
                        enabled: !state.loading && !isInvalidated,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: AppTextStyles.headingMedium.copyWith(
                          letterSpacing: 8,
                          color: AppColors.backgroundDark,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'OTP',
                          hintText: '000000',
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (state.error != null)
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      if (state.error != null)
                        const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: verifyEnabled ? _verify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state.loading && !isInvalidated
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: resendEnabled ? _resend : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isInvalidated
                              ? Colors.white
                              : AppColors.backgroundDark,
                          backgroundColor: isInvalidated
                              ? AppColors.accent
                              : Colors.transparent,
                          side: BorderSide(
                            color: isInvalidated
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          state.countdownSeconds > 0 && !isInvalidated
                              ? 'Resend OTP in ${state.countdownSeconds}s'
                              : 'Resend OTP',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: state.loading
                            ? null
                            : () => Navigator.maybePop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
