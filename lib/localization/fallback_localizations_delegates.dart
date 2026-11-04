import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Fallback MaterialLocalizations Delegate for Indian Languages.
///
/// Flutter's built-in [GlobalMaterialLocalizations] only supports ~78 international languages.
/// Several official Indian languages (e.g. Dogri 'doi', Bodo 'brx', Konkani 'kok', Maithili 'mai',
/// Santali 'sat', Kashmiri 'ks', Sindhi 'sd', Manipuri 'mni', Sanskrit 'sa') are not present
/// in Flutter's built-in material catalog.
///
/// This delegate intercepts unsupported locales and transparently loads the appropriate
/// native regional script fallback (e.g. Hindi 'hi' for Devanagari languages, Urdu 'ur' for Perso-Arabic,
/// or Bengali 'bn' for Manipuri), completely eliminating the red screen crash in Flutter.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    if (GlobalMaterialLocalizations.delegate.isSupported(locale)) {
      return await GlobalMaterialLocalizations.delegate.load(locale);
    }
    final fallback = _resolveFallbackLocale(locale);
    return await GlobalMaterialLocalizations.delegate.load(fallback);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;

  static Locale _resolveFallbackLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'doi': // Dogri (Devanagari) -> Hindi
      case 'brx': // Bodo (Devanagari) -> Hindi
      case 'kok': // Konkani (Devanagari) -> Hindi
      case 'mai': // Maithili (Devanagari) -> Hindi
      case 'sa': // Sanskrit (Devanagari) -> Hindi
      case 'sat': // Santali -> Hindi
        return const Locale('hi');
      case 'ks': // Kashmiri -> Urdu
      case 'sd': // Sindhi -> Urdu
        return const Locale('ur');
      case 'mni': // Manipuri -> Bengali
        return const Locale('bn');
      default:
        return const Locale('hi');
    }
  }
}

/// Fallback CupertinoLocalizations Delegate for unsupported Indian Languages.
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    if (GlobalCupertinoLocalizations.delegate.isSupported(locale)) {
      return await GlobalCupertinoLocalizations.delegate.load(locale);
    }
    final fallback = _resolveFallbackLocale(locale);
    return await GlobalCupertinoLocalizations.delegate.load(fallback);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;

  static Locale _resolveFallbackLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'doi':
      case 'brx':
      case 'kok':
      case 'mai':
      case 'sa':
      case 'sat':
        return const Locale('hi');
      case 'ks':
      case 'sd':
        return const Locale('ur');
      case 'mni':
        return const Locale('bn');
      default:
        return const Locale('en');
    }
  }
}

/// Fallback WidgetsLocalizations Delegate for unsupported Indian Languages.
class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    if (GlobalWidgetsLocalizations.delegate.isSupported(locale)) {
      return await GlobalWidgetsLocalizations.delegate.load(locale);
    }
    return await GlobalWidgetsLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}
