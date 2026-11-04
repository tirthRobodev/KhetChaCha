import 'package:flutter/material.dart';

import '../../models/agriculture_news_item.dart';
import '../../models/farmer_profile.dart';
import '../../services/agriculture_news_service.dart';
import '../../services/ai_news_intelligence_service.dart';
import '../../services/smart_notification_engine.dart';

/// Administrative Dialog to compose, AI-summarize, and broadcast official
/// verified government agriculture announcements, subsidies, and advisories.
class AdminNewsManagementDialog extends StatefulWidget {
  final FarmerProfile? currentFarmerProfile;
  final VoidCallback? onNewsPublished;

  const AdminNewsManagementDialog({
    super.key,
    this.currentFarmerProfile,
    this.onNewsPublished,
  });

  static Future<void> show(
    BuildContext context, {
    FarmerProfile? currentFarmerProfile,
    VoidCallback? onNewsPublished,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminNewsManagementDialog(
        currentFarmerProfile: currentFarmerProfile,
        onNewsPublished: onNewsPublished,
      ),
    );
  }

  @override
  State<AdminNewsManagementDialog> createState() =>
      _AdminNewsManagementDialogState();
}

class _AdminNewsManagementDialogState extends State<AdminNewsManagementDialog> {
  final _formKey = GlobalKey<FormState>();

  final _headlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController(
    text: 'Ministry of Agriculture & Farmers Welfare',
  );
  final _urlController = TextEditingController(text: 'https://agricoop.nic.in');
  final _districtController = TextEditingController();
  final _cropsController = TextEditingController();
  final _aiSummaryController = TextEditingController();

  AgricultureNewsCategory _selectedCategory =
      AgricultureNewsCategory.newSchemes;
  String _selectedState = 'All India';
  DateTime? _selectedDeadline;
  bool _isGeneratingAiSummary = false;
  bool _isBroadcasting = false;

  static const List<String> _indianStates = [
    'All India',
    'Gujarat',
    'Punjab',
    'Maharashtra',
    'Rajasthan',
    'Haryana',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Tamil Nadu',
    'Bihar',
    'West Bengal',
    'Odisha',
  ];

  @override
  void dispose() {
    _headlineController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    _urlController.dispose();
    _districtController.dispose();
    _cropsController.dispose();
    _aiSummaryController.dispose();
    super.dispose();
  }

  Future<void> _generateAiSummary() async {
    final headline = _headlineController.text.trim();
    final description = _descriptionController.text.trim();

    if (headline.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter headline and description first to generate AI summary.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAiSummary = true);

    try {
      final summary = await AiNewsIntelligenceService.instance
          .summarizeAnnouncementText(
            headline: headline,
            text: description,
            category: _selectedCategory,
            state: _selectedState,
            langCode: 'en',
          );

      if (mounted) {
        setState(() {
          _aiSummaryController.text = summary;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI farmer summary generated successfully!'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAiSummary = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _publishAndBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBroadcasting = true);

    try {
      final cropsText = _cropsController.text.trim();
      final targetCrops = cropsText.isNotEmpty
          ? cropsText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>['All Crops'];

      final districtText = _districtController.text.trim();
      final targetDistricts = districtText.isNotEmpty
          ? districtText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>['All'];

      final newsItem = AgricultureNewsItem(
        id: 'news_admin_${DateTime.now().millisecondsSinceEpoch}',
        headline: _headlineController.text.trim(),
        description: _descriptionController.text.trim(),
        originalSource: _sourceController.text.trim(),
        officialSourceUrl: _urlController.text.trim(),
        publishedDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        category: _selectedCategory,
        applicableState: _selectedState,
        applicableDistricts: targetDistricts,
        relevantCrops: targetCrops,
        applicationDeadline: _selectedDeadline,
        isVerified: true,
        aiSummary: _aiSummaryController.text.trim(),
      );

      // Add to Central Database
      AgricultureNewsService.instance.addNewsItem(newsItem);

      // If active profile matches, dispatch through Smart Notification Engine
      if (widget.currentFarmerProfile != null) {
        await SmartNotificationEngine.instance.processAndDeliverNewsAlert(
          news: newsItem,
          profile: widget.currentFarmerProfile!,
        );
      }

      widget.onNewsPublished?.call();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Published: "${newsItem.headline}". Broadcast processed for eligible farmers.',
            ),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBroadcasting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publish Government News & Alert',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Official Scheme, Subsidy, Advisory or SMS Broadcast',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Selector
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<AgricultureNewsCategory>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: AgricultureNewsCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat.displayNameEn,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (cat) {
                            if (cat != null) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Headline
                        const Text(
                          'Official Headline',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _headlineController,
                          decoration: InputDecoration(
                            hintText: 'e.g. 50% Subsidy on Solar Water Pumps under PM-KUSUM',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Headline is required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text(
                          'Announcement Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter full government notification details, eligibility, and process...',
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // AI Summary Generator Button
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGeneratingAiSummary
                                    ? null
                                    : _generateAiSummary,
                                icon: _isGeneratingAiSummary
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  _isGeneratingAiSummary
                                      ? 'Generating AI Summary...'
                                      : 'Auto-Generate AI Farmer Summary',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B5E20),
                                  side: const BorderSide(
                                    color: Color(0xFF1B5E20),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_aiSummaryController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _aiSummaryController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'AI Actionable Advice for Farmers',
                              labelStyle: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.all(10),
                              fillColor: const Color(0xFFF1F8E9),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Target State & District
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Target State',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedState,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _indianStates.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedState = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'District (Optional)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _districtController,
                                    decoration: InputDecoration(
                                      hintText: 'All Districts',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Target Crops & Deadline
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Target Crops (Optional)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _cropsController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Wheat, Cotton',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Application Deadline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _pickDeadline,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: Color(0xFF1B5E20),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _selectedDeadline != null
                                                  ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                                                  : 'None / Open',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _selectedDeadline != null
                                                    ? Colors.black87
                                                    : Colors.black45,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Source & Portal URL
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Department / Source',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _sourceController,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Official Portal URL',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _urlController,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // DLT-Compliant SMS Broadcast Preview Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.sms_rounded,
                                    size: 16,
                                    color: Color(0xFFE65100),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'TRAI DLT Compliant SMS Preview (Header: KHTCHA)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '[KhetChacha] Govt Alert ($_selectedState): '
                                '${_headlineController.text.isNotEmpty ? _headlineController.text : "<Headline>"}. '
                                'Apply: ${_urlController.text.isNotEmpty ? _urlController.text : "gov.in"} - KHETCHACHA',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '• Strict opt-in verification • 60-min deduplication • Rate-limited max 5/day',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isBroadcasting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isBroadcasting
                            ? null
                            : _publishAndBroadcast,
                        icon: _isBroadcasting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          _isBroadcasting
                              ? 'Publishing...'
                              : 'Publish & Broadcast',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
