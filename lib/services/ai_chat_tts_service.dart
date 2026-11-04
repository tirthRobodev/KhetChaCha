import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Audio Playback State for AI Chat TTS
enum AiTtsState { idle, loading, speaking, error }

/// Voice availability check result
enum AiVoiceAvailability { available, notInstalled, unsupported }

/// Dedicated multilingual Text-to-Speech (TTS) service for KhetChacha AI Chat.
///
/// Features:
/// - Supports all 22 Eighth Schedule Indian Languages + English (23 total).
/// - Enforces single-playback session: starting a new answer immediately halts previous.
/// - Verifies device voice installation before speaking; prevents cross-language distortion.
/// - Provides localized missing-voice notices and Android TTS setup guidance.
/// - Clean mock mode and lifecycle management for automated Flutter tests.
class AiChatTtsService extends ChangeNotifier {
  AiChatTtsService._internal();
  static final AiChatTtsService instance = AiChatTtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  String? _currentlySpeakingMessageId;
  AiTtsState _state = AiTtsState.idle;
  String? _activeLocale;
  String? _lastErrorMessage;

  // Testing & Mocking properties
  bool _useMockMode = false;
  final Set<String> _mockAvailableLocales = {
    'gu-IN', 'hi-IN', 'en-IN', 'pa-IN', 'mr-IN', 'bn-IN', 'ta-IN', 'te-IN', 'kn-IN', 'ml-IN', 'or-IN', 'ur-IN'
  };

  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  String? get currentlySpeakingMessageId => _currentlySpeakingMessageId;
  AiTtsState get state => _state;
  String? get activeLocale => _activeLocale;
  String? get lastErrorMessage => _lastErrorMessage;

  bool isMessageSpeaking(String messageId) =>
      _currentlySpeakingMessageId == messageId && _state == AiTtsState.speaking;

  bool isMessageLoading(String messageId) =>
      _currentlySpeakingMessageId == messageId && _state == AiTtsState.loading;

  /// BCP-47 locale mapping for all 22 scheduled Indian languages + English
  static const Map<String, String> bcp47LocaleMap = {
    'en': 'en-IN',
    'gu': 'gu-IN',
    'hi': 'hi-IN',
    'pa': 'pa-IN',
    'mr': 'mr-IN',
    'bn': 'bn-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'kn': 'kn-IN',
    'ml': 'ml-IN',
    'or': 'or-IN',
    'as': 'as-IN',
    'ur': 'ur-IN',
    'ne': 'ne-NP',
    'sa': 'sa-IN',
    'kok': 'kok-IN',
    'mai': 'mai-IN',
    'doi': 'doi-IN',
    'ks': 'ks-IN',
    'sd': 'sd-IN',
    'brx': 'brx-IN',
    'mni': 'mni-IN',
    'sat': 'sat-IN',
  };

  /// Localized "Listen to Answer" labels for speaker button across all 23 languages
  static const Map<String, String> listenLabels = {
    'gu': 'જવાબ સાંભળો',
    'hi': 'उत्तर सुनें',
    'pa': 'ਜਵਾਬ ਸੁਣੋ',
    'mr': 'उत्तर ऐका',
    'bn': 'উত্তর শুনুন',
    'ta': 'பதிலைக் கேளுங்கள்',
    'te': 'సమాధానం వినండి',
    'kn': 'ಉತ್ತರವನ್ನು ಆಲಿಸಿ',
    'ml': 'ഉത്തരം കേൾക്കുക',
    'or': 'ଉତ୍ତର ଶୁଣନ୍ତୁ',
    'as': 'উত্তৰ শুনক',
    'ur': 'جواب سنیں',
    'ne': 'उत्तर सुन्नुहोस्',
    'sa': 'उत्तरं शृणोतु',
    'kok': 'जाप आयकात',
    'mai': 'उत्तर सुनू',
    'doi': 'जवाब सुनो',
    'ks': 'جواب بوزِو',
    'sd': 'جواب ٻڌو',
    'brx': 'फिननाय खोनासं',
    'mni': 'পাউখুম তাবিয়ু',
    'sat': 'ᱛᱮᱞᱟ ᱟᱸᱡᱚᱢ ᱢᱮ',
    'en': 'Listen to Answer',
  };

