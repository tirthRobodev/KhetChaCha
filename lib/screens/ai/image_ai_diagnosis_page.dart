import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/ai_diagnosis_result.dart';
import '../../models/farmer_profile.dart';
import '../../services/ai_chat_tts_service.dart';
import '../../services/ai_crop_diagnosis_service.dart';
import '../../services/permission_service.dart';
import '../expert/ask_expert_page.dart';

/// Full-Screen Image AI Diagnosis Page (Bottom Navigation Destination 4).
/// Allows capturing/uploading photos of infected leaves, stalks, or fruits,
/// runs AI analysis, shows symptoms & treatments, and allows 1-click forwarding
/// to a verified agricultural expert.
class ImageAiDiagnosisPage extends StatefulWidget {
  final FarmerProfile profile;

  const ImageAiDiagnosisPage({super.key, required this.profile});

  @override
  State<ImageAiDiagnosisPage> createState() => _ImageAiDiagnosisPageState();
}

class _ImageAiDiagnosisPageState extends State<ImageAiDiagnosisPage> {
  late String _selectedCrop;
  String? _selectedImagePath;
  bool _isAnalyzing = false;
  AiDiagnosisResult? _result;

  final List<String> _crops = [
    'Cotton',
    'Paddy (Rice)',
    'Tomato',
    'Wheat',
    'Groundnut',
    'Mustard',
    'Soybean',
    'Sugarcane',
    'Potato',
    'Onion',
    'Chilli',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.profile.effectiveProducts.isNotEmpty
        ? widget.profile.effectiveProducts.first
        : 'Cotton';
    if (!_crops.contains(_selectedCrop)) {
      _selectedCrop = _crops.first;
    }
    AiChatTtsService.instance.addListener(_onTtsChange);
  }

  @override
  void dispose() {
    AiChatTtsService.instance.removeListener(_onTtsChange);
    AiChatTtsService.instance.stop();
    super.dispose();
  }

  void _onTtsChange() {
    if (mounted) setState(() {});
  }

  void _toggleTts() {
    if (_result == null) return;
    final messageId = 'diag_${_result!.cropName}_${_result!.diagnosisTitle}';
    final speakText = _result!.fullAnswer.isNotEmpty
        ? _result!.fullAnswer
        : '${_result!.diagnosisTitle}. ${_result!.symptoms.join(". ")}. ${_result!.organicRemedies.join(". ")}. ${_result!.chemicalRemedies.join(". ")}';

    AiChatTtsService.instance.speakAnswer(
      messageId: messageId,
      text: speakText,
      langCode: _result!.languageCode.isNotEmpty
          ? _result!.languageCode
          : widget.profile.effectiveLanguage,
      context: context,
    );
  }

  Future<void> _selectImage(String source) async {
    final permType = source == 'Camera'
        ? KhetPermissionType.camera
        : KhetPermissionType.gallery;

    final isGranted = await PermissionService.instance.ensurePermission(
      context,
      type: permType,
      featureName: source == 'Camera' ? 'Camera Access' : 'Gallery Access',
      reason: source == 'Camera'
          ? 'Camera access is required to photograph crop leaves and pests for instant AI diagnostic analysis.'
          : 'Photo gallery access is required to select stored crop disease images for diagnosis.',
    );

    if (!isGranted) return;
    if (!mounted) return;

    final chosenPath = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          {
            'title': 'Paddy / Rice Crop Sample',
            'path': 'assets/images/crops/paddy.png',
            'desc': 'Field crop leaf specimen',
          },
          {
            'title': 'Gujarat Farm Specimen',
            'path': 'assets/images/farmers/gujarat.png',
            'desc': 'Field observation sample',
          },
          {
            'title': 'Maharashtra Farm Specimen',
            'path': 'assets/images/farmers/maharashtra.png',
            'desc': 'Crop and plant specimen',
          },
          {
            'title': 'Punjab Farm Specimen',
            'path': 'assets/images/farmers/punjab.png',
            'desc': 'Regional field crop observation',
          },
          {
            'title': 'Standard Plant Specimen',
            'path': 'assets/images/farmers/default_farmer.png',
            'desc': 'Standard agricultural sample',
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$source: Select Crop Specimen',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a field sample photo for genuine AI diagnosis:',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
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
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      opt['title']!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      opt['desc']!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF1B5E20),
                      size: 20,
                    ),
                    onTap: () => Navigator.pop(ctx, opt['path']),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    final selected = chosenPath ?? 'assets/images/crops/paddy.png';

