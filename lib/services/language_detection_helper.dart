/// High-accuracy, offline Indic script and language detection helper for KhetChacha.
/// Maps farmer input text to the correct ISO language code across all 22 scheduled Indian languages + English.
class LanguageDetectionHelper {
  LanguageDetectionHelper._();

  /// Devanagari regional language marker words
  static const Map<String, List<String>> _devanagariMarkers = {
    'mr': ['आहे', 'नाही', 'पिक', 'शेतकरी', 'कशी', 'करावे', 'झाले', 'औषध', 'फवारणी', 'बोंडअळी', 'पाने'],
    'ne': ['छ', 'छैन', 'गर्ने', 'हुन्छ', 'भने', 'गर्नुहोस्', 'बाली'],
    'mai': ['अछि', 'होइछ', 'करब', 'हमरा', 'तोहर', 'गेल', 'छै', 'दबा'],
    'sa': ['अस्ति', 'भवति', 'कृषि', 'पादपस्य', 'रोगः', 'करोतु'],
    'kok': ['आसा', 'ना', 'करचें', 'शेतकार'],
    'doi': ['ऐ', 'नेईं', 'कन्ने', 'कीता'],
    'brx': ['दं', 'गैया', 'हाबनाय', 'आबाद'],
    'hi': ['है', 'हैं', 'क्या', 'करें', 'इस्तेमाल', 'कीटनाशक', 'फसल', 'पत्ते', 'उपाय', 'दवा', 'छिड़काव', 'रोग', 'खाद'],
  };

  /// Detects the target language from input query text.
  /// Falls back to [fallbackCode] if language is ambiguous or purely numeric/symbolic.
  static String detectLanguage(String text, {String fallbackCode = 'en'}) {
    final clean = text.trim();
    if (clean.isEmpty) return fallbackCode;

    // If text is purely numbers, measurements, or formula (e.g. "10-26-26 50kg")
    final withoutNumbersAndUnits = clean
        .replaceAll(RegExp(r'[0-9\s.,/\-+%:#@()]+', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'(kg|gm|g|ml|l|ltr|ha|acre|bigha|vigha|npk|dap|ph)',
            caseSensitive: false,
          ),
          '',
        );
    if (withoutNumbersAndUnits.isEmpty) {
      return fallbackCode;
    }

    int gujarati = 0;
    int devanagari = 0;
    int gurmukhi = 0;
    int bengaliAssamese = 0;
    int tamil = 0;
    int telugu = 0;
    int kannada = 0;
    int malayalam = 0;
    int odia = 0;
    int olChiki = 0;
    int meeteiMayek = 0;
    int arabic = 0;
    int latin = 0;

    for (final rune in clean.runes) {
      if (rune >= 0x0A80 && rune <= 0x0AFF) {
        gujarati++;
      } else if (rune >= 0x0900 && rune <= 0x097F) {
        devanagari++;
      } else if (rune >= 0x0A00 && rune <= 0x0A7F) {
        gurmukhi++;
      } else if (rune >= 0x0980 && rune <= 0x09FF) {
        bengaliAssamese++;
      } else if (rune >= 0x0B80 && rune <= 0x0BFF) {
        tamil++;
      } else if (rune >= 0x0C00 && rune <= 0x0C7F) {
        telugu++;
      } else if (rune >= 0x0C80 && rune <= 0x0CFF) {
        kannada++;
      } else if (rune >= 0x0D00 && rune <= 0x0D7F) {
        malayalam++;
      } else if (rune >= 0x0B00 && rune <= 0x0B7F) {
        odia++;
      } else if (rune >= 0x1C50 && rune <= 0x1C7F) {
        olChiki++;
      } else if (rune >= 0xABC0 && rune <= 0xABFF) {
        meeteiMayek++;
      } else if (rune >= 0x0600 && rune <= 0x06FF) {
        arabic++;
      } else if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
        latin++;
      }
    }

    // 1. Direct Script Matches
    if (gujarati > 0 && gujarati >= latin) return 'gu';
    if (gurmukhi > 0 && gurmukhi >= latin) return 'pa';
    if (tamil > 0 && tamil >= latin) return 'ta';
    if (telugu > 0 && telugu >= latin) return 'te';
    if (kannada > 0 && kannada >= latin) return 'kn';
    if (malayalam > 0 && malayalam >= latin) return 'ml';
    if (odia > 0 && odia >= latin) return 'or';
    if (olChiki > 0) return 'sat';
    if (meeteiMayek > 0) return 'mni';

    // 2. Eastern Nagari: Disambiguate Assamese vs Bengali
    if (bengaliAssamese > 0 && bengaliAssamese >= latin) {
      if (clean.contains('ৰ') || clean.contains('ৱ')) return 'as';
      return 'bn';
    }

    // 3. Perso-Arabic: Disambiguate Kashmiri, Sindhi, Urdu
    if (arabic > 0 && arabic >= latin) {
      if (clean.contains('ؠ') || clean.contains('ۄ') || clean.contains('ؽ')) return 'ks';
      if (clean.contains('ڄ') || clean.contains('ڃ') || clean.contains('ڳ') || clean.contains('ڱ') || clean.contains('ڏ') || clean.contains('ڦ')) return 'sd';
      return 'ur';
    }

    // 4. Devanagari: Disambiguate Hindi, Marathi, Nepali, Maithili, Sanskrit, Konkani, Dogri, Bodo
    if (devanagari > 0 && devanagari >= latin) {
      for (final entry in _devanagariMarkers.entries) {
        final lang = entry.key;
        final markers = entry.value;
        for (final marker in markers) {
          if (clean.contains(marker)) {
            return lang;
          }
        }
      }
      // If the currently selected app language is a Devanagari language, respect it
      if (['hi', 'mr', 'ne', 'mai', 'sa', 'kok', 'doi', 'brx'].contains(fallbackCode)) {
        return fallbackCode;
      }
      return 'hi';
    }

    // 5. Latin alphabet: English
    if (latin > 0) {
      return 'en';
    }

    return fallbackCode;
  }
}