  /// Localized "Stop Audio" labels for speaker button across all 23 languages
  static const Map<String, String> stopLabels = {
    'gu': 'અવાજ બંધ કરો',
    'hi': 'आवाज़ बंद करें',
    'pa': 'ਆਵਾਜ਼ ਬੰਦ ਕਰੋ',
    'mr': 'आवाज थांबवा',
    'bn': 'শব্দ বন্ধ করুন',
    'ta': 'நிறுத்துங்கள்',
    'te': 'ఆపివేయి',
    'kn': 'ನಿಲ್ಲಿಸಿ',
    'ml': 'നിർത്തുക',
    'or': 'ବନ୍ଦ କରନ୍ତୁ',
    'as': 'শব্দ বন্ধ কৰক',
    'ur': 'روکیں',
    'ne': 'रोक्नुहोस्',
    'sa': 'स्थगयतु',
    'kok': 'थांबयात',
    'mai': 'रोकू',
    'doi': 'रोको',
    'ks': 'بند کٔریو',
    'sd': 'بند ڪريو',
    'brx': 'थाद\'हो',
    'mni': 'লেপহন্নবা',
    'sat': 'ᱛᱷᱩᱠᱟᱹᱢ',
    'en': 'Stop Audio',
  };

  /// Localized explanation messages when language voice is not installed on device
  static const Map<String, String> missingVoiceNotices = {
    'gu': 'તમારા ફોનમાં ગુજરાતી અવાજ (TTS Voice) ઇન્સ્ટોલ કરેલો નથી. કૃપા કરીને ફોન સેટિંગ્સમાંથી Google TTS વૉઇસ ડાઉનલોડ કરો.',
    'hi': 'आपके फोन में हिंदी आवाज़ (TTS Voice) इंस्टॉल नहीं है। कृपया सेटिंग्स से Google TTS वॉइस डाउनलोड करें।',
    'pa': 'ਤੁਹਾਡੇ ਫ਼ੋਨ ਵਿੱਚ ਪੰਜਾਬੀ ਆਵਾਜ਼ (TTS Voice) ਇੰਸਟਾਲ ਨਹੀਂ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਸੈਟਿੰਗਾਂ ਤੋਂ Google TTS ਵੌਇਸ ਡਾਊਨਲੋਡ ਕਰੋ।',
    'mr': 'तुमच्या फोनमध्ये मराठी आवाज (TTS Voice) इन्स्टॉल नाही. कृपया सेटिंग्जमधून Google TTS व्हॉइस डाउनलोड करा.',
    'bn': 'আপনার ফোনে বাংলা ভয়েস (TTS Voice) ইনস্টল নেই। অনুগ্রহ করে সেটিংস থেকে Google TTS ভয়েস ডাউনলোড করুন।',
    'ta': 'உங்கள் தொலைபேசியில் தமிழ் குரல் நிறுவப்படவில்லை. அமைப்புகளிலிருந்து Google TTS குரலைப் பதிவிறக்கவும்.',
    'te': 'మీ ఫోన్‌లో తెలుగు వాయిస్ ఇన్‌స్టాల్ చేయబడలేదు. దయచేసి సెట్టింగ్‌ల నుండి Google TTS వాయిస్‌ను డౌన్‌లోഡ് చేయండి.',
    'kn': 'ನಿಮ್ಮ ಫೋನ್‌ನಲ್ಲಿ ಕನ್ನಡ ಧ್ವನಿ ಸ್ಥಾಪಿಸಲಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ Google TTS ಧ್ವನಿಯನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ.',
    'ml': 'നിങ്ങളുടെ ഫോണിൽ മലയാളം ശബ്ദം ഇൻസ്റ്റാൾ ചെയ്തിട്ടില്ല. ക്രമീകരണങ്ങളിൽ നിന്ന് Google TTS വോയ്സ് ഡൗൺലോഡ് ചെയ്യുക.',
    'or': 'ଆପଣଙ୍କ ଫୋନରେ ଓଡ଼ିଆ ଭଏସ୍ ଇନଷ୍ଟଲ୍ ହୋଇନାହିଁ। ଦୟାକରି ସେଟିଙ୍ଗ୍ସରୁ Google TTS ଡାଉନଲୋଡ୍ କରନ୍ତୁ।',
    'as': 'আপোনাৰ ফোনত অসমীয়া কণ্ঠ ইনষ্টল কৰা নাই। অনুগ্ৰহ কৰি ছেটিংছৰ পৰা Google TTS ভয়েচ ডাউনলোড কৰক।',
    'ur': 'آپ کے فون میں اردو آواز انسٹال نہیں ہے۔ براہ کرم سیٹنگز سے Google TTS وائس ڈاؤن لوڈ کریں۔',
    'ne': 'तपाईंको फोनमा नेपाली आवाज (TTS Voice) स्थापना गरिएको छैन। कृपया सेटिङहरूबाट Google TTS आवाज डाउनलोड गर्नुहोस्।',
    'sa': 'भवतः दूरभाषे संस्कृतध्वनिः (TTS Voice) न संस्थापिता। कृपया विन्यासात् (Settings) Google TTS ध्वनिं डाउनलोड् कुर्वन्तु।',
    'kok': 'तुमच्या फोनांत कोंकणी आवाज (TTS Voice) इनस्टॉल ना. उपकार करून सेटिंगांतल्यान Google TTS व्हॉईस डाउनलोड करात.',
    'mai': 'अहाँक फोन मे मैथिली आवाज (TTS Voice) इन्स्टॉल नहि अछि। कृपया सेटिंग्स सँ Google TTS वॉइस डाउनलोड करू।',
    'doi': 'तुंदे फोन च डोगरी आवाज (TTS Voice) इन्स्टाल नेईं ऐ। कृपया सेटिंग्स चा Google TTS आवाज डाउनलोड करो।',
    'ks': 'تہنزس فونس منٛز چھنہ کشمیری آواز انسٹال۔ مہربٲنی کٔرتھ سیٹنگز منٛزٕ کٔریو آواز ڈاؤنلوڈ۔',
    'sd': 'توهان جي فون ۾ سنڌي آواز (TTS Voice) انسٽال ٿيل ناهي. مهرباني ڪري سيٽنگن مان وائس ڊائون لوڊ ڪريو.',
    'brx': 'नोंथांनि फोनाव बर\' राव (TTS Voice) इनस्टॉल गैया। अननानै सेटिंग्सनिफ्राय Google TTS राव डाउनलोड खालाम।',
    'mni': 'নহাক্কী ফোনদা মনিপুরী খোন্থাং (TTS Voice) ইনষ্টল তৌদে। চানবীদুনা সেতিংসতগী Google TTS খোন্থাং ডাউনলোড তৌবীয়ু।',
    'sat': 'ᱟᱢᱟᱜ ᱯᱷᱚᱱ ᱨᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱟᱲᱟᱝ (TTS Voice) ᱵᱟᱹᱱᱩᱜ-ᱟ᱾ ᱫᱟᱭᱟᱠᱟᱛᱮ ᱥᱮᱴᱤᱝ ᱠᱷᱚᱱ Google TTS ᱟᱲᱟᱝ ᱰᱟᱩᱱᱞᱳᱰ ᱢᱮ᱾',
    'en': 'Voice for this language is not installed on your phone. Please install or enable speech data in Android TTS settings.',
  };

