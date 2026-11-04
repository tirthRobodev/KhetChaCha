import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_chat_models.dart';

/// Reusable Mobile API Client connecting Flutter to the Python FastAPI Agriculture AI Engine.
///
/// Features:
/// - Environment-aware base URL (Android Emulator 10.0.2.2, Localhost, or Production)
/// - Configurable read & connection timeouts
/// - Dependency injection of `http.Client` for testing
/// - Explicit handling of HTTP 422, 429, 500 and network disconnects
/// - Zero hardcoded secrets (API keys remain strictly server-side)
class AiChatApiService {
  AiChatApiService._internal();
  static final AiChatApiService instance = AiChatApiService._internal();

  static const String _prefKeyBaseUrl = 'khetchacha_ai_api_base_url';

  // Environment Defaults
  static const String defaultPhysicalDevBaseUrl = 'http://10.180.217.194:8000';
  static const String defaultEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String defaultLocalhostBaseUrl = 'http://localhost:8000';
  static const String defaultProductionBaseUrl = 'https://api.khetchacha.com';

  String? _customBaseUrl;
  http.Client _client = http.Client();
  bool isPhysicalAndroidDevice = true;
  int _requestIdCounter = 0;

  Duration connectionTimeout = const Duration(seconds: 15);
  Duration responseTimeout = const Duration(seconds: 45);

  /// Inject mock or custom HTTP client for unit tests.
  void setHttpClientForTesting(http.Client client) {
    _client = client;
  }

  /// Toggle between physical Android device and emulator URL resolution.
  void setPhysicalAndroidDevice(bool isPhysical) {
    isPhysicalAndroidDevice = isPhysical;
  }

