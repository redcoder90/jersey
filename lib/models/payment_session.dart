import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSession {
  PaymentSession({
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.createdAt,
    this.email,
    this.emailSentAt,
    this.verificationCompleted = false,
    this.verifiedAt,
    this.completedAt,
  });

  /// Unique payment session ID
  final String sessionId;

  /// User performing the payment
  final String userId;

  /// Session status: pending_verification, verified, completed, failed
  final String status;

  /// Payment method: bkash, card
  final String paymentMethod;

  /// Transaction ID for this payment
  final String transactionId;

  /// When session was created
  final DateTime createdAt;

  /// Email address used for this payment session verification
  final String? email;

  /// When the payment OTP email was requested
  final DateTime? emailSentAt;

  /// Transaction-level completion flag for payment verification
  final bool verificationCompleted;

  /// When user verified email for this session (null if not verified)
  final DateTime? verifiedAt;

  /// When payment was completed and order created
  final DateTime? completedAt;

  /// Returns true only if this session is verified
  bool get isVerified =>
      status == 'verified' && verificationCompleted && verifiedAt != null;

  /// Returns true only if payment was completed
  bool get isCompleted => status == 'completed';

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'sessionId': sessionId,
      'userId': userId,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'emailSentAt': emailSentAt?.toIso8601String(),
      'verificationCompleted': verificationCompleted,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };

    data.removeWhere((_, value) => value == null);
    return data;
  }

  /// Create from Firestore document
  factory PaymentSession.fromFirestore(Map<String, dynamic> doc) {
    return PaymentSession(
      sessionId: doc['sessionId'] as String? ?? '',
      userId: doc['userId'] as String? ?? '',
      status: doc['status'] as String? ?? 'pending_verification',
      paymentMethod: doc['paymentMethod'] as String? ?? '',
      transactionId: doc['transactionId'] as String? ?? '',
      createdAt: _readDate(doc['createdAt']) ?? DateTime.now(),
      email: doc['email'] as String?,
      emailSentAt: _readDate(doc['emailSentAt']),
      verificationCompleted: doc['verificationCompleted'] as bool? ?? false,
      verifiedAt: _readDate(doc['verifiedAt']),
      completedAt: _readDate(doc['completedAt']),
    );
  }

  /// Create a copy with updated fields
  PaymentSession copyWith({
    String? status,
    String? email,
    DateTime? emailSentAt,
    bool? verificationCompleted,
    DateTime? verifiedAt,
    DateTime? completedAt,
  }) {
    return PaymentSession(
      sessionId: sessionId,
      userId: userId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      createdAt: createdAt,
      email: email ?? this.email,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      verificationCompleted:
          verificationCompleted ?? this.verificationCompleted,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
