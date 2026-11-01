import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../localization/language_data.dart';
import '../../models/farmer_profile.dart';
import '../../services/language_service.dart';
import '../../widgets/khetchacha_logo.dart';
import '../ai/image_ai_diagnosis_page.dart';
import '../ai/voice_assistant_page.dart';
import '../expert/ask_expert_page.dart';

/// Full-Screen AI Assistant Farming Chatbot (Bottom Navigation Destination 3).
/// Includes multilingual chat history, real-time agronomic guidance, language selector,
/// microphone shortcut, image attachment shortcut, and 1-click expert escalation.
class AskKhetChachaAiPage extends StatefulWidget {
  final FarmerProfile profile;

  const AskKhetChachaAiPage({super.key, required this.profile});

  @override
  State<AskKhetChachaAiPage> createState() => _AskKhetChachaAiPageState();
}

class _AskKhetChachaAiPageState extends State<AskKhetChachaAiPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initWelcome();
  }

  void _initWelcome() {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    _messages.clear();
    _messages.add({
      'sender': 'bot',
      'text': _getWelcomeMessage(langCode, widget.profile.fullName),
    });
  }

  @override
  void dispose() {
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

  String _getAiResponse(String query, String langCode) {
    final q = query.toLowerCase();

    if (q.contains('pink') || q.contains('બોલવર્મ') || q.contains('ગુલાબી') || q.contains('bollworm')) {
      return langCode == 'gu'
          ? 'કપાસમાં ગુલાબી ઈયળ માટે: ૮-૧૦ ફેરોમોન ટ્રેપ લગાવો. લીંબોળીનું તેલ (૫%) અથવા ઇમામેક્ટીન બેન્ઝોએટ ૫% એસજી (૫ ગ્રામ/૧૫ લિટર) સ્પ્રે કરો.'
          : 'For Cotton Pink Bollworm: Install 8-10 Pheromone Traps/acre. Spray 5% NSKE (Neem seed extract) or Emamectin Benzoate 5% SG @ 5g/15L.';
    }

    if (q.contains('urea') || q.contains('ખાતર') || q.contains('fertilizer') || q.contains('dap')) {
      return langCode == 'gu'
          ? 'ખાતર ભલામણ: પાકની વૃદ્ધિ પ્રમાણે નાઇટ્રોજન, ફોસ્ફરસ અને પોટાશનો સંતુલિત ઉપયોગ કરો. વધુ પડતા યુરિયાથી જીવાતનો ઉપદ્રવ વધે છે.'
          : 'Fertilizer Advisory: Use split doses of Nitrogen (Urea) and balanced DAP/Potash based on soil test values. Excess Urea attracts sucking pests.';
    }

    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'ખેતચાચા AI સલાહ: પાકમાં સમયસર નિંદામણ કરો અને ભેજ જાળવી રાખો. જો પાંદડા પીળા પડતા હોય તો ૧૯:૧૯:૧૯ સ્પ્રે કરો અથવા નિષ્ણાત ડૉક્ટરની સલાહ લો.';
      case 'pa':
        return 'ਖੇਤਚਾਚਾ AI ਸਲਾਹ: ਫ਼ਸਲ ਵਿੱਚ ਜ਼ਿਆਦਾ ਯੂਰੀਆ ਨਾ ਪਾਓ। ਪੱਤੇ ਪੀਲੇ ਹੋਣ ਤੇ 19:19:19 ਜਾਂ ਜ਼ਿੰਕ સલਫੇਟ ਦਾ ਛਿੜਕਾਅ ਕਰੋ।';
      case 'hi':
        return 'खेतचाचा AI सलाह: समय पर सिंचाई करें और जैविक कीटनाशक जैसे नीम तेल का उपयोग करें। यदि रोग गंभीर है तो विशेषज्ञ से संपर्क करें।';
      default:
        return 'KhetChaCha AI Advisory: Maintain optimal field drainage and balanced nutrient supply. For sucking pests, apply neem-based bio-pesticides or consult our University Expert.';
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _msgController.clear();
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': _getAiResponse(text, langCode),
        });
      });
      _scrollToBottom();
    });
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Select AI Assistant Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageData.allLanguages.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final l = LanguageData.allLanguages[i];
                    final isCur = LanguageService.instance.currentLanguage.code == l.code;
                    return ListTile(
                      title: Text(l.nativeName, style: TextStyle(fontWeight: isCur ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(l.englishName),
                      trailing: isCur ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E20)) : null,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await LanguageService.instance.setLanguage(l);
                        if (!mounted) return;
                        setState(() => _initWelcome());
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
            Text(loc.askKhetChachaAiTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Icon(Icons.language_rounded, size: 14, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 4),
                  Text(activeLang.nativeName, style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
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
                MaterialPageRoute(builder: (_) => AskExpertPage(profile: widget.profile)),
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
                const Icon(Icons.smart_toy_rounded, color: Color(0xFF1B5E20), size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'AI Smart Assistant • Ask in text or tap mic for voice',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AskExpertPage(profile: widget.profile)),
                    );
                  },
                  child: const Text('Ask Expert →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
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
                final isUser = m['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
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
                        Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isUser ? Colors.white : const Color(0xFF212121),
                            height: 1.4,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => AskExpertPage(profile: widget.profile)),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.support_agent_rounded, size: 12, color: Color(0xFF1B5E20)),
                                      SizedBox(width: 4),
                                      Text('Ask Expert for 2nd Opinion', style: TextStyle(fontSize: 10, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Image attachment shortcut
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1B5E20)),
                    tooltip: 'Diagnose Crop Photo with Image AI',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ImageAiDiagnosisPage(profile: widget.profile)),
                      );
                    },
                  ),

                  // Microphone shortcut
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: Color(0xFFE65100)),
                    tooltip: 'Speak Question by Voice',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VoiceAssistantPage(profile: widget.profile)),
                      );
                    },
                  ),

                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type your farming question...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
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
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
