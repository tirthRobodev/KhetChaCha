import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'unified_agri_ai_service.dart';

/// State of the voice assistant
enum VoiceAssistantState {
  idle,
  listening,
  processing,
  speaking,
  paused,
  error,
}

/// Dedicated Voice Assistant Audio Service for KhetChaCha.
/// Manages native Android STT (Speech-to-Text), live transcript streaming,
/// sound level monitoring for UI waveforms, Markdown sanitization, sentence chunking,
/// and full TTS playback controls (Play, Pause, Resume, Replay, Stop).
class VoiceAssistantService extends ChangeNotifier {
  VoiceAssistantService._internal();
  static final VoiceAssistantService instance =
      VoiceAssistantService._internal();

  final SpeechToText _speechToText = SpeechToText();
  FlutterTts? _flutterTts;

  bool _isSttInitialized = false;
  bool _isTtsInitialized = false;

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _liveTranscript = '';
  double _soundLevel = 0.0; // 0.0 to 1.0 for dynamic UI waves
  String? _errorMessage;

  // TTS chunking & playback management
  List<String> _ttsChunks = [];
  int _currentChunkIndex = 0;
  String _lastSpokenText = '';
  String _lastSpokenLangCode = 'gu';
  double _speechRate = 0.48; // Farmer-friendly, calm cadence

  VoiceAssistantState get state => _state;
  bool get isListening => _state == VoiceAssistantState.listening;
  bool get isSpeaking => _state == VoiceAssistantState.speaking;
  bool get isPaused => _state == VoiceAssistantState.paused;
  bool get isProcessing => _state == VoiceAssistantState.processing;
  String get liveTranscript => _liveTranscript;
  double get soundLevel => _soundLevel;
  String? get errorMessage => _errorMessage;
  double get speechRate => _speechRate;
  double get playbackProgress => _ttsChunks.isEmpty
      ? 0.0
      : (_currentChunkIndex / _ttsChunks.length).clamp(0.0, 1.0);

  // ===========================================================================
  // 1. INITIALIZATION & PERMISSIONS
  // ===========================================================================

  Future<bool> init() async {
    await _initTts();
    return _initStt();
  }

  Future<bool> _initStt() async {
    if (_isSttInitialized) return true;
    try {
      _isSttInitialized = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
    } catch (e) {
      debugPrint(
        '[VoiceAssistantService] STT init notice (fallback allowed): $e',
      );
      _isSttInitialized = false;
    }
    return _isSttInitialized;
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() {
        if (_state != VoiceAssistantState.speaking) {
          _state = VoiceAssistantState.speaking;
          notifyListeners();
        }
      });

      _flutterTts!.setCompletionHandler(() {
        _playNextChunk();
      });

      _flutterTts!.setCancelHandler(() {
        _state = VoiceAssistantState.idle;
        notifyListeners();
      });

