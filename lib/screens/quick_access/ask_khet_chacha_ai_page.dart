import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../localization/language_data.dart';
import '../../models/ai_conversation_message.dart';
import '../../models/farmer_profile.dart';
import '../../services/conversation_history_service.dart';
import '../../services/language_service.dart';
import '../../services/permission_service.dart';
import '../../services/unified_agri_ai_service.dart';
import '../../services/voice_assistant_service.dart';
import '../../widgets/khetchacha_logo.dart';
import '../ai/image_ai_diagnosis_page.dart';
import '../ai/voice_assistant_page.dart';
import '../expert/ask_expert_page.dart';

/// Full-Screen AI Assistant Farming Chatbot (Bottom Navigation Destination 3).
/// Includes shared conversation history with Voice Assistant, real-time agronomic guidance,
/// language selector, 1-click TTS audio listening on replies, microphone shortcut,
/// image attachment shortcut, and expert escalation.
class AskKhetChachaAiPage extends StatefulWidget {
  final FarmerProfile profile;

  const AskKhetChachaAiPage({super.key, required this.profile});

  @override
  State<AskKhetChachaAiPage> createState() => _AskKhetChachaAiPageState();
}

class _AskKhetChachaAiPageState extends State<AskKhetChachaAiPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initHistory();
    VoiceAssistantService.instance.addListener(_onVoiceServiceStateChanged);
  }

  void _onVoiceServiceStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initHistory() async {
    await ConversationHistoryService.instance.init();
    if (ConversationHistoryService.instance.messages.isEmpty) {
      final langCode =
          LanguageService.instance.currentLanguage.locale.languageCode;
      final welcome = _getWelcomeMessage(langCode, widget.profile.fullName);
      final welcomeMsg = AiConversationMessage(
        id: 'msg_welcome',
        sender: 'assistant',
        text: welcome,
        inputMode: 'text',
        languageCode: langCode,
        timestamp: DateTime.now(),
      );
      await ConversationHistoryService.instance.addMessage(welcomeMsg);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    VoiceAssistantService.instance.removeListener(_onVoiceServiceStateChanged);
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    _msgController.clear();

    final userMsg = AiConversationMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: text,
      inputMode: 'text',
      languageCode: langCode,
      timestamp: DateTime.now(),
    );

    await ConversationHistoryService.instance.addMessage(userMsg);
    _scrollToBottom();

    setState(() => _isLoading = true);

    try {
      final aiMsg = await UnifiedAgriAiService.instance.processQuery(
        query: text,
        profile: widget.profile,
        inputMode: 'text',
        preferredLanguageCode: langCode,
      );

      await ConversationHistoryService.instance.addMessage(aiMsg);
    } catch (e) {
      debugPrint('[AskKhetChachaAiPage] Query error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                        setState(() {});
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
    final messages = ConversationHistoryService.instance.messages;

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
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length && _isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'KhetChaCha AI is analyzing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final m = messages[i];
                final isUser = m.isUser;
                final voiceService = VoiceAssistantService.instance;
                final isThisSpeaking = voiceService.isSpeaking;

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
                      color: isUser ? const Color(0xFF1B5E20) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
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
                        if (m.isVoice && isUser) ...[
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 14,
                                color: Color(0xFFFFD54F),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Voice Query',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          m.text,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isUser
                                ? Colors.white
                                : const Color(0xFF212121),
                            height: 1.4,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // TTS Listen Button
                              InkWell(
                                onTap: () {
                                  if (isThisSpeaking) {
                                    voiceService.stopSpeaking();
                                  } else {
                                    voiceService.speak(m.text, m.languageCode);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isThisSpeaking
                                            ? Icons.stop_rounded
                                            : Icons.volume_up_rounded,
                                        size: 13,
                                        color: const Color(0xFFE65100),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isThisSpeaking
                                            ? 'Stop Audio'
                                            : 'Listen / સાંભળો',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFFE65100),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Ask Expert 2nd Opinion
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
                                    vertical: 3,
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
                                        '2nd Opinion',
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
              child: Row(
                children: [
                  // Image attachment shortcut
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                    tooltip: 'Diagnose Crop Photo with Image AI',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageAiDiagnosisPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),

                  // Microphone shortcut to full Voice Assistant
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
                      decoration: const InputDecoration(
                        hintText: 'Type your farming question...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
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