  /// Sets custom API base URL at runtime and persists to SharedPreferences.
  Future<void> setBaseUrl(String url) async {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBaseUrl, _customBaseUrl!);
    } catch (_) {}
  }

  /// Resolves effective base URL based on platform and custom overrides.
  Future<String> getBaseUrl() async {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const envUrl = String.fromEnvironment('AI_API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyBaseUrl);
      if (saved != null && saved.isNotEmpty) {
        _customBaseUrl = saved;
        return _customBaseUrl!;
      }
    } catch (_) {}

    if (kIsWeb) {
      return defaultLocalhostBaseUrl;
    } else if (Platform.isAndroid) {
      return isPhysicalAndroidDevice ? defaultPhysicalDevBaseUrl : defaultEmulatorBaseUrl;
    } else {
      return defaultLocalhostBaseUrl;
    }
  }

  /// Checks backend health and Gemini availability via `GET /health`.
  Future<bool> checkHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/health');
      debugPrint('[AiChatApiService] [HEALTH_CHECK] Probing $uri');
      final res = await _client.get(uri).timeout(connectionTimeout);
      stopwatch.stop();
      debugPrint('[AiChatApiService] [HEALTH_RES] Status: ${res.statusCode} in ${stopwatch.elapsedMilliseconds}ms');
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      stopwatch.stop();
      debugPrint('[AiChatApiService] [HEALTH_ERR] Failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      return false;
    }
  }

  /// Submits farmer query to Python FastAPI AI text intelligence endpoint (`POST /api/v1/chat`).
  Future<FarmerChatApiResponse> sendFarmerQuery(FarmerChatApiRequest request) async {
    final lang = request.language;
    final reqId = ++_requestIdCounter;
    final stopwatch = Stopwatch()..start();

    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/v1/chat');

      debugPrint(
        '[AiChatApiService] [REQ #$reqId] Sending POST to $uri '
        '(qLen: ${request.question.length}, lang: ${request.language}, crop: ${request.currentCrop})',
      );

      final bodyJson = json.encode(request.toJson());

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: bodyJson,
          )
          .timeout(responseTimeout);

      stopwatch.stop();
      debugPrint(
        '[AiChatApiService] [RES #$reqId] Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms '
        '(bodyBytes: ${response.bodyBytes.length})',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return FarmerChatApiResponse.fromJson(decoded);
        }
        return FarmerChatApiResponse.error(
          userFriendlyMessage: _getLocalizedErrorMessage('invalid_json', lang),
          language: lang,
          rawError: 'Expected JSON object but received ${decoded.runtimeType}',
        );
      } else if (response.statusCode == 422) {
        // Validation Error
        return FarmerChatApiResponse.error(
          userFriendlyMessage: _getLocalizedErrorMessage('validation_error', lang),
          language: lang,
          rawError: 'HTTP 422 Unprocessable Entity: ${response.body}',
        );
      } else if (response.statusCode == 429) {
        // Rate Limit / Quota Exceeded
        return FarmerChatApiResponse.error(
          userFriendlyMessage: _getLocalizedErrorMessage('quota_limit', lang),
          language: lang,
          rawError: 'HTTP 429 Rate Limit Exceeded',
        );
      } else {
        // HTTP 500 or other server errors
        return FarmerChatApiResponse.error(
          userFriendlyMessage: _getLocalizedErrorMessage('server_error', lang),
          language: lang,
          rawError: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('[AiChatApiService] [ERR #$reqId] SocketException after ${stopwatch.elapsedMilliseconds}ms: $e');
      return FarmerChatApiResponse.error(
        userFriendlyMessage: _getLocalizedErrorMessage('network_error', lang),
        language: lang,
        rawError: 'SocketException: $e',
      );
    } on TimeoutException catch (e) {
      stopwatch.stop();
      debugPrint('[AiChatApiService] [ERR #$reqId] TimeoutException after ${stopwatch.elapsedMilliseconds}ms: $e');
      return FarmerChatApiResponse.error(
        userFriendlyMessage: _getLocalizedErrorMessage('timeout_error', lang),
        language: lang,
        rawError: 'TimeoutException: $e',
      );
    } on FormatException catch (e) {
      stopwatch.stop();
      debugPrint('[AiChatApiService] [ERR #$reqId] FormatException after ${stopwatch.elapsedMilliseconds}ms: $e');
      return FarmerChatApiResponse.error(
        userFriendlyMessage: _getLocalizedErrorMessage('invalid_json', lang),
        language: lang,
        rawError: 'FormatException: $e',
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[AiChatApiService] [ERR #$reqId] Unexpected error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return FarmerChatApiResponse.error(
        userFriendlyMessage: _getLocalizedErrorMessage('unknown_error', lang),
        language: lang,
        rawError: e.toString(),
      );
    }
  }

  String _getLocalizedErrorMessage(String errorType, String langCode) {
    final isGu = langCode == 'gu';
    final isHi = langCode == 'hi';

    switch (errorType) {
      case 'network_error':
        if (isGu) {
          return 'સર્વર સાથે સંપર્ક થઈ શક્યો નથી. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો અથવા કિસાન હેલ્પલાઇન (1800-180-1551) નો સંપર્ક કરો.';
        } else if (isHi) {
          return 'सर्वर से संपर्क नहीं हो सका। कृपया अपना इंटरनेट कनेक्शन जांचें या किसान हेल्पलाइन (1800-180-1551) पर संपर्क करें।';
        } else {
          return 'Unable to connect to the agricultural AI server. Please check your internet connection or call the Kisan Helpline (1800-180-1551).';
        }

      case 'timeout_error':
        if (isGu) {
          return 'કૃષિ સલાહકાર સર્વર તરફથી જવાબ મળવામાં વધુ સમય લાગ્યો. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો.';
        } else if (isHi) {
          return 'कृषि सलाहकार सर्वर से प्रतिक्रिया मिलने में अधिक समय लगा। कृपया थोड़ी देर बाद पुनः प्रयास करें।';
        } else {
          return 'The agricultural AI server took too long to respond. Please try again in a few moments.';
        }

      case 'quota_limit':
        if (isGu) {
          return 'હાલમાં કૃષિ AI સર્વર પર ઘણો ટ્રાફિક છે. ચોક્કસ સલાહ માટે કૃપા કરીને સ્થાનિક KVK અથવા ટોલ-ફ્રી નંબર (1800-180-1551) નો સંપર્ક કરો.';
        } else if (isHi) {
          return 'इस समय कृषि AI सर्वर पर अधिक लोड है। तत्काल सहायता हेतु नजदीकी KVK या किसान कॉल सेंटर (1800-180-1551) से संपर्क करें।';
        } else {
          return 'The AI server is experiencing high traffic. For urgent crop queries, contact your nearest Krishi Vigyan Kendra (KVK) or call Toll-Free 1800-180-1551.';
        }

      case 'validation_error':
        if (isGu) {
          return 'તમારા પ્રશ્નમાં જરૂરી વિગતો ખૂટે છે. કૃપા કરીને પાકનું નામ અને સમસ્યા સ્પષ્ટ લખીને મોકલો.';
        } else if (isHi) {
          return 'आपके प्रश्न में कुछ जानकारी अधूरी है। कृपया फसल का नाम और समस्या स्पष्ट रूप से लिखकर भेजें।';
        } else {
          return 'Your query was incomplete. Please mention the crop name and clear symptoms.';
        }

      case 'invalid_json':
      case 'server_error':
      default:
        if (isGu) {
          return 'કૃષિ સેવા દરમિયાન ક્ષતિ સર્જાઈ છે. અયોગ્ય દવાનો ઉપયોગ ટાળો અને સ્થાનિક કૃષિ અધિકારીની સલાહ લો.';
        } else if (isHi) {
          return 'कृषि सेवा में अस्थाई त्रुटि आई है। बिना पुष्टि के कीटनाशक का छिड़काव न करें और विशेषज्ञ की सलाह लें।';
        } else {
          return 'An error occurred while generating agricultural advisory. Please consult your local KVK agronomist before applying any agrochemical.';
        }
    }
  }
}

