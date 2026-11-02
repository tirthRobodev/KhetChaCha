import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../localization/crop_master_database.dart';
import '../models/crop_master_entry.dart';
import '../models/farmer_profile.dart';
import '../services/farm_profile_service.dart';
import '../services/language_service.dart';
import '../widgets/khetchacha_logo.dart';
import '../services/crop_audio_service.dart';
import '../widgets/crop_visual_widget.dart';
import 'farmer_dashboard_page.dart';

/// Production-ready Multilingual Crop Selection & Farmer Onboarding System.
/// Supports all 300 Indian crops across 11 official categories.
///
/// CRITICAL SELECTION RULE:
/// NEVER preselect any crop by default. Initial selected crops = 0.
/// Wheat, Paddy, or regional crops must NEVER be preselected automatically.
/// The farmer must explicitly select each crop.
class FarmProductionSelectionPage extends StatefulWidget {
  final FarmerProfile profile;
  final bool isEditMode;

  const FarmProductionSelectionPage({
    super.key,
    required this.profile,
    this.isEditMode = false,
  });

  @override
  State<FarmProductionSelectionPage> createState() =>
      _FarmProductionSelectionPageState();
}

class _FarmProductionSelectionPageState
    extends State<FarmProductionSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final Set<String> _selectedCropIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    CropAudioService.instance.addListener(_onAudioStateChanged);
    // Pre-populate with existing profile crops ONLY if the farmer is editing
    // their existing saved farm profile.
    // For a new farmer onboarding, initial selected crops MUST be strictly 0!
    if (widget.isEditMode) {
      final existing = widget.profile.effectiveProducts;
      for (final cropName in existing) {
        final match = CropMasterDatabase.findCropByName(cropName);
        if (match != null) {
          _selectedCropIds.add(match.cropId);
        } else {
          // Check if cropName is an existing CROP_XXX ID
          final byId = CropMasterDatabase.getCropById(cropName);
          if (byId != null) {
            _selectedCropIds.add(byId.cropId);
          }
        }
      }
    } else {
      // STRICT RULE: No default selections! Wheat & Paddy are NOT preselected.
      _selectedCropIds.clear();
    }
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CropAudioService.instance.removeListener(_onAudioStateChanged);
    CropAudioService.instance.stop();
    _searchController.dispose();
    super.dispose();
  }

  List<CropMasterEntry> get _filteredCrops {
    return CropMasterDatabase.searchCrops(
      _searchQuery,
      categoryId: _selectedCategory,
    );
  }

  void _toggleCrop(String cropId) {
    setState(() {
      if (_selectedCropIds.contains(cropId)) {
        _selectedCropIds.remove(cropId);
      } else {
        _selectedCropIds.add(cropId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedCropIds.clear();
    });
  }

  /// Audio assistance: speaks crop name aloud using Text-to-Speech (TTS)
  Future<void> _playCropAudio(CropMasterEntry crop, String langCode) async {
    await CropAudioService.instance.speakCrop(crop: crop, langCode: langCode);
  }

  /// Voice search modal simulating regional Speech-To-Text
  void _openVoiceSearchDialog(String langCode) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.mic_rounded, color: Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 8),
              Text(
                langCode == 'gu'
                    ? 'બોલીને પાક શોધો'
                    : (langCode == 'hi'
                          ? 'बोलकर फसल खोजें'
                          : 'Voice Crop Search'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E7D32), width: 2),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF2E7D32),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                langCode == 'gu'
                    ? 'તમારા પાકનું નામ બોલો (દા.ત. ઘઉં, કપાસ, ડાંગર, ટામેટાં)'
                    : (langCode == 'hi'
                          ? 'अपनी फसल का नाम बोलें (जैसे: गेहूं, कपास, धान, टमाटर)'
                          : 'Say your crop name (e.g. Wheat, Cotton, Rice, Tomato)'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children:
                    [
                      'Wheat (ઘઉં)',
                      'Cotton (કપાસ)',
                      'Paddy (ડાંગર)',
                      'Tomato (ટામેટાં)',
                      'Groundnut (મગફળી)',
                    ].map((sample) {
                      return ActionChip(
                        label: Text(
                          sample,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        backgroundColor: const Color(0xFFF1F8E9),
                        onPressed: () {
                          final clean = sample.split(' ').first;
                          _searchController.text = clean;
                          setState(() {
                            _searchQuery = clean;
                          });
                          Navigator.of(ctx).pop();
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(langCode == 'gu' ? 'બંધ કરો' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  /// Farmer Assistance: "I don't know the crop name / મને પાકનું નામ ખબર નથી"
  void _openCropAssistanceSheet(String langCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF1B5E20),
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    langCode == 'gu'
                        ? 'પાક પસંદ કરવામાં મદદ'
                        : (langCode == 'hi'
                              ? 'फसल चुनने में सहायता'
                              : 'Crop Identification Help'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                langCode == 'gu'
                    ? 'જો તમને પાકનું નામ ખબર ન હોય, તો નીચેના સરળ વિકલ્પોનો ઉપયોગ કરો:'
                    : (langCode == 'hi'
                          ? 'यदि आपको फसल का नाम नहीं पता है, तो नीचे दिए गए विकल्पों का उपयोग करें:'
                          : 'If you are unsure of the crop name, use these easy options:'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Text('🌾'),
                ),
                title: Text(
                  langCode == 'gu'
                      ? 'ચોમાસુ / ખરીફ પાક જુઓ'
                      : 'Browse Kharif / Monsoon Crops',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: const Text(
                  'Cotton, Paddy, Groundnut, Soybean, Bajra',
                  style: TextStyle(fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _selectedCategory = 'cereals_millets');
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Text('❄️'),
                ),
                title: Text(
                  langCode == 'gu'
                      ? 'શિયાળુ / રવી પાક જુઓ'
                      : 'Browse Rabi / Winter Crops',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: const Text(
                  'Wheat, Mustard, Cumin, Chickpea',
                  style: TextStyle(fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _selectedCategory = 'pulses_legumes');
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF00796B),
                  ),
                ),
                title: Text(
                  langCode == 'gu'
                      ? 'ખેતી નિષ્ણાતને પૂછો'
                      : 'Ask Agriculture Expert',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  langCode == 'gu'
                      ? 'તમારા પાકનો ફોટો મોકલીને ઓળખો'
                      : 'Identify by sending crop photo to AAU Expert',
                  style: const TextStyle(fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You can ask the AAU Expert directly from your dashboard.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onContinueToDashboard() async {
    // ENFORCE CRITICAL VALIDATION: Farmer MUST select at least 1 crop!
    if (_selectedCropIds.isEmpty) {
      final langCode =
          LanguageService.instance.currentLanguage.locale.languageCode;
      final msg = langCode == 'gu'
          ? 'આગળ વધવા માટે તમારા ખેતરમાં ઉગતા ઓછામાં ઓછા એક પાકને પસંદ કરો.'
          : (langCode == 'hi'
                ? 'आगे बढ़ने के लिए अपने खेत में उगाई जाने वाली कम से कम एक फसल चुनें।'
                : 'Please select at least one crop you grow on your farm to continue.');

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    // Resolve canonical English crop names for profile and dashboard
    final selectedProductNames = _selectedCropIds.map((id) {
      final c = CropMasterDatabase.getCropById(id);
      return c != null ? c.canonicalNameEn : id;
    }).toList();

    // Resolve distinct category IDs
    final selectedCategories = _selectedCropIds
        .map((id) {
          final c = CropMasterDatabase.getCropById(id);
          return c?.categoryId ?? 'cereals_millets';
        })
        .toSet()
        .toList();

    final updatedProfile = widget.profile.copyWith(
      crops: selectedProductNames,
      selectedProducts: selectedProductNames,
      selectedCategories: selectedCategories,
      selectedLanguage: langCode,
      farmSetupCompleted: true,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Save immediately to local cache & Firebase background sync
    await FarmProfileService.instance.saveFarmProfile(updatedProfile);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (widget.isEditMode) {
      Navigator.of(context).pop(updatedProfile);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => FarmerDashboardPage(profile: updatedProfile),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final displayCrops = _filteredCrops;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: widget.isEditMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: KhetChachaLogo.appBar(height: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Step Progress Indicator (if onboarding)
                    if (!widget.isEditMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            _buildStepCircle(
                              number: '1',
                              label: loc.stepLogin,
                              isActive: false,
                              isDone: true,
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            _buildStepCircle(
                              number: '2',
                              label: loc.stepSelectProduction,
                              isActive: true,
                              isDone: false,
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            _buildStepCircle(
                              number: '3',
                              label: loc.stepDashboard,
                              isActive: false,
                              isDone: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Title & Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.park_rounded,
                            color: Color(0xFF2E7D32),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langCode == 'gu'
                                    ? 'તમે તમારા ખેતરમાં કયા પાક ઉગાડો છો?'
                                    : (langCode == 'hi'
                                          ? 'आप अपने खेत में कौन-कौन सी फसल उगाते हैं?'
                                          : loc.selectFarmProductionTitle),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                langCode == 'gu'
                                    ? 'તમારા ખેતરમાં ઉગતા પાક, શાકભાજી કે ફળો પસંદ કરો જેથી ખેતચાચા તમને સચોટ સલાહ આપી શકે.'
                                    : (langCode == 'hi'
                                          ? 'अपनी फसलें, सब्जियां या फल चुनें ताकि खेतचाचा आपको सही सलाह और मौसम अलर्ट दे सके।'
                                          : loc.selectFarmProductionSubtitle),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. Search Bar with Voice Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: langCode == 'gu'
                              ? 'પાક, શાકભાજી, ફળો શોધો (દા.ત. ઘઉં, કપાસ)...'
                              : (langCode == 'hi'
                                    ? 'फसल, सब्जी, फल खोजें (जैसे गेहूं, कपास)...'
                                    : loc.searchCropsHint),
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9E9E9E),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.mic_rounded,
                                  color: Color(0xFFE65100),
                                ),
                                tooltip: 'Voice Search',
                                onPressed: () =>
                                    _openVoiceSearchDialog(langCode),
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Farmer Help Button: "મને પાકનું નામ ખબર નથી"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => _openCropAssistanceSheet(langCode),
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          size: 14,
                          color: Color(0xFF0288D1),
                        ),
                        label: Text(
                          langCode == 'gu'
                              ? 'મને પાકનું નામ ખબર નથી'
                              : (langCode == 'hi'
                                    ? 'मुझे फसल का नाम नहीं पता'
                                    : "I don't know the crop name"),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 4. Horizontal Category Filter Tabs (11 Categories + All)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CropMasterDatabase.categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildCategoryChip(
                              id: cat.id,
                              label: cat.getTitle(langCode),
                              emoji: cat.iconEmoji,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. Responsive Crop Cards Grid (3 Columns)
                    if (displayCrops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              langCode == 'gu'
                                  ? 'કોઈ પાક મળ્યો નથી'
                                  : 'No crops found matching your search',
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayCrops.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                        itemBuilder: (context, index) {
                          if (index == displayCrops.length) {
                            return _buildMoreProductsCard(loc, langCode);
                          }

                          final crop = displayCrops[index];
                          final isSelected = _selectedCropIds.contains(
                            crop.cropId,
                          );

                          return _buildCropCard(
                            crop: crop,
                            isSelected: isSelected,
                            langCode: langCode,
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 6. Sticky Bottom Selection Panel & Continue Button
            _buildBottomPanel(loc, langCode),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required String emoji,
  }) {
    final isSelected = _selectedCategory == id;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF424242),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreProductsCard(AppLocalizations loc, String langCode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCropAssistanceSheet(langCode),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81C784), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF2E7D32),
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  loc.moreProducts,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCard({
    required CropMasterEntry crop,
    required bool isSelected,
    required String langCode,
  }) {
    final isSpeaking = CropAudioService.instance.isCropSpeaking(crop.cropId);
    final isLoading = CropAudioService.instance.isCropLoading(crop.cropId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleCrop(crop.cropId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Audio / TTS Speaker Button at Top Left (isolated tap: only speaks audio)
              Positioned(
                top: 4,
                left: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _playCropAudio(crop, langCode),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSpeaking
                            ? const Color(0xFFFFD54F)
                            : (isLoading
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1B5E20),
                              ),
                            )
                          : Icon(
                              Icons.volume_up_rounded,
                              size: 16,
                              color: isSpeaking
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF757575),
                            ),
                    ),
                  ),
                ),
              ),

              // Selection Checkbox at Top Right (isolated tap: toggles selection)
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => _toggleCrop(crop.cropId),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFBDBDBD),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ),
              ),

              // Crop Visual, Localized Name (2-line support), Secondary Label
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Dedicated Crop Visual Widget
                    CropVisualWidget(
                      crop: crop,
                      size: 46.0,
                      isSelected: isSelected,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 6),
                    // Localized Crop Name (2 lines to avoid awkward truncation like Moo...)
                    SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          crop.getLocalizedName(langCode),
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF212121),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Secondary English / Canonical Label
                    Text(
                      crop.getSecondaryLabel(langCode),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations loc, String langCode) {
    final selectedCount = _selectedCropIds.length;
    final selectedCrops = _selectedCropIds
        .map((id) => CropMasterDatabase.getCropById(id))
        .whereType<CropMasterEntry>()
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Selected (N) & Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langCode == 'gu'
                    ? 'પસંદ કરેલ ($selectedCount)'
                    : (langCode == 'hi'
                          ? 'चुने गए ($selectedCount)'
                          : loc.selectedCount(selectedCount)),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              if (selectedCount > 0)
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  child: Text(
                    langCode == 'gu'
                        ? 'બધું સાફ કરો'
                        : (langCode == 'hi' ? 'सभी हटाएं' : loc.clearAll),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Chips of selected crops
          if (selectedCrops.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCrops.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = selectedCrops[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.iconEmoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          c.getLocalizedName(langCode),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _toggleCrop(c.cropId),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Helper note when 0 crops are selected
          if (selectedCount == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFE65100),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      langCode == 'gu'
                          ? 'આગળ વધવા માટે તમારા ખેતરમાં ઉગતા ઓછામાં ઓછા એક પાકને પસંદ કરો.'
                          : (langCode == 'hi'
                                ? 'आगे बढ़ने के लिए अपने खेत में उगाई जाने वाली कम से कम एक फसल चुनें।'
                                : loc.selectAtLeastOneHint),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Large Continue Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCount > 0
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: selectedCount > 0 ? 2 : 0,
              ),
              onPressed: (_isSaving || selectedCount == 0)
                  ? null
                  : _onContinueToDashboard,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Center(
                      child: Text(
                        loc.continueToDashboard,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle({
    required String number,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF2E7D32)
                : (isActive ? const Color(0xFF1B5E20) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isActive || isDone)
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFBDBDBD),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : const Color(0xFF757575),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF1B5E20) : const Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}
