import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bkash_payment_page.dart';
import 'core/theme/app_spacing.dart';
import 'models/checkout_session.dart';
import 'otp_verification_screen.dart';
import 'providers/auth_otp_controller.dart';
import 'services/payment_session_service.dart';

class CardPaymentPage extends ConsumerStatefulWidget {
  const CardPaymentPage({super.key, required this.session});

  final CheckoutSession session;

  @override
  ConsumerState<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends ConsumerState<CardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryController = TextEditingController();
  final _paymentSessionService = PaymentSessionService();
  bool _loading = false;

  @override
  void dispose() {
    _cardController.dispose();
    _cvvController.dispose();
    _expiryController.dispose();
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
        paymentMethod: 'card',
        transactionId: _fakeTransactionId('CD'),
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

  String? _validateCardNumber(String? value) {
    final cardNumber = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{16}$').hasMatch(cardNumber)) {
      return 'Enter a 16-digit card number';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    final cvv = value?.trim() ?? '';
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return 'Enter a valid CVV';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    final expiry = value?.trim() ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(expiry);
    if (match == null) {
      return 'Use MM/YY format';
    }

    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final expiryDate = DateTime(year, month + 1, 0, 23, 59, 59);

    if (!expiryDate.isAfter(DateTime.now())) {
      return 'Expiry must be a future date';
    }

    return null;
  }

  String _fakeTransactionId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return PaymentInputShell(
      title: 'Card Payment',
      subtitle: 'Secure payment required to continue',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '16 digits',
              ),
              validator: _validateCardNumber,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                    ),
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    obscureText: true,
                    validator: _validateCvv,
                  ),
                ),
              ],
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
