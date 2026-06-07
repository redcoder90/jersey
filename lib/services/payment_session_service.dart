import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_session.dart';

class PaymentSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new payment session in Firestore.
  ///
  /// This ONLY happens when entering checkout verification.
  /// Status starts as "pending_verification".
  Future<PaymentSession> createPaymentSession({
    required String paymentMethod,
    required String transactionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user to create payment session.',
      );
    }

    // Generate unique session ID using timestamp and random suffix
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond % 10000).toString().padLeft(
      5,
      '0',
    );
    final sessionId = 'psession_${timestamp}_$random';
    final now = DateTime.now();

    final session = PaymentSession(
      sessionId: sessionId,
      userId: user.uid,
      status: 'pending_verification',
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      createdAt: now,
      email: user.email,
    );

    await _firestore
        .collection('payment_sessions')
        .doc(sessionId)
        .set(session.toFirestore());

    return session;
  }

  /// Record that a payment verification email was requested for this session.
  ///
  /// This does not verify the session. A trusted backend, email-link handler,
  /// or emulator/admin workflow must set status to "verified",
  /// verificationCompleted to true, and verifiedAt for payment approval.
  Future<PaymentSession> markVerificationEmailSent(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user to send payment verification.',
      );
    }

    final session = await _requireUserSession(sessionId);
    if (session.status != 'pending_verification') {
      return session;
    }

    final now = DateTime.now();
    await _collection.doc(sessionId).update({
      'email': user.email,
      'emailSentAt': now.toIso8601String(),
      'verificationCompleted': false,
    });

    return session.copyWith(email: user.email, emailSentAt: now);
  }

  /// Retrieve a payment session by ID.
  Future<PaymentSession?> getPaymentSession(String sessionId) async {
    try {
      final doc = await _collection.doc(sessionId).get();

      if (!doc.exists) {
        return null;
      }

      return PaymentSession.fromFirestore(doc.data() ?? {});
    } catch (e) {
      throw FirebaseException(
        plugin: 'payment_session_service',
        message: 'Failed to retrieve payment session: $e',
      );
    }
  }

  /// Mark a payment session as completed (payment processed and order created).
  ///
  /// This is called ONLY after order creation succeeds.
  Future<PaymentSession> markSessionCompleted(String sessionId) async {
    try {
      final session = await _requireUserSession(sessionId);

      if (!session.isVerified || session.isCompleted) {
        throw FirebaseException(
          plugin: 'payment_session_service',
          message: 'Payment session is not eligible for completion.',
        );
      }

      final updatedSession = session.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
      );

      await _collection.doc(sessionId).update({
        'status': 'completed',
        'completedAt': updatedSession.completedAt!.toIso8601String(),
      });

      return updatedSession;
    } catch (e) {
      throw FirebaseException(
        plugin: 'payment_session_service',
        message: 'Failed to mark session completed: $e',
      );
    }
  }

  /// Validate that a payment session exists and is in the verified state.
  ///
  /// This is the ONLY validation used for payment security.
  /// Returns true if and only if the session is verified in Firestore.
  Future<bool> isCurrentUserSessionVerified(String sessionId) async {
    try {
      final session = await _requireUserSession(sessionId);
      return session.isVerified && !session.isCompleted;
    } catch (e) {
      return false;
    }
  }

  /// Validate that a payment session can be processed.
  ///
  /// Checks:
  /// 1. Session exists
  /// 2. Session is verified
  /// 3. Session is not already completed
  /// 4. Session belongs to current user
  Future<bool> canProcessPayment(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final session = await getPaymentSession(sessionId);
      return session != null &&
          session.isVerified &&
          !session.isCompleted &&
          session.userId == user.uid;
    } catch (e) {
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('payment_sessions');
  }

  Future<PaymentSession> _requireUserSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user for payment session.',
      );
    }

    final session = await getPaymentSession(sessionId);
    if (session == null) {
      throw FirebaseException(
        plugin: 'payment_session_service',
        message: 'Payment session not found: $sessionId',
      );
    }
    if (session.userId != user.uid) {
      throw FirebaseException(
        plugin: 'payment_session_service',
        message: 'Payment session does not belong to this user.',
      );
    }

    return session;
  }
}
