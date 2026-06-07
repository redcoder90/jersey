import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/email_otp_service.dart';
import '../services/otp_service.dart';
import '../services/payment_session_service.dart';

final emailOtpServiceProvider = Provider<EmailOtpService>((ref) {
  return EmailOtpService();
});

final otpProvider = Provider<OtpService>((ref) {
  return OtpService(emailOtpService: ref.watch(emailOtpServiceProvider));
});

final authOtpControllerProvider =
    NotifierProvider<AuthOtpController, AuthOtpState>(AuthOtpController.new);

class AuthOtpState {
  const AuthOtpState({
    this.loading = false,
    this.error,
    this.countdownSeconds = 0,
    this.verified = false,
    this.invalidated = false,
  });

  final bool loading;
  final String? error;
  final int countdownSeconds;
  final bool verified;
  final bool invalidated;

  AuthOtpState copyWith({
    bool? loading,
    Object? error = _sentinel,
    int? countdownSeconds,
    bool? verified,
    bool? invalidated,
  }) {
    return AuthOtpState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      verified: verified ?? this.verified,
      invalidated: invalidated ?? this.invalidated,
    );
  }

  static const Object _sentinel = Object();
}

class AuthOtpController extends Notifier<AuthOtpState> {
  late final OtpService _otpService;
  late final AuthService _authService;
  late final PaymentSessionService _paymentSessionService;
  Timer? _cooldownTimer;

  @override
  AuthOtpState build() {
    _otpService = ref.watch(otpProvider);
    _authService = AuthService();
    _paymentSessionService = PaymentSessionService();
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const AuthOtpState();
  }

  Future<String> sendSignupOtp({required String email}) async {
    return _createOtp(email: email, purpose: OtpPurpose.signup);
  }

  Future<String> sendPaymentOtp({
    required String email,
    required String paymentSessionId,
  }) async {
    return _createOtp(
      email: email,
      purpose: OtpPurpose.payment,
      verificationId: 'payment_$paymentSessionId',
    );
  }

  Future<void> resendOtp({
    required String verificationId,
    required String email,
    required OtpPurpose purpose,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _otpService.resendOtp(
        verificationId: verificationId,
        email: email,
        purpose: purpose,
      );
      state = state.copyWith(
        loading: false,
        invalidated: false,
        verified: false,
        error: null,
      );
      startCooldown();
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: _messageFromError(
          error,
          'Unable to resend OTP. Please try again.',
        ),
      );
    }
  }

  Future<bool> verifySignupOtp({
    required String verificationId,
    required String email,
    required String otp,
    required String name,
    required String password,
  }) async {
    final verified = await _verifyOtp(
      verificationId: verificationId,
      email: email,
      purpose: OtpPurpose.signup,
      otp: otp,
    );
    if (!verified) return false;

    try {
      state = state.copyWith(loading: true, error: null);
      await _authService.signUp(name, email, password);
      await _otpService.deleteOtpRecord(verificationId);
      state = state.copyWith(loading: false, verified: true, error: null);
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        verified: false,
        error: 'OTP verified, but account creation failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyPaymentOtp({
    required String verificationId,
    required String email,
    required String otp,
    required String paymentSessionId,
  }) async {
    final verified = await _verifyOtp(
      verificationId: verificationId,
      email: email,
      purpose: OtpPurpose.payment,
      otp: otp,
    );
    if (!verified) return false;

    try {
      state = state.copyWith(loading: true, error: null);
      await _paymentSessionService.markSessionVerified(paymentSessionId);
      await _otpService.deleteOtpRecord(verificationId);
      state = state.copyWith(loading: false, verified: true, error: null);
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        verified: false,
        error:
            'OTP verified, but payment confirmation failed. Please try again.',
      );
      return false;
    }
  }

  void startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(
      countdownSeconds: OtpService.resendCooldown.inSeconds,
    );

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.countdownSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(countdownSeconds: 0);
        return;
      }
      state = state.copyWith(countdownSeconds: next);
    });
  }

  Future<String> _createOtp({
    required String email,
    required OtpPurpose purpose,
    String? verificationId,
  }) async {
    state = state.copyWith(loading: true, error: null, invalidated: false);
    try {
      final id = await _otpService.createOtpRecord(
        email: email,
        purpose: purpose,
        verificationId: verificationId,
      );
      state = state.copyWith(loading: false, error: null);
      return id;
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: _messageFromError(
          error,
          'Unable to send OTP. Please try again.',
        ),
      );
      rethrow;
    }
  }

  Future<bool> _verifyOtp({
    required String verificationId,
    required String email,
    required OtpPurpose purpose,
    required String otp,
  }) async {
    state = state.copyWith(loading: true, error: null);
    final result = await _otpService.verifyOtp(
      verificationId: verificationId,
      email: email,
      purpose: purpose,
      otp: otp,
    );

    state = state.copyWith(
      loading: false,
      verified: result.success,
      invalidated: result.invalidated,
      error: result.message,
    );
    return result.success;
  }

  String _messageFromError(Object error, String fallback) {
    if (error is StateError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }
}
