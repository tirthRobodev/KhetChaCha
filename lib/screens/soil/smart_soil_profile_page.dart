import 'package:flutter/material.dart';

import '../../models/farmer_profile.dart';
import '../../models/soil_profile.dart';
import '../../services/farm_profile_service.dart';
import '../../services/language_service.dart';
import '../../services/soil_analysis_service.dart';

/// Interactive Soil Profile Management and Chemical Fertility Diagnostics Screen.
/// Allows farmers to review estimated agro-climatic soil benchmarks, edit NPK/pH values,
/// mark lab test verification, and receive ICAR-recommended soil amendments.
class SmartSoilProfilePage extends StatefulWidget {
  final FarmerProfile profile;
  final SoilProfile? initialSoilProfile;

  const SmartSoilProfilePage({
    super.key,
    required this.profile,
    this.initialSoilProfile,
  });

  @override
  State<SmartSoilProfilePage> createState() => _SmartSoilProfilePageState();
}

class _SmartSoilProfilePageState extends State<SmartSoilProfilePage> {
  late SoilType _selectedSoilType;
  late double _pH;
  late double _nitrogen;
  late double _phosphorus;
  late double _potassium;
  late double _organicCarbon;
  late String _soilMoisture;
  late String _drainageCapacity;
  late bool _isLabVerified;
  late TextEditingController _reportIdController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reportIdController = TextEditingController();
    final soil =
        widget.initialSoilProfile ??
        SoilProfile.estimatedForRegion(
          state: widget.profile.effectiveState,
          district: widget.profile.effectiveDistrict,
          preferredType: SoilTypeExtension.fromString(widget.profile.soilType),
        );
    _applySoilData(soil);
    _isLoading = false;
    _initSoilData();
  }

  void _applySoilData(SoilProfile soil) {
    _selectedSoilType = soil.soilType;
    _pH = soil.pH;
    _nitrogen = soil.nitrogenKgPerHa;
    _phosphorus = soil.phosphorusKgPerHa;
    _potassium = soil.potassiumKgPerHa;
    _organicCarbon = soil.organicCarbonPercent;
    _soilMoisture = soil.soilMoisture;
    _drainageCapacity = soil.drainageCapacity;
    _isLabVerified = soil.isLabVerified;
    _reportIdController.text = soil.labReportNumber;
  }

  Future<void> _initSoilData() async {
    final soil = await SoilAnalysisService.instance.getSoilProfile(
      farmerUidOrPhone: widget.profile.mobileNumber,
      state: widget.profile.effectiveState,
      district: widget.profile.effectiveDistrict,
      preferredType: SoilTypeExtension.fromString(widget.profile.soilType),
    );

    if (mounted) {
      setState(() {
        _applySoilData(soil);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reportIdController.dispose();
    super.dispose();
  }

  SoilProfile _buildCurrentProfile() {
    return SoilProfile(
      soilType: _selectedSoilType,
      pH: _pH,
      nitrogenKgPerHa: _nitrogen,
      phosphorusKgPerHa: _phosphorus,
      potassiumKgPerHa: _potassium,
      organicCarbonPercent: _organicCarbon,
      soilMoisture: _soilMoisture,
      drainageCapacity: _drainageCapacity,
      isLabVerified: _isLabVerified,
      labReportNumber: _reportIdController.text.trim(),
      testedDate: _isLabVerified ? DateTime.now() : null,
      dataSource: _isLabVerified
          ? 'Soil Health Card Lab Report (${_reportIdController.text.trim()})'
          : 'ICAR District Agro-climatic Benchmark (Estimated)',
    );
  }

  Future<void> _saveSoilProfile() async {
    setState(() {
      _isSaving = true;
    });

    final current = _buildCurrentProfile();
    await SoilAnalysisService.instance.saveSoilProfile(
      farmerUidOrPhone: widget.profile.mobileNumber,
      profile: current,
    );

    // Update main farmer profile with matching soil type
    final updatedProfile = widget.profile.copyWith(
      soilType: _selectedSoilType.displayNameEn,
    );
    await FarmProfileService.instance.saveFarmProfile(updatedProfile);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm soil profile saved successfully!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );

    Navigator.of(context).pop(current);
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final soilCurrent = _isLoading
        ? const SoilProfile()
        : _buildCurrentProfile();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'જમીન વિશ્લેષણ અને ગુણવત્તા'
              : (langCode == 'hi'
                    ? 'मृदा विश्लेषण एवं स्वास्थ्य'
                    : 'Farm Soil Profile & Health'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Data Verification Status Banner
                  _buildVerificationBanner(langCode),

                  const SizedBox(height: 16),

                  // 2. Soil Type Selector Card
                  _buildSoilTypeCard(langCode),

                  const SizedBox(height: 16),

                  // 3. Chemical Fertility Sliders (NPK & pH & OC)
                  _buildFertilityCard(langCode, soilCurrent),

                  const SizedBox(height: 16),

                  // 4. Physical Soil Properties (Moisture & Drainage)
                  _buildPhysicalPropertiesCard(langCode),

                  const SizedBox(height: 16),

                  // 5. ICAR Agronomic Advisory Card
                  _buildAdvisoryCard(langCode, soilCurrent),

                  const SizedBox(height: 24),

                  // 6. Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSoilProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            langCode == 'gu'
                                ? 'જમીન પ્રોફાઇલ સાચવો'
                                : (langCode == 'hi'
                                      ? 'मृदा प्रोफ़ाइल सहेजें'
                                      : 'Save Farm Soil Profile'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildVerificationBanner(String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isLabVerified
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLabVerified
              ? const Color(0xFF81C784)
              : const Color(0xFFFFD54F),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLabVerified
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: _isLabVerified
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLabVerified
                      ? (langCode == 'gu'
                            ? 'પ્રયોગશાળા દ્વારા પ્રમાણિત રિપોર્ટ'
                            : 'Lab-Verified Soil Test Report')
                      : (langCode == 'gu'
                            ? 'અંદાજિત કૃષિ ડેટા (ICAR બેન્ચમાર્ક)'
                            : 'Estimated Agro-Climatic Benchmark'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isLabVerified
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
              Switch.adaptive(
                value: _isLabVerified,
                activeTrackColor: const Color(0xFF2E7D32),
                onChanged: (val) {
                  setState(() {
                    _isLabVerified = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isLabVerified
                ? 'Data sourced from Soil Health Card testing laboratory.'
                : 'Values are estimated based on ${widget.profile.effectiveDistrict}, ${widget.profile.effectiveState} regional soil benchmarks. Switch to Lab Verified if you have a Soil Health Card.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
          ),
          if (_isLabVerified) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _reportIdController,
              decoration: InputDecoration(
                labelText: 'Soil Health Card / Lab Sample ID',
                hintText: 'e.g. SHC/2026/GJ-AMR/4982',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoilTypeCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.landscape_rounded, color: Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                langCode == 'gu' ? 'જમીનનો પ્રકાર' : 'Farm Soil Classification',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SoilType.values.map((type) {
              final isSelected = _selectedSoilType == type;
              return ChoiceChip(
                label: Text(
                  type.getLocalizedName(langCode),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF333333),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF1B5E20),
                backgroundColor: const Color(0xFFF1F4F1),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSoilType = type;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilityCard(String langCode, SoilProfile soil) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.science_rounded, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Text(
                    langCode == 'gu'
                        ? 'રાસાયણિક પોષક તત્વો (NPK & pH)'
                        : 'Chemical Nutrient Profile',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Health: ${soil.soilHealthScore}/100',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // pH Slider
          _buildSliderRow(
            title: 'Soil pH (Reaction)',
            valueText: _pH.toStringAsFixed(1),
            value: _pH,
            min: 5.0,
            max: 9.5,
            divisions: 45,
            levelDesc: _pH < 6.5
                ? 'Acidic'
                : (_pH <= 7.8 ? 'Neutral / Optimal' : 'Alkaline'),
            onChanged: (val) => setState(() => _pH = val),
          ),

          const Divider(height: 24),

          // Nitrogen (N)
          _buildSliderRow(
            title: 'Available Nitrogen (N)',
            valueText: '${_nitrogen.toStringAsFixed(0)} kg/ha',
            value: _nitrogen,
            min: 100.0,
            max: 700.0,
            divisions: 60,
            levelDesc: soil.nitrogenLevel,
            onChanged: (val) => setState(() => _nitrogen = val),
          ),

          const Divider(height: 24),

          // Phosphorus (P)
          _buildSliderRow(
            title: 'Available Phosphorus (P₂O₅)',
            valueText: '${_phosphorus.toStringAsFixed(1)} kg/ha',
            value: _phosphorus,
            min: 5.0,
            max: 60.0,
            divisions: 55,
            levelDesc: soil.phosphorusLevel,
            onChanged: (val) => setState(() => _phosphorus = val),
          ),

          const Divider(height: 24),

          // Potassium (K)
          _buildSliderRow(
            title: 'Available Potassium (K₂O)',
            valueText: '${_potassium.toStringAsFixed(0)} kg/ha',
            value: _potassium,
            min: 80.0,
            max: 500.0,
            divisions: 42,
            levelDesc: soil.potassiumLevel,
            onChanged: (val) => setState(() => _potassium = val),
          ),

          const Divider(height: 24),

          // Organic Carbon (OC)
          _buildSliderRow(
            title: 'Organic Carbon (OC)',
            valueText: '${_organicCarbon.toStringAsFixed(2)} %',
            value: _organicCarbon,
            min: 0.10,
            max: 1.50,
            divisions: 28,
            levelDesc: soil.organicCarbonLevel,
            onChanged: (val) => setState(() => _organicCarbon = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String levelDesc,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($levelDesc)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E7D32),
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: const Color(0xFF1B5E20),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalPropertiesCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(Icons.water_drop_outlined, color: Color(0xFF0288D1)),
              SizedBox(width: 8),
              Text(
                'Physical Properties & Drainage',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soil Moisture',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _soilMoisture,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _soilMoisture = val);
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
                      'Drainage Capacity',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _drainageCapacity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Well-drained',
                          child: Text('Well-drained'),
                        ),
                        DropdownMenuItem(
                          value: 'Moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'Poor / Waterlogged',
                          child: Text('Poor'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _drainageCapacity = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(String langCode, SoilProfile soil) {
    final advisories = SoilAnalysisService.instance.getNutrientAdvisory(
      profile: soil,
      langCode: langCode,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAED581)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'ICAR Soil Health Recommendations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...advisories.map(
            (adv) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌿 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      adv,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Color(0xFF2E7D32),
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
