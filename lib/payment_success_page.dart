import 'dart:async';

import 'package:flutter/material.dart';

import 'models/checkout_session.dart';
import 'order_receipt_page.dart';
import 'services/order_service.dart';
import 'services/payment_session_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({
    super.key,
    required this.result,
    required this.paymentSessionId,
  });

  final PaymentResult result;
  final String paymentSessionId;

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final PaymentSessionService _sessionService = PaymentSessionService();
  late final AnimationController _controller;
  bool _creatingOrder = true;
  bool _checkingVerification = true;
  bool _verificationBlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_verifyEmailThenCreateOrder());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyEmailThenCreateOrder() async {
    try {
      // CRITICAL: Verify payment session from Firestore, NOT Firebase Auth.
      // This is the only source of truth for payment verification.
      final isVerified = await _sessionService.isCurrentUserSessionVerified(
        widget.paymentSessionId,
      );

      if (!isVerified) {
        _blockPaymentSuccess('Email not verified for this payment session');
        return;
      }

      if (!mounted) return;
      setState(() {
        _checkingVerification = false;
      });
      _controller.forward();
      await _createOrderAndContinue();
    } catch (error) {
      if (!mounted) return;
      _blockPaymentSuccess('Unable to verify payment session');
    }
  }

  void _blockPaymentSuccess(String message) {
    if (!mounted) return;
    setState(() {
      _checkingVerification = false;
      _creatingOrder = false;
      _verificationBlocked = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createOrderAndContinue() async {
    try {
      final order = await _orderService.createPaidOrder(
        items: widget.result.session.items,
        paymentMethod: widget.result.paymentMethod,
        transactionId: widget.result.transactionId,
      );

      // Mark payment session as completed after order is created
      await _sessionService.markSessionCompleted(widget.paymentSessionId);

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderReceiptPage(order: order)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creatingOrder = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to create order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingVerification) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_verificationBlocked) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          foregroundColor: AppColors.backgroundDark,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Email not verified yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please check your inbox and verify first.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Back to Verification'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 62,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Payment Successful',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Transaction ID: ${widget.result.transactionId}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_creatingOrder)
                  const CircularProgressIndicator()
                else
                  Text(
                    'Please go back and try again.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
