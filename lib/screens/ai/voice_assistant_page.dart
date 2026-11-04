import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/ai_conversation_message.dart';
import '../../models/farmer_profile.dart';
import '../../services/conversation_history_service.dart';
import '../../services/language_service.dart';
import '../../services/unified_agri_ai_service.dart';
import '../../services/voice_assistant_service.dart';
import '../../localization/language_data.dart';
import '../expert/ask_expert_page.dart';
import '../quick_access/ask_khet_chacha_ai_page.dart';

/// Full-Screen Multilingual Voice Assistant Page (Bottom Navigation Destination 5).
/// Features native microphone STT, real-time waveform pulse, 6-part structured
/// agricultural response rendering, spoken TTS chunking with playback controls,
/// persistent shared conversation history, and fallback text input.
class VoiceAssistantPage extends StatefulWidget {
  final FarmerProfile profile;

  const VoiceAssistantPage({super.key, required this.profile});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final TextEditingController _editQueryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _currentTranscript = '';
  AiConversationMessage? _lastAnswerMessage;
  bool _isProcessingAi = false;
  bool _isEditingTranscript = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize services
    ConversationHistoryService.instance.init();
    VoiceAssistantService.instance.init();

    // Listen to voice assistant audio state changes
    VoiceAssistantService.instance.addListener(_onVoiceServiceStateChange);