  /// Resolves the BCP-47 locale code for a given ISO language code
  String resolveLocale(String langCode) {
    final clean = langCode.trim().toLowerCase();
    return bcp47LocaleMap[clean] ?? 'en-IN';
  }

  /// Get localized button label for listen
  String getListenLabel(String langCode) {
    final clean = langCode.trim().toLowerCase();
    return listenLabels[clean] ?? listenLabels['en']!;
  }

  /// Get localized button label for stop
  String getStopLabel(String langCode) {
    final clean = langCode.trim().toLowerCase();
    return stopLabels[clean] ?? stopLabels['en']!;
  }

  /// Get localized missing voice message
  String getMissingVoiceMessage(String langCode) {
    final clean = langCode.trim().toLowerCase();
    return missingVoiceNotices[clean] ?? missingVoiceNotices['en']!;
  }

  /// Enable mock mode for headless unit & widget tests
  @visibleForTesting
  void enableMockMode({bool enabled = true, Set<String>? availableLocales}) {
    _useMockMode = enabled;
    if (availableLocales != null) {
      _mockAvailableLocales.clear();
      _mockAvailableLocales.addAll(availableLocales);
    }
  }

  /// Reset mock mode and active state
  @visibleForTesting
  void resetMockMode() {
    _useMockMode = false;
    _state = AiTtsState.idle;
    _currentlySpeakingMessageId = null;
    _activeLocale = null;
    _lastErrorMessage = null;
  }

