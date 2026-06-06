import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  AuthExceptionHandler._();

  static String getMessage(Exception exception) {
    if (exception is FirebaseAuthException) {
      switch (exception.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 8 characters.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Incorrect email or password.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'network-request-failed':
          return 'Check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'account-exists-with-different-credential':
          return 'An account exists with a different sign-in method.';
        case 'google-sign-in-cancelled':
          return 'Google sign-in was cancelled.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
