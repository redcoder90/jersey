import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/checkout_session.dart';
import 'otp_verification_screen.dart';
import 'providers/auth_otp_controller.dart';
import 'services/payment_session_service.dart';

class BkashPaymentPage extends ConsumerStatefulWidget {
  const BkashPaymentPage({super.key, required this.session});

  final CheckoutSession session;

  @override
  ConsumerState<BkashPaymentPage> createState() => _BkashPaymentPageState();
}

class _BkashPaymentPageState extends ConsumerState<BkashPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _paymentSessionService = PaymentSessionService();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = PaymentResult(
        session: widget.session,
        paymentMethod: 'bkash',
        transactionId: _fakeTransactionId('BK'),
      );
      final paymentSession = await _paymentSessionService.createPaymentSession(
        paymentMethod: result.paymentMethod,
        transactionId: result.transactionId,
      );
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final verificationId = await ref
          .read(authOtpControllerProvider.notifier)
          .sendPaymentOtp(
            email: email,
            paymentSessionId: paymentSession.sessionId,
          );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        OTPVerificationScreen.routeName,
        arguments: OtpVerificationArgs.payment(
          email: email,
          verificationId: verificationId,
          paymentSessionId: paymentSession.sessionId,
          paymentResult: result,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final error = ref.read(authOtpControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Unable to send payment OTP.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^01\d{9}$').hasMatch(phone)) {
      return 'Enter a valid Bangladesh phone number';
    }
    return null;
  }

  String _fakeTransactionId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return PaymentInputShell(
      title: 'bKash Payment',
      subtitle: 'Tap to proceed with payment',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'bKash Phone Number',
                hintText: '01XXXXXXXXX',
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loading ? null : _continue,
              style: primaryPaymentButtonStyle(),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentInputShell extends StatelessWidget {
  const PaymentInputShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle primaryPaymentButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
