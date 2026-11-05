import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/app_localizations.dart';
import '../../localization/language_data.dart';
import '../../models/ai_chat_models.dart';
import '../../models/ai_conversation_message.dart';
import '../../services/conversation_history_service.dart';
import '../../models/farmer_profile.dart';
import '../../services/ai_chat_tts_service.dart';
import '../../services/language_detection_helper.dart';
import '../../services/language_service.dart';
import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import '../../services/universal_agri_ai_engine.dart';
import '../../widgets/khetchacha_logo.dart';
import '../ai/image_ai_diagnosis_page.dart';
import '../ai/voice_assistant_page.dart';
import '../expert/ask_expert_page.dart';

/// Internal data representation of a chat message bubble.
class _ChatMessageItem {
  final String id;
  final String sender; // 'user' or 'bot'
  final String text;
  final String? languageCode;
  final String? detailedExplanation;
  final List<String> actionSteps;
  final List<String> safetyPrecautions;
  final List<AiEvidenceSource> sources;
  final bool requiresPhoto;
  final bool isError;
  final bool isLoading;
  final String? failedQuestion;
  bool isExpanded;

  _ChatMessageItem({
    required this.id,
    required this.sender,
    required this.text,
    this.languageCode,
    this.detailedExplanation,
    this.actionSteps = const [],
    this.safetyPrecautions = const [],
    this.sources = const [],
    this.requiresPhoto = false,
    this.isError = false,
    this.isLoading = false,
    this.failedQuestion,
  }) : isExpanded = false;
}

/// Full-Screen AI Assistant Farming Chatbot (Bottom Navigation Destination 3).
///
/// Fully integrated with the Python FastAPI Agriculture AI Engine:
/// - Sends user question, language, crop context, and location (when permitted)
/// - Renders short answer, detailed explanation, action steps, safety precautions,
///   citations, and photo diagnosis prompts
/// - Preserves 100% of existing UI, language switcher, mic and camera shortcuts
class AskKhetChachaAiPage extends StatefulWidget {
  final FarmerProfile profile;

  const AskKhetChachaAiPage({super.key, required this.profile});

  @override
  State<AskKhetChachaAiPage> createState() => _AskKhetChachaAiPageState();
}

