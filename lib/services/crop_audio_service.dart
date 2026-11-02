import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/crop_master_entry.dart';

/// Audio Playback State for Crop TTS
enum CropAudioState { idle, loading, speaking, error }

/// Dedicated Crop Audio & Text-to-Speech (TTS) Service for KhetChacha.
/// Speaks localized crop names aloud in Gujarati, Hindi, English, and regional Indian languages.
/// Ensures single-session audio playback (tapping another crop stops previous immediately).
class CropAudioService extends ChangeNotifier {
  CropAudioService._internal();
  static final CropAudioService instance = CropAudioService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  String? _currentlySpeakingCropId;
  CropAudioState _state = CropAudioState.idle;
  String? _errorMessage;

  String? get currentlySpeakingCropId => _currentlySpeakingCropId;
  CropAudioState get state => _state;
  String? get errorMessage => _errorMessage;

  bool isCropSpeaking(String cropId) =>
      _currentlySpeakingCropId == cropId && _state == CropAudioState.speaking;

  bool isCropLoading(String cropId) =>
      _currentlySpeakingCropId == cropId && _state == CropAudioState.loading;

  /// Initializes the TTS engine with proper handlers
  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() {
        _state = CropAudioState.speaking;
        notifyListeners();
      });

      _flutterTts!.setCompletionHandler(() {
        _state = CropAudioState.idle;
        _currentlySpeakingCropId = null;
        notifyListeners();
      });

      _flutterTts!.setCancelHandler(() {
        _state = CropAudioState.idle;
        _currentlySpeakingCropId = null;
        notifyListeners();
      });

      _flutterTts!.setErrorHandler((dynamic msg) {
        debugPrint('[CropAudioService] TTS Error: $msg');
        _state = CropAudioState.error;
        _errorMessage = msg?.toString() ?? 'Audio error';
        _currentlySpeakingCropId = null;
        notifyListeners();
      });

      // Farmer-friendly speech parameters (calm, clear, audible)
      await _flutterTts!.setSpeechRate(0.48);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.setVolume(1.0);

      _isInitialized = true;
    } catch (e) {
      debugPrint(
        '[CropAudioService] Engine init notice (test or fallback): $e',
      );
      _isInitialized = true; // allow fallback simulation in test mode
    }
  }

  /// Resolve BCP-47 locale code for regional Indian languages
  String resolveLocale(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'gu-IN';
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'pa':
        return 'pa-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  /// Speaks the localized crop name aloud for the given crop in the active language.
  /// If the same crop is already playing, stops audio.
  /// If another crop is playing, stops previous audio and speaks new crop.
  Future<void> speakCrop({
    required CropMasterEntry crop,
    required String langCode,
  }) async {
    // 1. If currently speaking this same crop, toggle off (stop)
    if (_currentlySpeakingCropId == crop.cropId &&
        (_state == CropAudioState.speaking ||
            _state == CropAudioState.loading)) {
      await stop();
      return;
    }

    // 2. Stop any existing audio session
    await stop();

    _currentlySpeakingCropId = crop.cropId;
    _state = CropAudioState.loading;
    _errorMessage = null;
    notifyListeners();

    await _initTts();

    final targetLocale = resolveLocale(langCode);
    final textToSpeak = crop.getLocalizedName(langCode);

    try {
      if (_flutterTts != null) {
        // Set language
        try {
          await _flutterTts!.setLanguage(targetLocale);
        } catch (_) {
          // Fallback to English if regional voice is not installed on device
          await _flutterTts!.setLanguage('en-IN');
        }

        final result = await _flutterTts!.speak(textToSpeak);
        if (result == 1) {
          _state = CropAudioState.speaking;
          notifyListeners();
        } else {
          // If speak result was not immediately 1 (e.g. running in widget test environment)
          _state = CropAudioState.idle;
          _currentlySpeakingCropId = null;
          notifyListeners();
        }
      } else {
        _state = CropAudioState.idle;
        _currentlySpeakingCropId = null;
        notifyListeners();
      }
    } on MissingPluginException {
      // Graceful fallback for test runner / headless environments
      debugPrint('[CropAudioService] MissingPluginException in headless mode.');
      _state = CropAudioState.idle;
      _currentlySpeakingCropId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[CropAudioService] Speech failure: $e');
      _state = CropAudioState.error;
      _errorMessage = e.toString();
      _currentlySpeakingCropId = null;
      notifyListeners();
    }
  }

  /// Stops any currently playing speech session
  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      debugPrint('[CropAudioService] Stop error: $e');
    } finally {
      _state = CropAudioState.idle;
      _currentlySpeakingCropId = null;
      notifyListeners();
    }
  }
}
