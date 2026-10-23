import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Callback signatures for Firebase Phone Verification lifecycle events.
typedef OnPhoneVerificationCompleted = void Function(PhoneAuthCredential credential);
typedef OnPhoneVerificationFailed = void Function(FirebaseAuthException exception, String userFriendlyMessage);
typedef OnPhoneCodeSent = void Function(String verificationId, int? resendToken);
typedef OnPhoneCodeAutoRetrievalTimeout = void Function(String verificationId);

/// Production-ready Firebase Authentication Service for KhetChaCha.
///
/// Handles real SMS phone verification, automatic SMS code retrieval on Android,
/// credential signing, and descriptive error mapping.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current authenticated user (if any).
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Formats standard Indian or international phone numbers to E.164.
  /// If a 10-digit number like 9876543210 is provided, prepends +91.
  static String formatToE164(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    // Standard 10-digit Indian mobile number
    if (cleaned.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return '+91$cleaned';
    }
    // Default fallback with +91 if length is 10 digits
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    return '+$cleaned';
  }

  /// Triggers Firebase Phone Verification with full lifecycle handling.
  ///
  /// - [onVerificationCompleted]: Automatically called when SMS retrieval succeeds instantly.
  /// - [onVerificationFailed]: Called when Firebase rejects request (quota, format, safety checks).
  /// - [onCodeSent]: Called when SMS code is dispatched to carrier, providing verificationId.
  /// - [onCodeAutoRetrievalTimeout]: Called when device auto-retrieval window lapses.
  Future<void> verifyPhoneNumber({
    required String rawPhoneNumber,
    required OnPhoneVerificationCompleted onVerificationCompleted,
    required OnPhoneVerificationFailed onVerificationFailed,
    required OnPhoneCodeSent onCodeSent,
    required OnPhoneCodeAutoRetrievalTimeout onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final formattedNumber = formatToE164(rawPhoneNumber);

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException exception) {
        final message = mapAuthExceptionToMessage(exception);
        onVerificationFailed(exception, message);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeAutoRetrievalTimeout(verificationId);
      },
    );
  }

  /// Signs in using a [PhoneAuthCredential] (e.g. from automatic SMS retrieval).
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  /// Completes manual OTP verification with the [verificationId] and [smsCode].
  Future<UserCredential> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Signs in anonymously so Firebase Auth issues a genuine User and UID for this session.
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Translates [FirebaseAuthException] codes to actionable, human-friendly guidance.
  static String mapAuthExceptionToMessage(FirebaseAuthException ex) {
    final rawMessage = ex.message ?? '';
    if (rawMessage.contains('BILLING_NOT_ENABLED') || ex.code == 'billing-not-enabled') {
      return 'Real telecom SMS requires the Firebase Blaze (Pay-as-you-go) plan. To test for free right now, add this number in Firebase Console under Authentication > Sign-in method > Phone > "Phone numbers for testing".';
    }

    switch (ex.code) {
      case 'invalid-phone-number':
        return 'The phone number entered is invalid. Please check the digits and try again.';
      case 'quota-exceeded':
        return 'SMS verification quota exceeded for this Firebase project. Please try again later or add test phone numbers in the Firebase Console.';
      case 'too-many-requests':
        return 'Too many verification attempts from this device. Please wait a few minutes before trying again.';
      case 'invalid-verification-code':
        return 'The OTP code you entered is incorrect. Please re-check the SMS message and try again.';
      case 'session-expired':
        return 'The OTP verification session has expired. Please tap "Resend OTP" to receive a new code.';
      case 'app-not-authorized':
        return 'App verification failed. Ensure your SHA-1 / SHA-256 fingerprint is added in Firebase Console and Play Integrity is enabled.';
      case 'captcha-check-failed':
        return 'Safety check verification failed. Please check device connectivity and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This farmer account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled in Firebase Console. Go to Authentication > Sign-in method > Phone to enable it.';
      default:
        return ex.message ?? 'An unexpected authentication error occurred (${ex.code}).';
    }
  }
}
