import 'package:flutter/material.dart';
import '../../models/farmer_profile.dart';
import '../../services/language_service.dart';
import '../expert/ask_expert_page.dart';

/// Full-Screen Voice Assistant Page (Bottom Navigation Destination 5).
/// Features a prominent animated microphone button, multilingual speech-to-text,
/// spoken response simulation with waveform visuals, and query history.
class VoiceAssistantPage extends StatefulWidget {
  final FarmerProfile profile;

  const VoiceAssistantPage({super.key, required this.profile});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentTranscript = '';
  String _currentResponse = '';

  final List<Map<String, String>> _voiceHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Seed realistic localized past voice queries
    final langCode = LanguageService.instance.currentLanguage.code;
    _voiceHistory.addAll(_getDefaultHistory(langCode));
  }

  List<Map<String, String>> _getDefaultHistory(String langCode) {
    if (langCode == 'gu') {
      return [
        {
          'query': 'કપાસમાં ગુલાબી ઈયળ માટે શું કરવું?',
          'response': 'કપાસમાં ગુલાબી ઈયળ માટે એકરે ૮-૧૦ ફેરોમોન ટ્રેપ લગાવો અને ૫% લીંબોળીના અર્કનો સ્પ્રે કરો.',
          'time': 'Yesterday',
        },
        {
          'query': 'ઘઉંમાં પહેલું પિયત ક્યારે આપવું?',
          'response': 'ઘઉંમાં વાવણી બાદ ૨૧ દિવસે (મુકુટ મૂળ ફૂટવાની અવસ્થાએ) પ્રથમ પિયત આપવું ખૂબ જરૂરી છે.',
          'time': '3 days ago',
        },
      ];
    } else if (langCode == 'pa') {
      return [
        {
          'query': 'ਝੋਨੇ ਵਿੱਚ ਪੱਤਾ ਲਪੇਟ ਸੁੰਡੀ ਦਾ ਹੱਲ ਦੱਸੋ',
          'response': 'ਪੱਤਾ ਲਪੇਟ ਸੁੰਡੀ ਲਈ ਕਾਰਟਾਪ ਹਾਈਡ੍ਰੋਕਲੋਰਾਈਡ 4G ਜਾਂ ਕੋਰਾਜਨ 60ml ਪ੍ਰਤੀ ਏਕੜ ਸਪਰੇਅ ਕਰੋ।',
          'time': 'Yesterday',
        },
      ];
    } else {
      return [
        {
          'query': 'What is the best fertilizer dose for Cotton?',
          'response': 'Apply 120kg Nitrogen, 60kg Phosphorus, and 60kg Potash per hectare in 3 split doses.',
          'time': 'Yesterday',
        },
      ];
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    final lang = LanguageService.instance.currentLanguage;
    final langCode = lang.code;

    if (!_isListening) {
      setState(() {
        _isListening = true;
        _isSpeaking = false;
        _currentTranscript = 'Listening... Speak in ${lang.nativeName}';
        _currentResponse = '';
      });
      _pulseController.repeat(reverse: true);

      // Simulate real-time speech-to-text recognition
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;

      String sampleQuery = 'કપાસમાં ખાતરનો કેટલો હપ્તો આપવો?';
      String sampleReply =
          'કપાસમાં ફૂલ-ઝીંડવા બેસવાના સમયે ૧૯:૧૯:૧૯ અથવા પોટાશનું દ્રાવણ સ્પ્રે કરવું. યુરિયા વધુ ન નાખવું.';

      if (langCode == 'hi') {
        sampleQuery = 'टमाटर में पत्ती मुड़ने का क्या इलाज है?';
        sampleReply =
          'सफेद मक्खी नियंत्रण के लिए पीले चिपचिपे कार्ड लगाएं और नीम तेल 1500 ppm का छिड़काव करें।';
      } else if (langCode == 'pa') {
        sampleQuery = 'ਕਣਕ ਵਿੱਚ ਪੀਲੀ ਕੁੰਗੀ ਦੀ ਰੋਕਥਾਮ ਕਿਵੇਂ ਕਰੀਏ?';
        sampleReply =
          'ਪੀਲੀ ਕੁੰਗੀ ਦੇ ਪਹਿਲੇ ਲੱਛਣ ਦਿਸਦੇ ਹੀ ਪ੍ਰੋਪੀਕੋਨਾਜ਼ੋਲ (ਟਿਲਟ) 200ml ਪ੍ਰਤੀ ਏਕੜ 200 ਲੀਟਰ ਪਾਣੀ ਵਿੱਚ ਸਪਰੇਅ ਕਰੋ।';
      } else if (langCode != 'gu') {
        sampleQuery = 'How to control Pink Bollworm in Cotton naturally?';
        sampleReply =
          'Install 8-10 Pheromone traps per acre and spray 5% Neem Seed Kernel Extract (NSKE) during flower initiation.';
      }

      setState(() {
        _isListening = false;
        _isSpeaking = true;
        _currentTranscript = sampleQuery;
        _currentResponse = sampleReply;
        _voiceHistory.insert(0, {
          'query': sampleQuery,
          'response': sampleReply,
          'time': 'Just now',
        });
      });
      _pulseController.stop();

      // Simulate spoken audio playback duration
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    } else {
      setState(() {
        _isListening = false;
        _pulseController.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance.currentLanguage;

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
            Text(
              'Voice Assistant (${lang.nativeName})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Color(0xFF1B5E20), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Speak in your mother tongue: ${lang.nativeName} (${lang.englishName})',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Large Animated Microphone Centerpiece
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isListening ? _pulseAnimation.value : 1.0,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isListening
                                        ? [const Color(0xFFE53935), const Color(0xFFFF7043)]
                                        : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening ? Colors.red : const Color(0xFF1B5E20))
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      spreadRadius: _isListening ? 6 : 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _toggleListening,
                                    child: Icon(
                                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                      size: 54,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isListening
                              ? 'Listening... Tap to stop'
                              : _isSpeaking
                                  ? 'Speaking reply...'
                                  : 'Tap to Ask KhetChacha by Voice',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: _isListening ? const Color(0xFFC62828) : const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live Transcription & Response Card
                  if (_currentTranscript.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF81C784)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, color: Color(0xFF1B5E20), size: 18),
                              const SizedBox(width: 6),
                              Text('Your Question (${lang.nativeName}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1B5E20))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentTranscript,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
                          ),
                          if (_currentResponse.isNotEmpty) ...[
                            const Divider(height: 18),
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, color: Color(0xFFE65100), size: 18),
                                const SizedBox(width: 6),
                                const Text('KhetChacha Voice Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFE65100))),
                                const Spacer(),
                                if (_isSpeaking)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentResponse,
                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333), height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B5E20),
                                side: const BorderSide(color: Color(0xFF1B5E20)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.school_rounded, size: 16),
                              label: const Text('Forward this to Agriculture Expert', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AskExpertPage(profile: widget.profile)),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Query History Header
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, size: 18, color: Color(0xFF1B5E20)),
                      SizedBox(width: 6),
                      Text('Recent Voice Conversations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ..._voiceHistory.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['query']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                                  ),
                                ),
                                Text(item['time']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['response']!,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF555555), height: 1.3),
                            ),
                          ],
                        ),
                      ),
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