  /// Initialize the native FlutterTts engine
  Future<void> _initTts() async {
    if (_isInitialized) return;
    if (_useMockMode || _isTestEnv) {
      _isInitialized = true;
      return;
    }

    try {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() {
        _state = AiTtsState.speaking;
        notifyListeners();
      });

      _flutterTts!.setCompletionHandler(() {
        _state = AiTtsState.idle;
        _currentlySpeakingMessageId = null;
        _activeLocale = null;
        notifyListeners();
      });

      _flutterTts!.setCancelHandler(() {
        _state = AiTtsState.idle;
        _currentlySpeakingMessageId = null;
        _activeLocale = null;
        notifyListeners();
      });

      _flutterTts!.setErrorHandler((dynamic msg) {
        debugPrint('[AiChatTtsService] TTS Error: $msg');
        _state = AiTtsState.error;
        _lastErrorMessage = msg?.toString() ?? 'Audio error';
        _currentlySpeakingMessageId = null;
        _activeLocale = null;
        notifyListeners();
      });

      // Farmer-friendly speech parameters (calm, clear, audible)
      await _flutterTts!.setSpeechRate(0.48);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.setVolume(1.0);

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AiChatTtsService] Engine init fallback: $e');
      _isInitialized = true;
    }
  }

  /// Check whether the specific regional voice is installed and available on this device
  Future<bool> isVoiceAvailable(String langCode) async {
    final targetLocale = resolveLocale(langCode);

    if (_useMockMode || _isTestEnv) {
      return _mockAvailableLocales.contains(targetLocale);
    }

    await _initTts();
    if (_flutterTts == null) return false;

    try {
      final res = await _flutterTts!.isLanguageAvailable(targetLocale);
      if (res is bool) return res;
      if (res is int) return res == 1;
      if (res is String) return res.toLowerCase() == 'true';
      return false;
    } catch (e) {
      debugPrint('[AiChatTtsService] isLanguageAvailable check error: $e');
      return false;
    }
  }

  /// Speaks the complete AI answer in its native language.
  ///
  /// - Tapping an already speaking answer toggles it off (stops).
  /// - Tapping another answer immediately stops the previous and begins the new one.
  /// - If voice is missing, prevents wrong-language distortion and surfaces localized notice.
  Future<bool> speakAnswer({
    required String messageId,
    required String text,
    required String langCode,
    BuildContext? context,
  }) async {
    // 1. Toggle off if already speaking this exact message
    if (_currentlySpeakingMessageId == messageId &&
        (_state == AiTtsState.speaking || _state == AiTtsState.loading)) {
      await stop();
      return false;
    }

    // 2. Halt any existing audio immediately
    await stop();

    _currentlySpeakingMessageId = messageId;
    _state = AiTtsState.loading;
    _lastErrorMessage = null;
    notifyListeners();

    final targetLocale = resolveLocale(langCode);
    _activeLocale = targetLocale;

    // 3. Verify voice availability
    final voiceAvailable = await isVoiceAvailable(langCode);
    if (!voiceAvailable) {
      _state = AiTtsState.idle;
      _currentlySpeakingMessageId = null;
      _activeLocale = null;
      notifyListeners();

      if (context != null && context.mounted) {
        _showMissingVoiceNotice(context, langCode);
      }
      return false;
    }

    // Clean text: strip markdown syntax, formatting asterisks, and excessive URLs
    final cleanText = _sanitizeTextForSpeech(text);

    if (_useMockMode || _isTestEnv) {
      _state = AiTtsState.speaking;
      notifyListeners();
      return true;
    }

    await _initTts();

    try {
      if (_flutterTts != null) {
        await _flutterTts!.setLanguage(targetLocale);
        final result = await _flutterTts!.speak(cleanText);
        if (result == 1) {
          _state = AiTtsState.speaking;
          notifyListeners();
          return true;
        } else {
          _state = AiTtsState.idle;
          _currentlySpeakingMessageId = null;
          notifyListeners();
          return false;
        }
      } else {
        _state = AiTtsState.idle;
        _currentlySpeakingMessageId = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[AiChatTtsService] Speak error: $e');
      _state = AiTtsState.error;
      _lastErrorMessage = e.toString();
      _currentlySpeakingMessageId = null;
      notifyListeners();
      return false;
    }
  }

  /// Stops any currently playing speech session
  Future<void> stop() async {
    try {
      if (_flutterTts != null && !_useMockMode && !_isTestEnv) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      debugPrint('[AiChatTtsService] Stop error: $e');
    } finally {
      _state = AiTtsState.idle;
      _currentlySpeakingMessageId = null;
      _activeLocale = null;
      notifyListeners();
    }
  }

  /// Sanitizes raw advisory text into clear phonetics without markdown or raw artifacts
  String _sanitizeTextForSpeech(String text) {
    var cleaned = text;
    // Remove markdown headers (###)
    cleaned = cleaned.replaceAll(RegExp(r'#+\s*'), '');
    // Remove bold/italic asterisks (* and **)
    cleaned = cleaned.replaceAll(RegExp(r'\*+'), '');
    // Remove bullet dashes and symbols
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '');
    // Replace URL links with brief phrase or omit
    cleaned = cleaned.replaceAll(RegExp(r'https?://[^\s]+'), '');
    return cleaned.trim();
  }

  /// Displays localized advisory snackbar explaining device voice setup
  void _showMissingVoiceNotice(BuildContext context, String langCode) {
    final message = getMissingVoiceMessage(langCode);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12.5, height: 1.3),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF37474F),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