class _AskKhetChachaAiPageState extends State<AskKhetChachaAiPage>
    with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessageItem> _messages = [];
  bool _isSending = false;
  late final String _conversationId;
  String? _attachedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AiChatTtsService.instance.addListener(_onTtsStateChanged);
    _conversationId = 'session-${DateTime.now().millisecondsSinceEpoch}';
    _initWelcome();
  }

  void _onTtsStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      AiChatTtsService.instance.stop();
    }
  }

  void _initWelcome() {
    final langCode = LanguageService.instance.currentLanguage.code;
    _messages.clear();
    _messages.add(
      _ChatMessageItem(
        id: 'msg-welcome-0',
        sender: 'bot',
        languageCode: langCode,
        text: _getWelcomeMessage(langCode, widget.profile.fullName),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AiChatTtsService.instance.removeListener(_onTtsStateChanged);
    AiChatTtsService.instance.stop();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getWelcomeMessage(String langCode, String name) {
    final farmerName = name.isNotEmpty ? name : 'કૃષિ મિત્ર';
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'નમસ્તે $farmerName! હું ખેતચાચા AI કૃષિ સલાહકાર છું. પાક રક્ષણ, ખાતર, દવાઓ કે સિંચાઈ વિશે કોઈપણ પ્રશ્ન પૂછો.';
      case 'pa':
        return 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ $farmerName ਜੀ! ਮੈਂ ਤੁਹਾਡਾ ਖੇਤਚਾਚਾ AI ਖੇਤੀ ਸਹਾਇਕ ਹਾਂ। ਫ਼ਸਲਾਂ, ਕੀੜੇ-ਮਕੌੜਿਆਂ ਜਾਂ ਖਾਦਾਂ ਬਾਰੇ ਸਵਾਲ ਪੁੱਛੋ।';
      case 'hi':
        return 'नमस्ते $farmerName! मैं खेतचाचा AI कृषि सहायक हूँ। फसलों की बीमारी, मौसम, खाद या कीटनाशकों से संबंधित कोई भी सवाल पूछें।';
      case 'mr':
        return 'नमस्कार $farmerName! मी तुमचा खेतचाचा AI शेती मित्र आहे. पिकांवरील रोग, खते किंवा हवामानाबद्दल काहीही विचारा.';
      default:
        return 'Hello $farmerName! I am your KhetChaCha AI Farming Assistant. Ask me anything about crop diseases, fertilizers, weather advisory, or market prices.';
    }
  }

  Future<void> _sendMessage({String? customText, bool isRetry = false}) async {
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty || _isSending) return;

    final activeAppLang = LanguageService.instance.currentLanguage.code;
    // Auto-detect question language or fall back to selected app language
    final detectedLang = LanguageDetectionHelper.detectLanguage(
      text,
      fallbackCode: activeAppLang,
    );

    final userMsgId = 'msg-user-${DateTime.now().millisecondsSinceEpoch}';
    final loadingMsgId = 'msg-loading-${DateTime.now().millisecondsSinceEpoch}';

    String loadingText;
    switch (detectedLang) {
      case 'gu':
        loadingText = 'ખેતચાચા AI કૃષિ સલાહ ચકાસી રહ્યા છે...';
        break;
      case 'pa':
        loadingText = 'ਖੇਤਚਾਚਾ AI ਖੇਤੀ ਸਲਾਹ ਤਿਆਰ ਕਰ ਰਹੇ ਹਨ...';
        break;
      case 'hi':
        loadingText = 'खेतचाचा AI कृषि सलाह तैयार कर रहे हैं...';
        break;
      case 'mr':
        loadingText = 'ખેતચાચા AI કૃષિ સલાહ તૈયાર કરી રહ્યા છે...';
        break;
      default:
        loadingText =
            'KhetChaCha AI is preparing your agricultural advisory...';
    }

    setState(() {
      _isSending = true;
      if (!isRetry) {
        _messages.add(
          _ChatMessageItem(
            id: userMsgId,
            sender: 'user',
            text: text,
            languageCode: detectedLang,
          ),
        );
        ConversationHistoryService.instance.addMessage(
          AiConversationMessage(
            id: userMsgId,
            sender: 'user',
            text: text,
            inputMode: 'text',
            timestamp: DateTime.now(),
            languageCode: detectedLang,
          ),
        );
      }
      _messages.add(
        _ChatMessageItem(
          id: loadingMsgId,
          sender: 'bot',
          text: loadingText,
          languageCode: detectedLang,
          isLoading: true,
        ),
      );
      if (customText == null) {
        _msgController.clear();
      }
    });

    _scrollToBottom();

    try {
      // 1. Resolve Location only if permission is granted
      FarmerLocationPayload? locPayload;
      final isLocGranted =
          await PermissionService.instance.checkStatus(
            KhetPermissionType.location,
          ) ==
          KhetPermissionState.granted;
      final cachedLoc = LocationService.instance.lastKnownLocation;

      if (isLocGranted && cachedLoc != null) {
        locPayload = FarmerLocationPayload(
          village: cachedLoc.village.isNotEmpty
              ? cachedLoc.village
              : widget.profile.village,
          taluka: cachedLoc.taluka.isNotEmpty
              ? cachedLoc.taluka
              : widget.profile.taluka,
          district: cachedLoc.district.isNotEmpty
              ? cachedLoc.district
              : widget.profile.effectiveDistrict,
          state: cachedLoc.state.isNotEmpty
              ? cachedLoc.state
              : widget.profile.effectiveState,
          latitude: cachedLoc.latitude,
          longitude: cachedLoc.longitude,
        );
      } else {
        locPayload = FarmerLocationPayload(
          village: widget.profile.village.isNotEmpty
              ? widget.profile.village
              : null,
          taluka: widget.profile.taluka.isNotEmpty
              ? widget.profile.taluka
              : null,
          district: widget.profile.effectiveDistrict.isNotEmpty
              ? widget.profile.effectiveDistrict
              : null,
          state: widget.profile.effectiveState.isNotEmpty
              ? widget.profile.effectiveState
              : null,
        );
      }

      // 2. Crop Context
      final crop = widget.profile.effectiveProducts.isNotEmpty
          ? widget.profile.effectiveProducts.first
          : (widget.profile.crops.isNotEmpty
                ? widget.profile.crops.first
                : null);

      // 3. Land Size
      double? landSizeVal;
      final parsedLand = double.tryParse(
        widget.profile.landSize.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      if (parsedLand != null) landSizeVal = parsedLand;

      // 4. Image Attachment (if farmer attached plant photo)
      String? imageBase64;
      String? imageMimeType;
      if (_attachedImagePath != null && _attachedImagePath!.isNotEmpty) {
        try {
          Uint8List? bytes;
          if (_attachedImagePath!.startsWith('assets/')) {
            final data = await rootBundle.load(_attachedImagePath!);
            bytes = data.buffer.asUint8List();
          } else {
            final f = File(_attachedImagePath!);
            if (await f.exists()) {
              bytes = await f.readAsBytes();
            }
          }
          if (bytes != null && bytes.isNotEmpty) {
            imageBase64 = base64Encode(bytes);
            imageMimeType = _attachedImagePath!.endsWith('.png') ? 'image/png' : 'image/jpeg';
          }
        } catch (e) {
          debugPrint('Error preparing image bytes: $e');
        }
      }

      final request = FarmerChatApiRequest(
        question: text,
        language: detectedLang,
        currentCrop: crop,
        soilType: widget.profile.soilType.isNotEmpty
            ? widget.profile.soilType
            : null,
        landSize: landSizeVal,
        landUnit: widget.profile.landUnit.isNotEmpty
            ? widget.profile.landUnit
            : 'Bigha',
        location: locPayload,
        conversationId: _conversationId,
        imageBase64: imageBase64,
        imageMimeType: imageMimeType,
      );

      final response = await UniversalAgriAiEngine.instance.processChatQuery(
        request: request,
        profile: widget.profile,
      );

      if (!mounted) return;

      final botMsgId = 'msg-bot-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(
          _ChatMessageItem(
            id: botMsgId,
            sender: 'bot',
            text: response.answer,
            languageCode: response.language.isNotEmpty
                ? response.language
                : detectedLang,
            detailedExplanation: response.detailedExplanation.isNotEmpty
                ? response.detailedExplanation
                : null,
            actionSteps: response.actionSteps,
            safetyPrecautions: response.safetyPrecautions,
            sources: response.sources,
            requiresPhoto: response.requiresPhoto,
            isError: response.isError,
            failedQuestion: response.isError ? text : null,
          ),
        );
        _attachedImagePath = null;
      });

      if (!response.isError) {
        ConversationHistoryService.instance.addMessage(
          AiConversationMessage(
            id: botMsgId,
            sender: 'assistant',
            text: response.answer,
            inputMode: 'text',
            timestamp: DateTime.now(),
            languageCode: response.language.isNotEmpty
                ? response.language
                : detectedLang,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsgId = 'msg-err-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(
          _ChatMessageItem(
            id: errorMsgId,
            sender: 'bot',
            text: detectedLang == 'gu'
                ? 'સર્વર સાથે સંપર્ક થઈ શક્યો નથી. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો અથવા કિસાન હેલ્પલાઇન (1800-180-1551) નો સંપર્ક કરો.'
                : (detectedLang == 'hi'
                      ? 'सर्वर से संपर्क नहीं हो सका। कृपया पुनः प्रयास करें या किसान हेल्पलाइन (1800-180-1551) पर संपर्क करें।'
                      : (detectedLang == 'pa'
                            ? 'ਸਰਵਰ ਨਾਲ ਸੰਪਰਕ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ ਜਾਂ ਕਿਸਾਨ ਹੈਲਪਲਾਈਨ (1800-180-1551) ਤੇ ਸੰਪਰਕ ਕਰੋ।'
                            : 'Unable to connect to the agricultural AI server. Please try again or contact the Kisan Helpline (1800-180-1551).')),
            languageCode: detectedLang,
            isError: true,
            failedQuestion: text,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickSampleSpecimen() async {
    final chosenPath = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          {'title': 'Cotton Pink Bollworm', 'desc': 'કપાસ - ગુલાબી ઈયળ', 'path': 'assets/images/crops/cotton.png'},
          {'title': 'Paddy Leaf Blast', 'desc': 'ડાંગર - પાનનો કરપો', 'path': 'assets/images/crops/paddy.png'},
          {'title': 'Wheat Yellow Rust', 'desc': 'ઘઉં - પીળો ગેરુ', 'path': 'assets/images/crops/wheat.png'},
          {'title': 'Tomato Early Blight', 'desc': 'ટામેટા - સુકારો', 'path': 'assets/images/crops/tomato.png'},
        ];

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crop Diagnosis Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text(
                          'Full Scanner',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ImageAiDiagnosisPage(
                                profile: widget.profile,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a plant photo to diagnose symptoms in this chat conversation:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...options.map((opt) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          opt['path']!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Color(0xFF1B5E20),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        opt['title']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        opt['desc']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.add_photo_alternate,
                        color: Color(0xFF1B5E20),
                        size: 20,
                      ),
                      onTap: () => Navigator.pop(ctx, opt['path']),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosenPath != null && mounted) {
      setState(() {
        _attachedImagePath = chosenPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached ${chosenPath.split('/').last} for diagnosis.'),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _openLanguagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select AI Assistant Language',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageData.allLanguages.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final l = LanguageData.allLanguages[i];
                    final isCur =
                        LanguageService.instance.currentLanguage.code == l.code;
                    return ListTile(
                      title: Text(
                        l.nativeName,
                        style: TextStyle(
                          fontWeight: isCur
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(l.englishName),
                      trailing: isCur
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF1B5E20),
                            )
                          : null,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await LanguageService.instance.setLanguage(l);
                        if (!mounted) return;
                        setState(() {
                          if (_messages.length <= 1) {
                            _initWelcome();
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final activeLang = LanguageService.instance.currentLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            KhetChachaLogo.mark(size: 26),
            const SizedBox(width: 8),
            Text(
              loc.askKhetChachaAiTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          InkWell(
            onTap: _openLanguagePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 14,
                    color: Color(0xFFFFD54F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeLang.nativeName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expert Assistance Shortcut
          IconButton(
            icon: const Icon(Icons.school_outlined, color: Colors.white),
            tooltip: 'Consult Human Agriculture Expert',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AskExpertPage(profile: widget.profile),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Banner with shortcuts to Image AI and Expert
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF1B5E20),
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'AI Smart Assistant • Ask in text or tap mic for voice',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AskExpertPage(profile: widget.profile),
                      ),
                    );
                  },
                  child: const Text(
                    'Ask Expert →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.sender == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF1B5E20)
                          : (m.isError
                                ? const Color(0xFFFFF3E0)
                                : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: m.isError
                          ? Border.all(color: const Color(0xFFFFB74D))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main text / spinner
                        if (m.isLoading)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                m.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            m.text,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isUser
                                  ? Colors.white
                                  : (m.isError
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFF212121)),
                              height: 1.4,
                              fontWeight: isUser
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),

                        // Speaker Button - directly below every AI answer
                        if (!isUser &&
                            !m.isLoading &&
                            !m.isError &&
                            m.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (ctx) {
                              final isSpeaking = AiChatTtsService.instance
                                  .isMessageSpeaking(m.id);
                              final isTtsLoading = AiChatTtsService.instance
                                  .isMessageLoading(m.id);
                              final lang = m.languageCode ?? 'gu';
                              final buttonLabel = isSpeaking
                                  ? AiChatTtsService.instance.getStopLabel(lang)
                                  : AiChatTtsService.instance.getListenLabel(
                                      lang,
                                    );

                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  final fullSpeech = m.actionSteps.isNotEmpty
                                      ? '${m.text}\n${m.actionSteps.join('. ')}'
                                      : m.text;
                                  AiChatTtsService.instance.speakAnswer(
                                    messageId: m.id,
                                    text: fullSpeech,
                                    langCode: lang,
                                    context: ctx,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSpeaking
                                        ? const Color(0xFFFFEBEE)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSpeaking
                                          ? const Color(0xFFEF5350)
                                          : const Color(0xFFA5D6A7),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isTtsLoading)
                                        const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        )
                                      else
                                        Icon(
                                          isSpeaking
                                              ? Icons.stop_circle_rounded
                                              : Icons.volume_up_rounded,
                                          size: 16,
                                          color: isSpeaking
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFF1B5E20),
                                        ),
                                      const SizedBox(width: 5),
                                      Text(
                                        buttonLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSpeaking
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        // Retry Option - if request failed
                        if (m.isError && m.failedQuestion != null) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isSending
                                ? null
                                : () {
                                    final retryQuestion = m.failedQuestion!;
                                    setState(() {
                                      _messages.remove(m);
                                    });
                                    _sendMessage(
                                      customText: retryQuestion,
                                      isRetry: true,
                                    );
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 14,
                                    color: Color(0xFFE65100),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ફરી પ્રયાસ કરો (Retry)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Action steps
                        if (!isUser && m.actionSteps.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.checklist_rounded,
                                      size: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'તાત્કાલિક પગલાં (Action Steps):',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                for (
                                  int sIdx = 0;
                                  sIdx < m.actionSteps.length;
                                  sIdx++
                                )
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${sIdx + 1}. ',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            m.actionSteps[sIdx],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF333333),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Safety Precautions
                        if (!isUser && m.safetyPrecautions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFECB3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: Color(0xFFE65100),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    m.safetyPrecautions.join(' • '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF795548),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Expandable Detailed Explanation
                        if (!isUser && m.detailedExplanation != null) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                m.isExpanded = !m.isExpanded;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m.isExpanded
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: const Color(0xFF1B5E20),
                                ),
                                Text(
                                  m.isExpanded
                                      ? 'ઓછી વિગત (Hide details)'
                                      : 'વિગતવાર માહિતી (Detailed Info)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (m.isExpanded) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m.detailedExplanation!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF333333),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],

                        // Photo Upload Request Button
                        if (!isUser && m.requiresPhoto) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'પાકનો ફોટો પાડી તપાસો (Photo Diagnosis)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ImageAiDiagnosisPage(
                                      profile: widget.profile,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Sources / Citations & Expert 2nd Opinion
                        if (!isUser && !m.isLoading) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AskExpertPage(
                                        profile: widget.profile,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.support_agent_rounded,
                                        size: 12,
                                        color: Color(0xFF1B5E20),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ask Expert for 2nd Opinion',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF1B5E20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (m.sources.isNotEmpty) ...[
                                const Spacer(),
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 11,
                                  color: Color(0xFF388E3C),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'ICAR/KVK Verified',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Bar with Microphone and Image Attachment Shortcuts
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_attachedImagePath != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6, left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1B5E20), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, size: 14, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 4),
                          Text(
                            'Photo attached: ${_attachedImagePath!.split('/').last}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _attachedImagePath = null),
                            child: const Icon(Icons.close, size: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // Image attachment shortcut
                      IconButton(
                        icon: Icon(
                          _attachedImagePath != null
                              ? Icons.check_circle
                              : Icons.add_photo_alternate_outlined,
                          color: const Color(0xFF1B5E20),
                        ),
                        tooltip: 'Attach Crop Photo for Diagnosis',
                        onPressed: _isSending ? null : _pickSampleSpecimen,
                      ),

                  // Microphone shortcut
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: Color(0xFFE65100),
                    ),
                    tooltip: 'Speak Question by Voice',
                    onPressed: () async {
                      await PermissionService.instance.ensurePermission(
                        context,
                        type: KhetPermissionType.microphone,
                        featureName: 'Voice AI Assistant',
                        reason: 'Microphone access is needed so you can ask farming questions by voice in your language.',
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VoiceAssistantPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),

                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      enabled: !_isSending,
                      decoration: const InputDecoration(
                        hintText: 'Type your farming question...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: _isSending ? null : (_) => _sendMessage(),
                    ),
                  ),

                  // Send button (locked & debounced during in-flight requests)
                  Container(
                    decoration: BoxDecoration(
                      color: _isSending
                          ? const Color(0xFFB0BEC5)
                          : const Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: _isSending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
