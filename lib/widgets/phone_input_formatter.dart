import 'package:flutter/services.dart';

/// Sanitizes an Indian phone number string by removing leading country code
/// (+91 or 91) and leading 0, ensuring exactly a 10-digit mobile number.
String sanitizeIndianPhoneNumber(String raw) {
  String text = raw.trim();
  if (text.startsWith('+91')) {
    text = text.substring(3).trim();
  } else if (text.startsWith('+')) {
    text = text.substring(1).trim();
  }

  // Extract digits only
  String digits = text.replaceAll(RegExp(r'\D'), '');

  // If text starts with 91 and has more than 10 digits (e.g. 919876543210 from Android Autofill)
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length > 10 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  // If still longer than 10 digits, take the trailing 10 digits
  if (digits.length > 10) {
    digits = digits.substring(digits.length - 10);
  }

  return digits;
}

/// Custom TextInputFormatter for Indian mobile number fields.
/// Handles Android Autofill, Google keyboard suggestions, and copy-paste
/// where numbers often arrive prefixed with "+91", "91", or leading "0".
class IndianPhoneNumberInputFormatter extends TextInputFormatter {
  const IndianPhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    if (rawText.isEmpty) {
      return newValue;
    }

    final sanitized = sanitizeIndianPhoneNumber(rawText);

    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}
