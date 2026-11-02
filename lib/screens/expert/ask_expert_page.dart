import 'package:flutter/material.dart';

import '../../models/expert_query.dart';
import '../../models/farmer_notification.dart';
import '../../models/farmer_profile.dart';
import '../../services/expert_query_service.dart';
import '../../services/notification_service.dart';

/// Full-Featured Ask Agriculture Expert Screen.
/// Implements 3-Level Problem Taxonomy (Crop -> Category -> Specific Problem),
/// multi-modal query submission (Text, Image, Voice, Video),
/// end-to-end status tracking timeline, and Role-Based Expert Dashboard.
class AskExpertPage extends StatefulWidget {
  final FarmerProfile profile;
  final String? preselectedCrop;
  final String? preselectedProblem;
  final String? preselectedImage;

  const AskExpertPage({
    super.key,
    required this.profile,
    this.preselectedCrop,
    this.preselectedProblem,
    this.preselectedImage,
  });

  @override
  State<AskExpertPage> createState() => _AskExpertPageState();
}

class _AskExpertPageState extends State<AskExpertPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // 3-Level Problem Taxonomy selections
  late String _selectedCrop;
  late String _selectedCategory;
  late String _selectedSpecificProblem;

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  final List<String> _mediaPaths = [];
  final List<String> _mediaTypes = [];

  bool _isSubmitting = false;
  bool _isRecordingVoice = false;
  int _voiceSeconds = 0;
  bool _isExpertView = false; // Role-based view toggle

  List<ExpertQuery> _queries = [];
  bool _isLoadingQueries = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _selectedCrop =
        widget.preselectedCrop ??
        (widget.profile.effectiveProducts.isNotEmpty
            ? widget.profile.effectiveProducts.first
            : 'Cotton');
    if (!ExpertQueryService.availableCrops.contains(_selectedCrop)) {
      _selectedCrop = ExpertQueryService.availableCrops.first;
    }

    _selectedCategory = ExpertQueryService.problemCategories.first;
    _selectedSpecificProblem =
        widget.preselectedProblem ??
        ExpertQueryService.specificProblemsMap[_selectedCategory]!.first;

    if (widget.preselectedImage != null &&
        widget.preselectedImage!.isNotEmpty) {
      _mediaPaths.add(widget.preselectedImage!);
      _mediaTypes.add('image');
    }

    _villageController.text = widget.profile.effectiveVillage;
    _loadQueries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _loadQueries() async {
    setState(() => _isLoadingQueries = true);
    final items = await ExpertQueryService.instance.getFarmerQueries(
      widget.profile.firebaseUid ?? 'default_farmer',
    );
    if (!mounted) return;
    setState(() {
      _queries = items;
      _isLoadingQueries = false;
    });
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _selectedCategory = newCategory;
      final problems =
          ExpertQueryService.specificProblemsMap[newCategory] ??
          ['General Issue'];
      _selectedSpecificProblem = problems.first;
    });
  }

  void _simulateAddAttachment(String type) {
    setState(() {
      if (type == 'image') {
        _mediaPaths.add('assets/images/farmers/gujarat_farmer.jpg');
        _mediaTypes.add('image');
      } else if (type == 'voice') {
        _mediaPaths.add(
          'audio_query_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        _mediaTypes.add('audio');
      } else if (type == 'video') {
        _mediaPaths.add('field_inspection_video.mp4');
        _mediaTypes.add('video');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment added successfully'),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleVoiceRecording() {
    if (!_isRecordingVoice) {
      setState(() {
        _isRecordingVoice = true;
        _voiceSeconds = 0;
      });
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_isRecordingVoice) return false;
        setState(() => _voiceSeconds++);
        return _isRecordingVoice && _voiceSeconds < 60;
      });
    } else {
      setState(() {
        _isRecordingVoice = false;
      });
      _simulateAddAttachment('voice');
    }
  }

  Future<void> _submitFarmerQuery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final farmerName = widget.profile.fullName.isNotEmpty
        ? widget.profile.fullName
        : 'Farmer';
    final query = await ExpertQueryService.instance.submitQuery(
      farmerId: widget.profile.firebaseUid ?? 'default_farmer',
      farmerName: farmerName,
      farmerPhone: widget.profile.mobileNumber,
      state: widget.profile.effectiveState,
      district: widget.profile.effectiveDistrict,
      village: _villageController.text.trim(),
      crop: _selectedCrop,
      problemCategory: _selectedCategory,
      specificProblem: _selectedSpecificProblem,
      description: _descController.text.trim(),
      mediaPaths: List.from(_mediaPaths),
      mediaTypes: List.from(_mediaTypes),
    );

    await NotificationService.instance.addNotification(
      FarmerNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Query Submitted: ${query.id}',
        message:
            'Your query on $_selectedCrop has been assigned to Agricultural Experts in ${widget.profile.effectiveDistrict}.',
        category: 'Expert Replies',
        timestamp: DateTime.now(),
        deepLinkTarget: 'expert_queries',
      ),
    );

    setState(() {
      _isSubmitting = false;
      _descController.clear();
      _mediaPaths.clear();
      _mediaTypes.clear();
    });

    await _loadQueries();
    _tabController.animateTo(1); // Switch to My Queries tab

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Query ${query.id} submitted! Assigned to University Expert.',
        ),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }

  void _showExpertReplyDialog(ExpertQuery q) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF1B5E20)),
            const SizedBox(width: 8),
            Text('Expert Advisory: ${q.id}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer: ${q.farmerName} (${q.district}, ${q.state})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Problem: ${q.crop} → ${q.specificProblem}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 8),
              Text(
                q.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
              ),
              const Divider(height: 16),
              const Text(
                'Enter Agricultural Prescription & Treatment:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: replyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Prescribe organic bio-control or chemical doses, spray timing, and cultural practices...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              await ExpertQueryService.instance.submitExpertResponse(
                queryId: q.id,
                expertId: 'exp_manual_01',
                expertName: 'Dr. Ramesh Patel',
                expertDesignation: 'Senior Agronomist, AAU Anand',
                responseText: replyController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              _loadQueries();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Advisory sent to farmer successfully!'),
                  backgroundColor: Color(0xFF1B5E20),
                ),
              );
            },
            child: const Text('Send Advisory'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return const Color(0xFF0288D1);
      case 'assigned':
        return const Color(0xFF7B1FA2);
      case 'under review':
        return const Color(0xFFF57C00);
      case 'answered':
      case 'closed':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final problemsForSelectedCategory =
        ExpertQueryService.specificProblemsMap[_selectedCategory] ??
        ['General Issue'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ask Agriculture Expert',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Toggle between Farmer View and Expert View
          IconButton(
            tooltip: _isExpertView
                ? 'Switch to Farmer View'
                : 'Switch to Expert Dashboard',
            icon: Icon(
              _isExpertView ? Icons.person_rounded : Icons.school_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isExpertView = !_isExpertView);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isExpertView
                        ? 'Switched to Expert Portal Mode'
                        : 'Switched to Farmer Mode',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9933),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            const Tab(
              text: 'Submit New Query',
              icon: Icon(Icons.edit_note_rounded, size: 20),
            ),
            Tab(
              text: _isExpertView
                  ? 'Assigned Queries (${_queries.length})'
                  : 'My Queries (${_queries.length})',
              icon: const Icon(Icons.track_changes_rounded, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Submit Multi-Modal Query Form
          _buildSubmitQueryForm(problemsForSelectedCategory),

          // Tab 2: Track Status & Expert Responses
          _buildQueryTrackingList(),
        ],
      ),
    );
  }

  Widget _buildSubmitQueryForm(List<String> problemsForSelectedCategory) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Guidance Banner
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
                    Icons.support_agent_rounded,
                    color: Color(0xFF1B5E20),
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Directly connect with University & KVK Agronomists. Submit your crop problem with images, audio notes, or video.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: 3-Level Problem Taxonomy
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
                    '1. Problem Taxonomy (3 Levels)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Level 1: Crop
                  const Text(
                    'Level 1: Select Crop / પાક પસંદ કરો',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
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
                    items: ExpertQueryService.availableCrops
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCrop = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Level 2: Problem Category
                  const Text(
                    'Level 2: Problem Category / સમસ્યાનો પ્રકાર',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.category_rounded,
                        color: Color(0xFFE65100),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ExpertQueryService.problemCategories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 14),

                  // Level 3: Specific Problem
                  const Text(
                    'Level 3: Specific Problem / ચોક્કસ લક્ષણ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('problem_$_selectedCategory'),
                    initialValue:
                        problemsForSelectedCategory.contains(
                          _selectedSpecificProblem,
                        )
                        ? _selectedSpecificProblem
                        : problemsForSelectedCategory.first,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.bug_report_rounded,
                        color: Color(0xFFC62828),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: problemsForSelectedCategory
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSpecificProblem = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Description & Location
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
                    '2. Describe Your Crop Condition',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter symptoms, crop age, fertilizer applied, weather conditions...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Please provide a brief description of the issue';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _villageController,
                          decoration: InputDecoration(
                            labelText: 'Village / ગામ',
                            prefixIcon: const Icon(
                              Icons.home_rounded,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            '${widget.profile.effectiveDistrict}, ${widget.profile.effectiveState}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Multi-modal Attachments (Image, Voice, Video)
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
                    '3. Multi-Modal Attachments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Photos, voice recordings, or videos help agronomists accurately identify the infection.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 14),

                  // Attachment Action Buttons
                  Row(
                    children: [
                      // Camera / Photo
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text(
                            'Add Photo',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () => _simulateAddAttachment('image'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Voice Note
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isRecordingVoice
                                ? Colors.white
                                : const Color(0xFFE65100),
                            backgroundColor: _isRecordingVoice
                                ? const Color(0xFFD32F2F)
                                : null,
                            side: BorderSide(
                              color: _isRecordingVoice
                                  ? Colors.red
                                  : const Color(0xFFE65100),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: Icon(
                            _isRecordingVoice
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isRecordingVoice
                                ? 'Stop (${_voiceSeconds}s)'
                                : 'Voice Note',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onPressed: _toggleVoiceRecording,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Video
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0288D1),
                            side: const BorderSide(color: Color(0xFF0288D1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.videocam_outlined, size: 18),
                          label: const Text(
                            'Add Video',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () => _simulateAddAttachment('video'),
                        ),
                      ),
                    ],
                  ),

                  // Display Attached Chips
                  if (_mediaPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_mediaPaths.length, (idx) {
                        final type = _mediaTypes[idx];
                        IconData ic = Icons.image_rounded;
                        Color col = const Color(0xFF2E7D32);
                        if (type == 'audio') {
                          ic = Icons.mic_rounded;
                          col = const Color(0xFFE65100);
                        } else if (type == 'video') {
                          ic = Icons.videocam_rounded;
                          col = const Color(0xFF0288D1);
                        }

                        return Chip(
                          avatar: Icon(ic, size: 16, color: col),
                          label: Text(
                            '$type #${idx + 1}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: col,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: col.withValues(alpha: 0.1),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            setState(() {
                              _mediaPaths.removeAt(idx);
                              _mediaTypes.removeAt(idx);
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: _isSubmitting ? null : _submitFarmerQuery,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Submit Query to Agriculture Expert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryTrackingList() {
    if (_isLoadingQueries) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      );
    }

    if (_queries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No queries submitted yet',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Submit your crop issue in the first tab to get expert advice.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _queries.length,
      itemBuilder: (context, i) {
        final q = _queries[i];
        final statusColor = _getStatusColor(q.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      q.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        q.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3-Level Problem Breadcrumb
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        q.crop,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Expanded(
                      child: Text(
                        q.specificProblem,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF616161),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Lifecycle Tracking Timeline
                _buildStatusTimeline(q.status),

                // Assigned Expert & Advisory response
                if (q.assignedExpertName != null) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.school_rounded,
                          size: 16,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.assignedExpertName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            Text(
                              q.expertDesignation ?? 'Verified Agronomist',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF757575),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Answered Advisory Text
                if (q.expertResponseText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC5E1A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Prescribed Advisory / ભલામણ:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q.expertResponseText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expert Dashboard Action (When viewing as Expert)
                if (_isExpertView && !q.isAnswered) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: const Text(
                      'Reply as Expert',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _showExpertReplyDialog(q),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['Submitted', 'Assigned', 'Under Review', 'Answered'];
    final currentIndex = steps.indexWhere(
      (s) => s.toLowerCase() == currentStatus.toLowerCase(),
    );
    final activeIdx = currentIndex == -1 ? 0 : currentIndex;

    return Row(
      children: List.generate(steps.length, (idx) {
        final isDone = idx <= activeIdx;
        final isCurrent = idx == activeIdx;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: isDone
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFE0E0E0),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            )
                          : Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF757575),
                              ),
                            ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[idx],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDone
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF757575),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (idx < steps.length - 1)
                Container(
                  height: 2,
                  width: 14,
                  color: idx < activeIdx
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFE0E0E0),
                ),
            ],
          ),
        );
      }),
    );
  }
}