    // Find the latest voice interaction if available
    final history = ConversationHistoryService.instance.messages;
    if (history.isNotEmpty) {
      final lastBot = history.lastWhere(
        (m) => !m.isUser,
        orElse: () => history.last,
      );
      if (!lastBot.isUser) {
        _lastAnswerMessage = lastBot;
      }
    }
  }

  void _onVoiceServiceStateChange() {
    if (!mounted) return;
    final isListening = VoiceAssistantService.instance.isListening;
    if (isListening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    VoiceAssistantService.instance.removeListener(_onVoiceServiceStateChange);
    _pulseController.dispose();
    _editQueryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MICROPHONE & AI EXECUTION
  // ===========================================================================

  Future<void> _toggleMicrophone() async {
    final voiceService = VoiceAssistantService.instance;
    final currentLang = LanguageService.instance.currentLanguage.code;

    if (voiceService.isListening) {
      final captured = await voiceService.stopListening();
      if (captured.trim().isNotEmpty) {
        _currentTranscript = captured;
        _editQueryController.text = captured;
        _processVoiceQuery(captured);
      }
    } else {
      // Start listening
      setState(() {
        _isEditingTranscript = false;
        _currentTranscript = '';
        _editQueryController.clear();
      });

      final success = await voiceService.startListening(
        langCode: currentLang,
        onLiveUpdate: (liveText) {
          if (!mounted) return;
          setState(() {
            _currentTranscript = liveText;
            _editQueryController.text = liveText;
          });
        },
      );

      if (!success && voiceService.errorMessage != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(voiceService.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _processVoiceQuery(String queryText) async {
    final cleanQuery = queryText.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isProcessingAi = true;
      _currentTranscript = cleanQuery;
      _isEditingTranscript = false;
    });

    final currentLangCode = LanguageService.instance.currentLanguage.code;

    // 1. Record user query in shared history
    final userMsg = AiConversationMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: cleanQuery,
      inputMode: 'voice',
      languageCode: currentLangCode,
      timestamp: DateTime.now(),
    );
    await ConversationHistoryService.instance.addMessage(userMsg);

    // 2. Query Common AI Brain
    try {
      final responseMsg = await UnifiedAgriAiService.instance.processQuery(
        query: cleanQuery,
        profile: widget.profile,
        inputMode: 'voice',
        preferredLanguageCode: currentLangCode,
      );

      // 3. Persist AI answer in shared history
      await ConversationHistoryService.instance.addMessage(responseMsg);

      if (!mounted) return;
      setState(() {
        _lastAnswerMessage = responseMsg;
        _isProcessingAi = false;
      });

      // 4. Automatically speak answer aloud via TTS
      VoiceAssistantService.instance.speak(
        responseMsg.text,
        responseMsg.languageCode,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Processing notice: $e'),
          backgroundColor: Colors.orange.shade800,
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
          height: MediaQuery.of(context).size.height * 0.75,
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
                'Select Voice Language (ભાષા / भाषा)',
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
                          color: isCur ? const Color(0xFF1B5E20) : null,
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
    final activeLang = LanguageService.instance.currentLanguage;
    final voiceService = VoiceAssistantService.instance;
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.isSpeaking;
    final dynamicLevel = voiceService.soundLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.mic_rounded, color: Color(0xFFFF9933), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Voice Assistant (${activeLang.nativeName})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Switch to Text Chat Mode
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
            ),
            tooltip: 'Switch to Text Mode',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AskKhetChachaAiPage(profile: widget.profile),
                ),
              );
            },
          ),
          // Language Switcher Pill
          InkWell(
            onTap: _openLanguagePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    activeLang.code.toUpperCase(),
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
        ],
      ),
      body: Column(
        children: [
          // Sub-header instructions banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF1B5E20),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Speak in your mother tongue: ${activeLang.nativeName} (${activeLang.englishName})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openLanguagePicker,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Hero Animated Microphone with Dynamic Sound Waves
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final scale = isListening
                                ? (_pulseAnimation.value +
                                      (dynamicLevel * 0.25))
                                : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 115,
                                height: 115,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isListening
                                        ? [
                                            const Color(0xFFE53935),
                                            const Color(0xFFFF7043),
                                          ]
                                        : isSpeaking
                                        ? [
                                            const Color(0xFFEF6C00),
                                            const Color(0xFFFFA726),
                                          ]
                                        : [
                                            const Color(0xFF1B5E20),
                                            const Color(0xFF2E7D32),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isListening
                                                  ? Colors.red
                                                  : isSpeaking
                                                  ? Colors.orange
                                                  : const Color(0xFF1B5E20))
                                              .withValues(alpha: 0.35),
                                      blurRadius: 22,
                                      spreadRadius: isListening
                                          ? (8 + (dynamicLevel * 10))
                                          : 3,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _isProcessingAi
                                        ? null
                                        : _toggleMicrophone,
                                    child: Icon(
                                      isListening
                                          ? Icons.mic_rounded
                                          : isSpeaking
                                          ? Icons.volume_up_rounded
                                          : Icons.mic_none_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Status subtitle text
                        Text(
                          isListening
                              ? 'Listening... Speak now or tap to finish'
                              : _isProcessingAi
                              ? 'Analyzing with Agriculture AI Brain...'
                              : isSpeaking
                              ? 'Speaking answer in ${activeLang.nativeName}...'
                              : 'Tap Mic to Ask KhetChaCha by Voice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isListening
                                ? const Color(0xFFC62828)
                                : isSpeaking
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1B5E20),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isListening)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Recording audio amplitude live',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Live Transcription Display Card
                  if (_currentTranscript.isNotEmpty || isListening) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isListening
                              ? const Color(0xFFE53935)
                              : const Color(0xFF81C784),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isListening
                                    ? Icons.hearing_rounded
                                    : Icons.person_pin_rounded,
                                color: isListening
                                    ? Colors.red
                                    : const Color(0xFF1B5E20),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isListening
                                      ? 'Live Transcription:'
                                      : 'Your Voice Question:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isListening
                                        ? Colors.red
                                        : const Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              if (!_isEditingTranscript && !isListening)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingTranscript = true;
                                      _editQueryController.text =
                                          _currentTranscript;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 20),
                                    foregroundColor: const Color(0xFF1B5E20),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (_isEditingTranscript) ...[
                            TextField(
                              controller: _editQueryController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(10),
                                hintText: 'Edit your query...',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => _isEditingTranscript = false,
                                    );
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    _processVoiceQuery(
                                      _editQueryController.text,
                                    );
                                  },
                                  child: const Text('Ask AI Now'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              _currentTranscript.isEmpty
                                  ? 'Listening for words...'
                                  : _currentTranscript,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: _currentTranscript.isEmpty
                                    ? Colors.grey
                                    : const Color(0xFF212121),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // AI Processing Progress Indicator
                  if (_isProcessingAi) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Consulting Crop Master & Weather Database...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 6-Part Structured Agricultural Answer Card
                  if (_lastAnswerMessage != null && !_isProcessingAi) ...[
                    _buildStructuredAnswerCard(_lastAnswerMessage!),
                    const SizedBox(height: 20),
                  ],

                  // Recent Voice Conversations Section
                  _buildRecentVoiceHistorySection(),
                ],
              ),
            ),
          ),

          // Quick Fallback Text / Mic Input Bar at Bottom
          _buildBottomInputBar(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6-PART AGRICULTURAL RESPONSE CARD
  // ===========================================================================

  Widget _buildStructuredAnswerCard(AiConversationMessage msg) {
    final sections = msg.structuredSections;
    final voiceService = VoiceAssistantService.instance;
    final isSpeaking = voiceService.isSpeaking;
    final isPaused = voiceService.isPaused;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio Player Control Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF1B5E20),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'KhetChaCha Agri AI Advisor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),

                // Audio Playback Controls
                if (isSpeaking) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.pause_circle_filled_rounded,
                      color: Color(0xFFE65100),
                    ),
                    iconSize: 32,
                    tooltip: 'Pause audio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => voiceService.pause(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_circle_rounded,
                      color: Colors.red,
                    ),
                    iconSize: 32,
                    tooltip: 'Stop audio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => voiceService.stopSpeaking(),
                  ),
                ] else if (isPaused) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFF1B5E20),
                    ),
                    iconSize: 32,
                    tooltip: 'Resume audio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => voiceService.resume(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_circle_rounded,
                      color: Colors.red,
                    ),
                    iconSize: 32,
                    tooltip: 'Stop audio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => voiceService.stopSpeaking(),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF1B5E20),
                    ),
                    tooltip: 'Listen to advice aloud',
                    onPressed: () =>
                        voiceService.speak(msg.text, msg.languageCode),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.replay_rounded,
                      color: Color(0xFF1B5E20),
                    ),
                    tooltip: 'Replay from start',
                    onPressed: () => voiceService.replay(),
                  ),
                ],
              ],
            ),
          ),

          // If structured 6-parts are available, render them individually
          if (sections != null && sections.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sections['problemUnderstanding'] != null)
                    _buildSectionItem(
                      number: '1',
                      title: 'Problem Understanding (સમસ્યાની સમજ)',
                      body: sections['problemUnderstanding']!,
                      icon: Icons.checklist_rounded,
                      headerColor: const Color(0xFF1B5E20),
                    ),
                  if (sections['likelyCauses'] != null)
                    _buildSectionItem(
                      number: '2',
                      title: 'Likely Causes & Diagnosis (રોગ નિદાન)',
                      body: sections['likelyCauses']!,
                      icon: Icons.biotech_rounded,
                      headerColor: const Color(0xFF0277BD),
                    ),
                  if (sections['recommendedActions'] != null)
                    _buildSectionItem(
                      number: '3',
                      title: 'Recommended Actions (ભલામણ કરેલ પગલાં)',
                      body: sections['recommendedActions']!,
                      icon: Icons.eco_rounded,
                      headerColor: const Color(0xFF2E7D32),
                    ),
                  if (sections['timingAndSteps'] != null)
                    _buildSectionItem(
                      number: '4',
                      title: 'Timing & Steps (સમય અને વિગતવાર તબક્કા)',
                      body: sections['timingAndSteps']!,
                      icon: Icons.schedule_rounded,
                      headerColor: const Color(0xFFE65100),
                    ),
                  if (sections['precautionsAndDosages'] != null)
                    _buildSectionItem(
                      number: '5',
                      title: 'Precautions & Exact Dosages (સાવચેતી અને ડોઝ)',
                      body: sections['precautionsAndDosages']!,
                      icon: Icons.warning_amber_rounded,
                      headerColor: const Color(0xFFC62828),
                      isAlert: true,
                    ),
                  if (sections['additionalInfoNeeded'] != null)
                    _buildSectionItem(
                      number: '6',
                      title: 'Additional Info Needed (વધુ જરૂરી માહિતી)',
                      body: sections['additionalInfoNeeded']!,
                      icon: Icons.help_outline_rounded,
                      headerColor: const Color(0xFF455A64),
                    ),
                ],
              ),
            ),
          ] else ...[
            // Fallback plain markdown text rendering
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF333333),
                  height: 1.45,
                ),
              ),
            ),
          ],

          // Footer action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.school_rounded, size: 16),
                    label: const Text(
                      'Ask Verified Agronomist',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AskExpertPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem({
    required String number,
    required String title,
    required String body,
    required IconData icon,
    required Color headerColor,
    bool isAlert = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFF3E0) : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? const Color(0xFFFFB74D) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: headerColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: isAlert
                  ? const Color(0xFFBF360C)
                  : const Color(0xFF37474F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RECENT VOICE HISTORY SECTION
  // ===========================================================================

  Widget _buildRecentVoiceHistorySection() {
    final recentQueries = ConversationHistoryService.instance
        .getRecentVoiceQueries(limit: 6);

    if (recentQueries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 18,
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(width: 6),
            const Text(
              'Recent Voice Conversations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1B5E20),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await ConversationHistoryService.instance.clearHistory();
                setState(() {
                  _lastAnswerMessage = null;
                });
              },
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...recentQueries.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _processVoiceQuery(item.text);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 16,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM FALLBACK INPUT BAR
  // ===========================================================================

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _editQueryController,
                decoration: InputDecoration(
                  hintText: 'Type or speak your question...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (val) {
                  _processVoiceQuery(val);
                  _editQueryController.clear();
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF1B5E20)),
              onPressed: () {
                final txt = _editQueryController.text.trim();
                if (txt.isNotEmpty) {
                  _processVoiceQuery(txt);
                  _editQueryController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