    if (mounted) {
      setState(() {
        _selectedImagePath = selected;
        _result = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected crop sample image from $source'),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _runAiDiagnosis() async {
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or choose a crop image first.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final diagnosis = await AiCropDiagnosisService.instance.analyzeCropImage(
      cropName: _selectedCrop,
      imagePath: _selectedImagePath!,
      languageCode: widget.profile.effectiveLanguage,
      profile: widget.profile,
    );

    if (!mounted) return;
    setState(() {
      _result = diagnosis;
      _isAnalyzing = false;
    });
  }

  void _forwardToExpert() {
    if (_result == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AskExpertPage(
          profile: widget.profile,
          preselectedCrop: _result!.cropName,
          preselectedProblem: _result!.diagnosisTitle,
          preselectedImage: _selectedImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.document_scanner_rounded,
              color: Color(0xFFFF9933),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Image AI Crop Diagnosis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1B5E20),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Take a clear, focused photo of infected leaf, stem, or fruit in good light for instant AI diagnosis.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 1: Crop Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Target Crop',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCrop,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF2E7D32),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _crops
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCrop = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Camera Capture / Upload Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  if (_selectedImagePath == null) ...[
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC8E6C9),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Capture or Select Crop Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports JPG, PNG up to 15MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            color: const Color(0xFFE8F5E9),
                            child: _selectedImagePath!.startsWith('assets/')
                                ? Image.asset(
                                    _selectedImagePath!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.6,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                _selectedImagePath = null;
                                _result = null;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Capture & Gallery Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text(
                            'Capture Camera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          onPressed: () => _selectImage('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'From Gallery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          onPressed: () => _selectImage('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Analyze Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: _isAnalyzing ? null : _runAiDiagnosis,
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Analyzing Crop Disease with AI...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Analyze Crop Image with AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),

            // Step 3: Diagnosis Results
            if (_result != null) ...[
              Builder(
                builder: (context) {
                  final isSpeaking = AiChatTtsService.instance
                      .isMessageSpeaking(
                        'diag_${_result!.cropName}_${_result!.diagnosisTitle}',
                      );

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI Confidence: ${_result!.confidencePercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _result!.isHealthy
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Severity: ${_result!.severityLevel}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: _result!.isHealthy
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Plant Category, Part & Health Status Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC8E6C9),
                                ),
                              ),
                              child: Text(
                                '🌿 ${_result!.plantCategory} • ${_result!.plantPart}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _result!.isHealthy
                                    ? const Color(0xFFE8F5E9)
                                    : (_result!.healthStatus ==
                                              'possibly_affected'
                                          ? const Color(0xFFFFF8E1)
                                          : const Color(0xFFFFEBEE)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _result!.isHealthy
                                      ? const Color(0xFFA5D6A7)
                                      : (_result!.healthStatus ==
                                                'possibly_affected'
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFFFFCDD2)),
                                ),
                              ),
                              child: Text(
                                _result!.isHealthy
                                    ? '✅ સ્વસ્થ (Healthy Plant)'
                                    : (_result!.healthStatus ==
                                              'possibly_affected'
                                          ? '⚠️ પ્રારંભિક લક્ષણો (Early Symptoms)'
                                          : '🚨 ક્ષતિગ્રસ્ત / રોગગ્રસ્ત (Damaged / Affected)'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: _result!.isHealthy
                                      ? const Color(0xFF1B5E20)
                                      : (_result!.healthStatus ==
                                                'possibly_affected'
                                            ? const Color(0xFFE65100)
                                            : const Color(0xFFC62828)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Diagnosis Title & TTS Speaker Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _result!.diagnosisTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isSpeaking
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF1B5E20),
                                side: BorderSide(
                                  color: isSpeaking
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF1B5E20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                isSpeaking
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isSpeaking
                                    ? AiChatTtsService.instance.getStopLabel(
                                        _result!.languageCode,
                                      )
                                    : AiChatTtsService.instance.getListenLabel(
                                        _result!.languageCode,
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                              onPressed: _toggleTts,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Reassurance for healthy plants
                        if (_result!.isHealthy) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA5D6A7),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'છોડ સામાન્ય અને સ્વસ્થ જણાય છે. કોઈ બિનજરૂરી રાસાયણિક દવાની જરૂર નથી. સામાન્ય મોનિટરિંગ અને સમયસર પાણી આપો.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Immediate Actions if available
                        if (_result!.immediateActions.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.flash_on_rounded,
                                      size: 16,
                                      color: Color(0xFF00695C),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'તાત્કાલિક પગલાં (Immediate Actions):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ..._result!.immediateActions.map(
                                  (a) => Text(
                                    '• $a',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF004D40),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Symptoms
                        if (_result!.symptoms.isNotEmpty) ...[
                          const Text(
                            'Detected Symptoms:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ..._result!.symptoms.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.arrow_right_rounded,
                                    color: Color(0xFFE65100),
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: Text(
                                      s,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF424242),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Organic Remedies
                        if (_result!.organicRemedies.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.eco_rounded,
                                      size: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Organic & Bio-Control Remedies:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ..._result!.organicRemedies.map(
                                  (r) => Text(
                                    '• $r',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Chemical Remedies
                        if (_result!.chemicalRemedies.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.science_outlined,
                                      size: 16,
                                      color: Color(0xFFE65100),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Chemical Treatments (If required):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ..._result!.chemicalRemedies.map(
                                  (r) => Text(
                                    '• $r',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5D4037),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Additional Info Needed
                        if (_result!.additionalInfoNeeded.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF7B1FA2),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'વધુ માહિતી જરૂરી (Information Needed):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Color(0xFF7B1FA2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ..._result!.additionalInfoNeeded.map(
                                  (info) => Text(
                                    '• $info',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4A148C),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Uncertainty Warning
                        if (_result!.uncertaintyWarning != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFF57F17),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _result!.uncertaintyWarning!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Forward to Agriculture Expert Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text(
                            'Forward to Agriculture Expert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          onPressed: _forwardToExpert,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