      _flutterTts!.setErrorHandler((dynamic msg) {
        debugPrint('[VoiceAssistantService] TTS Error: $msg');
        _playNextChunk(); // Skip bad chunk gracefully
      });

      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.setVolume(1.0);

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[VoiceAssistantService] TTS init notice: $e');
      _isTtsInitialized = false;
    }
  }

  // ===========================================================================
  // 2. SPEECH-TO-TEXT (STT) RECORDING
  // ===========================================================================

  /// Starts listening to microphone in target language
  Future<bool> startListening({
    required String langCode,
    required void Function(String liveText) onLiveUpdate,
  }) async {
    // 1. Stop any currently active speech
    await stopSpeaking();

    // 2. Check & Request Microphone Permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _state = VoiceAssistantState.error;
      _errorMessage = 'Microphone permission is required for voice queries.';
      notifyListeners();
      return false;
    }

    // 3. Ensure STT is initialized
    final initialized = await _initStt();
    if (!initialized) {
      _state = VoiceAssistantState.error;
      _errorMessage =
          'Speech recognition service is unavailable on this device.';
      notifyListeners();
      return false;
    }

    _liveTranscript = '';
    _soundLevel = 0.0;
    _errorMessage = null;
    _state = VoiceAssistantState.listening;
    notifyListeners();

    final bcp47Locale = UnifiedAgriAiService.instance.resolveSpeechLocale(
      langCode,
    );
    final localeWithUnderscore = bcp47Locale.replaceAll('-', '_');

    try {
      final listenOptions = SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: localeWithUnderscore,
        cancelOnError: false,
        partialResults: true,
      );

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _liveTranscript = result.recognizedWords;
          onLiveUpdate(_liveTranscript);
          notifyListeners();
        },
        listenOptions: listenOptions,
        onSoundLevelChange: (double level) {
          // Normalize level (speech_to_text returns dB typically -10 to 10)
          final normalized = ((level + 10) / 20.0).clamp(0.05, 1.0);
          _soundLevel = normalized;
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      debugPrint('[VoiceAssistantService] Listen error: $e');
      _state = VoiceAssistantState.error;
      _errorMessage = 'Could not start microphone: $e';
      notifyListeners();
      return false;
    }
  }

  /// Manually stops microphone listening and returns final captured words
  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _soundLevel = 0.0;
    if (_state == VoiceAssistantState.listening) {
      _state = VoiceAssistantState.idle;
    }
    notifyListeners();
    return _liveTranscript;
  }

  /// Cancels listening and clears interim transcript
  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
    _liveTranscript = '';
    _soundLevel = 0.0;
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('[VoiceAssistantService] STT Error: ${error.errorMsg}');
    // 'error_speech_timeout' or 'error_no_match' is normal when farmer finishes speaking
    if (error.errorMsg != 'error_speech_timeout' &&
        error.errorMsg != 'error_no_match') {
      _errorMessage = error.errorMsg;
    }
    _soundLevel = 0.0;
    if (_state == VoiceAssistantState.listening) {
      _state = VoiceAssistantState.idle;
    }
    notifyListeners();
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceAssistantState.listening) {
        _state = VoiceAssistantState.idle;
      }
      _soundLevel = 0.0;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. TEXT-TO-SPEECH (TTS) PLAYBACK & CHUNKING
  // ===========================================================================

  /// Cleans markdown, chunks text, and plays sequentially through TTS
  Future<void> speak(String text, String langCode) async {
    await stopListening();
    await _initTts();

    _lastSpokenText = text;
    _lastSpokenLangCode = langCode;

    final sanitized = sanitizeMarkdownForSpeech(text);
    _ttsChunks = chunkTextForTts(sanitized);
    _currentChunkIndex = 0;

    if (_ttsChunks.isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    _state = VoiceAssistantState.speaking;
    notifyListeners();

    final locale = UnifiedAgriAiService.instance.resolveSpeechLocale(langCode);
    if (_flutterTts != null) {
      try {
        await _flutterTts!.setLanguage(locale);
      } catch (e) {
        debugPrint(
          '[VoiceAssistantService] Locale error, fallback to hi-IN: $e',
        );
        try {
          await _flutterTts!.setLanguage('hi-IN');
        } catch (_) {}
      }
    }

    _playCurrentChunk();
  }

  Future<void> _playCurrentChunk() async {
    if (_currentChunkIndex >= _ttsChunks.length) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    final chunk = _ttsChunks[_currentChunkIndex];
    if (_flutterTts != null) {
      try {
        await _flutterTts!.speak(chunk);
      } catch (e) {
        debugPrint('[VoiceAssistantService] Error speaking chunk: $e');
        _playNextChunk();
      }
    } else {
      // Test environment simulation
      _playNextChunk();
    }
  }

  void _playNextChunk() {
    _currentChunkIndex++;
    if (_currentChunkIndex < _ttsChunks.length &&
        _state == VoiceAssistantState.speaking) {
      _playCurrentChunk();
    } else {
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_flutterTts != null && _state == VoiceAssistantState.speaking) {
      await _flutterTts!.pause();
      _state = VoiceAssistantState.paused;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_state == VoiceAssistantState.paused) {
      _state = VoiceAssistantState.speaking;
      notifyListeners();
      _playCurrentChunk();
    }
  }

  Future<void> stopSpeaking() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
    _state = VoiceAssistantState.idle;
    _ttsChunks = [];
    _currentChunkIndex = 0;
    notifyListeners();
  }

  Future<void> replay() async {
    if (_lastSpokenText.isNotEmpty) {
      await speak(_lastSpokenText, _lastSpokenLangCode);
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.3, 1.0);
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(_speechRate);
    }
    notifyListeners();
  }

  void setProcessing(bool processing) {
    if (processing) {
      _state = VoiceAssistantState.processing;
    } else if (_state == VoiceAssistantState.processing) {
      _state = VoiceAssistantState.idle;
    }
    notifyListeners();
  }

  // ===========================================================================
  // 4. SANITIZER & CHUNKER UTILITIES
  // ===========================================================================

  /// Removes Markdown symbols (headers, bold, bullets, links) so speech is smooth
  static String sanitizeMarkdownForSpeech(String markdown) {
    var text = markdown;

    // Remove markdown links [title](url) -> title
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (m) => m[1] ?? '',
    );

    // Remove bold and italic markers: **, *, __, _
    text = text.replaceAll(RegExp(r'\*\*|\*|__|_'), '');

    // Remove header symbols: ###, ##, #
    text = text.replaceAll(RegExp(r'#+\s*'), '');

    // Replace bullet points with brief natural pauses
    text = text.replaceAll(RegExp(r'^[•\-\*]\s*', multiLine: true), '');

    // Clean up code markers and block quotes
    text = text.replaceAll('`', '');
    text = text.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // Replace multiple newlines or spaces with single clean space
    text = text.replaceAll(RegExp(r'\n+'), '. ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Splits long text into natural spoken sentence/clause chunks (<220 characters)
  static List<String> chunkTextForTts(String text, {int maxChunkLength = 220}) {
    final clean = text.trim();
    if (clean.isEmpty) return [];
    if (clean.length <= maxChunkLength) return [clean];

    final List<String> chunks = [];
    // Split primarily on sentence boundaries (. ? ! ।)
    final sentences = clean.split(RegExp(r'(?<=[.?!\।\n])\s+'));

    String current = '';
    for (final s in sentences) {
      final sentence = s.trim();
      if (sentence.isEmpty) continue;

      if ((current.length + sentence.length + 1) <= maxChunkLength) {
        current = current.isEmpty ? sentence : '$current $sentence';
      } else {
        if (current.isNotEmpty) {
          chunks.add(current);
        }
        if (sentence.length > maxChunkLength) {
          // Break large sentence by commas or clauses
          final parts = sentence.split(RegExp(r'(?<=[,;:])\s+'));
          String sub = '';
          for (final p in parts) {
            if ((sub.length + p.length + 1) <= maxChunkLength) {
              sub = sub.isEmpty ? p : '$sub $p';
            } else {
              if (sub.isNotEmpty) chunks.add(sub);
              sub = p;
            }
          }
          current = sub;
        } else {
          current = sentence;
        }
      }
    }

    if (current.isNotEmpty) {
      chunks.add(current);
    }

    return chunks;
  }
}
