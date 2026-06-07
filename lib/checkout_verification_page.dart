import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_success_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/checkout_session.dart';
import 'models/payment_session.dart';
import 'services/payment_session_service.dart';

enum _VerificationStatus { notSent, sent, verified, notVerified }

class CheckoutVerificationPage extends StatefulWidget {
  const CheckoutVerificationPage({super.key, required this.result});

  final PaymentResult result;

  @override
  State<CheckoutVerificationPage> createState() =>
      _CheckoutVerificationPageState();
}

class _CheckoutVerificationPageState extends State<CheckoutVerificationPage> {
  bool _sending = false;
  bool _checking = false;
  bool _initializing = true;
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;
  _VerificationStatus _status = _VerificationStatus.notSent;

  PaymentSession? _paymentSession;
  final PaymentSessionService _sessionService = PaymentSessionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializePaymentSession();
      }
    });
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePaymentSession() async {
    try {
      // Create a new payment session in Firestore
      _paymentSession = await _sessionService.createPaymentSession(
        paymentMethod: widget.result.paymentMethod,
        transactionId: widget.result.transactionId,
      );

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Failed to initialize payment session. Please try again.',
        AppColors.error,
      );
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _sending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No authenticated user is available.',
        );
      }

      final paymentSession = _paymentSession;
      if (paymentSession == null) {
        throw StateError('Payment session is not ready.');
      }

      await user.sendEmailVerification();
      _paymentSession = await _sessionService.markVerificationEmailSent(
        paymentSession.sessionId,
      );

      if (mounted) {
        setState(() {
          _status = _VerificationStatus.sent;
        });
      }
      _startResendCooldown();
      _showMessage('Verification email sent');
    } catch (error) {
      if (!mounted) return;
      final message = error is FirebaseAuthException
          ? error.message ?? 'Unable to send verification email'
          : 'Unable to send verification email';
      _showMessage(message, AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _continueAfterVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      // CRITICAL: Verify payment session status from Firestore, NOT Firebase Auth.
      final sessionId = _paymentSession?.sessionId;
      if (sessionId == null) {
        throw StateError('Payment session is not ready.');
      }

      // Refresh to confirm
      final canProceed = await _sessionService.canProcessPayment(sessionId);
      if (!canProceed) {
        _showMessage(
          'Email not verified for this payment session',
          AppColors.error,
        );
        if (mounted) {
          setState(() {
            _status = _VerificationStatus.notVerified;
            _checking = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _status = _VerificationStatus.verified;
        });
      }

      _showMessage('Payment session verified', AppColors.success);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            result: widget.result,
            paymentSessionId: sessionId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = 'Unable to verify email status';
      _showMessage(message, AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _resendCooldownSeconds = 30;
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldownSeconds = 0;
        });
        return;
      }

      setState(() {
        _resendCooldownSeconds -= 1;
      });
    });
  }

  String get _sendButtonLabel {
    if (_sending) return 'Sending...';
    if (_resendCooldownSeconds > 0) {
      return 'Resend available in ${_resendCooldownSeconds}s';
    }
    return _status == _VerificationStatus.notSent
        ? 'Send Email'
        : 'Resend Link';
  }

  String get _verificationStatusLabel {
    switch (_status) {
      case _VerificationStatus.notSent:
        return 'Status: Not sent';
      case _VerificationStatus.sent:
        return 'Status: Sent';
      case _VerificationStatus.verified:
        return 'Status: Verified';
      case _VerificationStatus.notVerified:
        return 'Status: Not verified';
    }
  }

  Color get _verificationStatusColor {
    switch (_status) {
      case _VerificationStatus.verified:
        return AppColors.success;
      case _VerificationStatus.notVerified:
        return AppColors.error;
      case _VerificationStatus.sent:
        return AppColors.accent;
      case _VerificationStatus.notSent:
        return AppColors.textSecondary;
    }
  }

  void _showMessage(String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.backgroundDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.accent,
                    size: 54,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verify Payment Email',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'A verification email is required to complete payment. Open the message, confirm your email, and then tap the verification button.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _verificationStatusLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: _verificationStatusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton(
                    onPressed:
                        _sending ||
                            _resendCooldownSeconds > 0 ||
                            _paymentSession == null
                        ? null
                        : _sendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.backgroundDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_sendButtonLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _checking || _paymentSession == null
                        ? null
                        : _continueAfterVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_checking ? 'Checking...' : 'I Have Verified'),
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
