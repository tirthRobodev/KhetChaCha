import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/govt_scheme_localization.dart';
import '../../models/farmer_profile.dart';
import '../../models/govt_scheme.dart';
import '../../services/govt_scheme_service.dart';
import '../../services/language_service.dart';

/// Clean, responsive, comprehensive Government Scheme Details Page.
/// Features verified government benefits, eligibility criteria, required documents,
/// client-side preliminary eligibility evaluation, and verified "Apply Online" portal launcher.
class SchemeDetailsPage extends StatefulWidget {
  final GovtScheme scheme;
  final FarmerProfile profile;

  const SchemeDetailsPage({
    super.key,
    required this.scheme,
    required this.profile,
  });

  @override
  State<SchemeDetailsPage> createState() => _SchemeDetailsPageState();
}

class _SchemeDetailsPageState extends State<SchemeDetailsPage> {
  // Eligibility checker state
  bool _showEligibilityChecker = false;
  late String _checkState;
  String _farmerCategory = 'Small & Marginal';
  double _landholdingAcres = 2.5;
  String _cropOrActivity = 'Cotton';
  Map<String, dynamic>? _eligibilityResult;

  final List<String> _states = [
    'All India',
    'Gujarat',
    'Punjab',
    'Maharashtra',
    'Uttar Pradesh',
    'Rajasthan',
    'Madhya Pradesh',
    'Haryana',
  ];

  final List<String> _farmerCategories = [
    'Small & Marginal',
    'General',
    'SC/ST',
    'Women',
  ];

  @override
  void initState() {
    super.initState();
    _checkState =
        widget.profile.effectiveState.isNotEmpty &&
            _states.contains(widget.profile.effectiveState)
        ? widget.profile.effectiveState
        : (widget.scheme.state.toLowerCase() != 'all india'
              ? widget.scheme.state
              : 'Gujarat');
    if (widget.scheme.applicableCrops.isNotEmpty &&
        !widget.scheme.applicableCrops.contains('All Crops')) {
      _cropOrActivity = widget.scheme.applicableCrops.first;
    }
  }

