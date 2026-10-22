import 'package:flutter/material.dart';

/// Represents a supported language in the KhetChacha application.
class AppLanguage {
  /// ISO 639-1 language code (e.g., 'gu', 'hi', 'en', 'bn', etc.)
  final String code;

  /// Optional script code for languages that require script distinction
  final String? scriptCode;

  /// English name of the language
  final String englishName;

  /// Native representation of the language name in its own script
  final String nativeName;

  /// True if the script is read from right to left (e.g., Urdu, Sindhi, Kashmiri Arabic)
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    this.scriptCode,
    this.isRtl = false,
  });

  /// Returns the Flutter [Locale] representation
  Locale get locale => Locale(code, scriptCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          scriptCode == other.scriptCode;

  @override
  int get hashCode => code.hashCode ^ (scriptCode?.hashCode ?? 0);
}