  Future<void> _openOfficialPortal(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Official application link is not announced yet.'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open portal: $urlString'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching official link: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  void _runEligibilityCheck() {
    final result = GovtSchemeService.instance.evaluateEligibility(
      scheme: widget.scheme,
      farmerState: _checkState,
      farmerCategory: _farmerCategory,
      landholdingAcres: _landholdingAcres,
      cropOrActivity: _cropOrActivity,
    );
    setState(() {
      _eligibilityResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scheme;
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          GovtSchemeLocalization.getDetailsApplyLabel(langCode),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Card
              _buildHeaderCard(s, langCode),

              const SizedBox(height: 14),

              // 2. Benefits & Financial Assistance Card
              _buildBenefitsCard(s, langCode),

              const SizedBox(height: 14),

              // 3. Eligibility Criteria Card
              _buildEligibilityCriteriaCard(s, langCode),

              const SizedBox(height: 14),

              // 4. Interactive "Check My Eligibility" Module
              _buildEligibilityCheckerModule(s, langCode),

              const SizedBox(height: 14),

              // 5. Required Documents Checklist Card
              _buildDocumentsCard(s, langCode),

              const SizedBox(height: 14),

              // 6. Application Timeline & How to Apply Card
              _buildTimelineAndHowToApplyCard(s, langCode),

              const SizedBox(height: 14),

              // 7. Official Source & Verification Metadata Card
              _buildOfficialSourceCard(s, langCode),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(s, langCode),
    );
  }

  Widget _buildHeaderCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.governmentLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  GovtSchemeLocalization.getCategoryLabel(s.category, langCode),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.statusBadgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s.statusBadgeTextColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  GovtSchemeLocalization.getStatusLabel(
                    s.status,
                    langCode,
                  ).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: s.statusBadgeTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scheme Name
          Text(
            s.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Department
          Text(
            s.department,
            style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
          ),

          const Divider(height: 20),

          // Overview description
          Text(
            s.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  GovtSchemeLocalization.getBenefitsHeading(langCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.benefitsSubsidy,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Benefit Type: ${s.benefitType}',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF616161),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityCriteriaCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.how_to_reg_rounded,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  GovtSchemeLocalization.getEligibilityHeading(langCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...s.eligibilityCriteria.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF424242),
                        height: 1.35,
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

  Widget _buildEligibilityCheckerModule(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFF59D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showEligibilityChecker = !_showEligibilityChecker;
                if (_showEligibilityChecker && _eligibilityResult == null) {
                  _runEligibilityCheck();
                }
              });
            },
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFE65100),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GovtSchemeLocalization.getCheckEligibilityLabel(langCode),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
                Icon(
                  _showEligibilityChecker
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFE65100),
                ),
              ],
            ),
          ),
          if (!_showEligibilityChecker) ...[
            const SizedBox(height: 6),
            const Text(
              'Tap here to check if your farm parameters potentially match this scheme without sharing sensitive numbers.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF795548)),
            ),
          ],
          if (_showEligibilityChecker) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // State Dropdown
            const Text(
              'Your Farm State:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _checkState,
              isDense: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              items: _states
                  .map(
                    (st) => DropdownMenuItem(
                      value: st,
                      child: Text(st, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _checkState = val);
                  _runEligibilityCheck();
                }
              },
            ),

            const SizedBox(height: 10),

            // Farmer Category
            const Text(
              'Farmer Category:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _farmerCategory,
              isDense: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              items: _farmerCategories
                  .map(
                    (fc) => DropdownMenuItem(
                      value: fc,
                      child: Text(fc, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _farmerCategory = val);
                  _runEligibilityCheck();
                }
              },
            ),

            const SizedBox(height: 10),

            // Landholding Slider
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cultivable Landholding:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_landholdingAcres.toStringAsFixed(1)} Acres',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            Slider(
              value: _landholdingAcres,
              min: 0.5,
              max: 20.0,
              divisions: 39,
              activeColor: const Color(0xFF1B5E20),
              label: '${_landholdingAcres.toStringAsFixed(1)} Ac',
              onChanged: (val) {
                setState(() => _landholdingAcres = val);
                _runEligibilityCheck();
              },
            ),

            // Evaluation Result Card
            if (_eligibilityResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _eligibilityResult!['isEligible'] == true
                      ? const Color(0xFFE8F5E9)
                      : (_eligibilityResult!['needsMoreInfo'] == true
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFFFEBEE)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _eligibilityResult!['isEligible'] == true
                        ? const Color(0xFF81C784)
                        : (_eligibilityResult!['needsMoreInfo'] == true
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFE57373)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _eligibilityResult!['isEligible'] == true
                              ? Icons.check_circle_rounded
                              : (_eligibilityResult!['needsMoreInfo'] == true
                                    ? Icons.info_rounded
                                    : Icons.cancel_rounded),
                          color: _eligibilityResult!['isEligible'] == true
                              ? const Color(0xFF2E7D32)
                              : (_eligibilityResult!['needsMoreInfo'] == true
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFFC62828)),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _eligibilityResult!['verdict'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _eligibilityResult!['isEligible'] == true
                                  ? const Color(0xFF2E7D32)
                                  : (_eligibilityResult!['needsMoreInfo'] ==
                                            true
                                        ? const Color(0xFFE65100)
                                        : const Color(0xFFC62828)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...(_eligibilityResult!['reasons'] as List<String>).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $r',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _eligibilityResult!['disclaimer'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.file_copy_rounded,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  GovtSchemeLocalization.getDocumentsHeading(langCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...s.requiredDocuments.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF616161),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF424242),
                        height: 1.35,
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

  Widget _buildTimelineAndHowToApplyCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  GovtSchemeLocalization.getHowToApplyHeading(langCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timeline row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8F5E9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Start Date: ${s.startDate}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF424242),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.event_busy_rounded,
                      size: 14,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Deadline: ${s.deadline}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            s.howToApply,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialSourceCard(GovtScheme s, String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Verified Official Source',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last Verified: ${s.lastVerifiedDate}',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Portal: ${s.portalName}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF424242)),
          ),
          Text(
            'Authority: ${s.officialSource}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _openOfficialPortal(s.officialWebsiteUrl),
            child: Text(
              s.officialWebsiteUrl,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF1565C0),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(GovtScheme s, String langCode) {
    final canApply = s.applyUrl.isNotEmpty && !s.isClosed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canApply
              ? const Color(0xFF1B5E20)
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canApply ? 2 : 0,
        ),
        onPressed: canApply ? () => _openOfficialPortal(s.applyUrl) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new_rounded, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                canApply
                    ? GovtSchemeLocalization.getApplyOnlineLabel(langCode)
                    : 'Application Window Closed',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
