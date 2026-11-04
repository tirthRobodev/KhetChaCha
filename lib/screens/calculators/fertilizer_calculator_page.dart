import 'package:flutter/material.dart';

import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class FertilizerCalculatorPage extends StatefulWidget {
  const FertilizerCalculatorPage({super.key});

  @override
  State<FertilizerCalculatorPage> createState() =>
      _FertilizerCalculatorPageState();
}

class _FertilizerCalculatorPageState extends State<FertilizerCalculatorPage> {
  final _areaController = TextEditingController(text: '1.0');
  final _doseController = TextEditingController(text: '45.0');
  final _bagWeightController = TextEditingController(text: '50.0');

  String _areaUnit = 'Acre';
  String _doseUnit = 'kg/Acre';
  String _selectedCrop = 'Wheat / ઘઉં / गेहूं';
  String _fertilizerType = 'Urea (46% N)';
  String _growthStage = 'Basal / પાયાનું ખાતર / बुवाई समय';

  FertilizerResult? _result;
  String? _validationError;

  final List<String> _areaUnits = ['Acre', 'Hectare', 'Bigha', 'Guntha'];
  final List<String> _fertilizerTypes = [
    'Urea (46% N)',
    'DAP (18% N, 46% P₂O₅)',
    'MOP (60% K₂O)',
    'NPK 10:26:26',
    'NPK 12:32:16',
    'SSP (16% P₂O₅)',
    'Custom / અન્ય',
  ];

  final List<String> _crops = [
    'Wheat / ઘઉં / गेहूं',
    'Paddy (Rice) / ડાંગર / धान',
    'Cotton / કપાસ / कपास',
    'Groundnut / મગફળી / मूंगफली',
    'Sugarcane / શેરડી / गन्ना',
    'Maize (Corn) / મકાઈ / मक्का',
    'Potato / બટાટા / आलू',
    'Mustard / રાયડો / सरसों',
    'Soybean / સોયાબીન / सोयाबीन',
  ];

  final List<String> _stages = [
    'Basal / પાયાનું ખાતર / बुवाई समय',
    'Vegetative / વૃદ્ધિ સમય / वानस्पतिक अवस्था',
    'Flowering / ફૂલ બેસવાનો સમય / फूल आने पर',
    'Grain Filling / દાણા ભરાવાના સમય / दाना भराव',
  ];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _doseController.dispose();
    _bagWeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _validationError = null;
    });

    final area = double.tryParse(_areaController.text.trim());
    final dose = double.tryParse(_doseController.text.trim());
    final bagWeight = double.tryParse(_bagWeightController.text.trim()) ?? 50.0;

    if (area == null || area <= 0) {
      setState(() {
        _validationError = 'Please enter a valid field area (> 0).';
        _result = null;
      });
      return;
    }

    if (dose == null || dose <= 0) {
      setState(() {
        _validationError =
            'Please enter a valid fertilizer dose in kg/acre (> 0).';
        _result = null;
      });
      return;
    }

    if (bagWeight <= 0) {
      setState(() {
        _validationError = 'Bag weight must be greater than zero.';
        _result = null;
      });
      return;
    }

    final res = AgricultureCalculatorService.calculateFertilizer(
      area: area,
      areaUnit: _areaUnit,
      crop: _selectedCrop,
      fertilizerType: _fertilizerType,
      doseKgPerAcre: _doseUnit == 'kg/Bigha' ? dose * 1.6 : dose,
      dosePerSelectedUnit: _doseUnit == 'kg/Bigha'
          ? dose
          : (_areaUnit == 'Bigha' ? dose / 1.6 : dose),
      doseUnit: _doseUnit == 'kg/Bigha' ? 'per_bigha' : 'per_acre',
      bagWeightKg: bagWeight,
      bighaPerAcre: 1.6,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _areaController.text = '1.0';
      _doseController.text = '45.0';
      _bagWeightController.text = '45.0';
      _areaUnit = 'Acre';
      _doseUnit = 'kg/Acre';
      _selectedCrop = _crops.first;
      _fertilizerType = _fertilizerTypes.first;
      _validationError = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('fertilizer_calc_name', langCode),
      subtitle: CalculatorLocalization.t('fertilizer_calc_desc', langCode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crop & Stage Selection
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.grass_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Crop & Stage / પાક અને અવસ્થા',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1B5E20),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCrop,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: CalculatorLocalization.t(
                          'crop_selection',
                          langCode,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F1),
                      ),
                      items: _crops
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCrop = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _growthStage,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: CalculatorLocalization.t(
                          'growth_stage',
                          langCode,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F1),
                      ),
                      items: _stages
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _growthStage = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Field Area and Units
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t(
                              'field_area',
                              langCode,
                            ),
                            controller: _areaController,
                            prefixIcon: Icons.landscape_rounded,
                            hint: 'e.g. 2.5',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CalculatorLocalization.t('area_unit', langCode),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _areaUnit,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: _areaUnits
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (u) {
                                  if (u != null) {
                                    setState(() {
                                      _areaUnit = u;
                                      if (u == 'Bigha') {
                                        _doseUnit = 'kg/Bigha';
                                      } else if (u == 'Acre') {
                                        _doseUnit = 'kg/Acre';
                                      }
                                    });
                                    _calculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Fertilizer Type & Dose
                    DropdownButtonFormField<String>(
                      initialValue: _fertilizerType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: CalculatorLocalization.t(
                          'fertilizer_type',
                          langCode,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F1),
                      ),
                      items: _fertilizerTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (t) {
                        if (t != null) {
                          setState(() {
                            _fertilizerType = t;
                            if (t.toLowerCase().contains('urea') ||
                                t.toLowerCase().contains('યુરિયા') ||
                                t.toLowerCase().contains('यूरिया')) {
                              _bagWeightController.text = '45.0';
                            } else {
                              _bagWeightController.text = '50.0';
                            }
                          });
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CalculatorInputField(
                            label: _doseUnit == 'kg/Bigha'
                                ? (langCode == 'gu'
                                      ? 'ખાતર દર (કિગ્રા/વીઘા)'
                                      : (langCode == 'hi'
                                            ? 'खाद मात्रा (किग्रा/बीघा)'
                                            : 'Dose (kg/Bigha)'))
                                : CalculatorLocalization.t(
                                    'dose_required',
                                    langCode,
                                  ),
                            controller: _doseController,
                            prefixIcon: Icons.scale_rounded,
                            suffixText: _doseUnit == 'kg/Bigha'
                                ? (langCode == 'gu'
                                      ? 'કિગ્રા/વીઘા'
                                      : 'kg/bigha')
                                : (langCode == 'gu' ? 'કિગ્રા/એકર' : 'kg/ac'),
                            hint: _doseUnit == 'kg/Bigha' ? '28' : '45',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langCode == 'gu'
                                    ? 'માત્રા દર'
                                    : (langCode == 'hi'
                                          ? 'खुराक इकाई'
                                          : 'Dose Rate'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _doseUnit,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'kg/Acre',
                                    child: Text(
                                      langCode == 'gu'
                                          ? 'કિગ્રા/એકર'
                                          : (langCode == 'hi'
                                                ? 'किग्रा/एकड़'
                                                : 'kg/Acre'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'kg/Bigha',
                                    child: Text(
                                      langCode == 'gu'
                                          ? 'કિગ્રા/વીઘા'
                                          : (langCode == 'hi'
                                                ? 'किग्रा/बीघा'
                                                : 'kg/Bigha'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                                onChanged: (u) {
                                  if (u != null) {
                                    setState(() {
                                      _doseUnit = u;
                                      if (u == 'kg/Bigha' &&
                                          _doseController.text == '45.0') {
                                        _doseController.text = '28.0';
                                      } else if (u == 'kg/Acre' &&
                                          _doseController.text == '28.0') {
                                        _doseController.text = '45.0';
                                      }
                                    });
                                    _calculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CalculatorInputField(
                      label: CalculatorLocalization.t('bag_weight', langCode),
                      controller: _bagWeightController,
                      prefixIcon: Icons.shopping_bag_outlined,
                      suffixText: 'kg',
                      hint: _fertilizerType.toLowerCase().contains('urea')
                          ? '45'
                          : '50',
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ),
            ),

            if (_validationError != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFC62828),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            CalculatorActionButtons(onCalculate: _calculate, onReset: _reset),

            if (_result != null) ...[
              const SizedBox(height: 8),
              // Main Output Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF81C784),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B5E20),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFFFFD54F),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              CalculatorLocalization.t(
                                'results_title',
                                langCode,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: [
                              ResultMetricBox(
                                label: CalculatorLocalization.t(
                                  'total_fertilizer',
                                  langCode,
                                ),
                                value: CalculatorLocalization.formatNumber(
                                  _result!.totalKgRequired,
                                ),
                                unit: 'kg',
                                color: const Color(0xFF1B5E20),
                                icon: Icons.scale_rounded,
                              ),
                              ResultMetricBox(
                                label: CalculatorLocalization.t(
                                  'full_bags_needed',
                                  langCode,
                                ),
                                value: '${_result!.fullBags}',
                                unit:
                                    'bags (${_result!.totalBagsDecimal.toStringAsFixed(1)})',
                                color: const Color(0xFFE65100),
                                icon: Icons.shopping_bag_rounded,
                              ),
                              ResultMetricBox(
                                label: CalculatorLocalization.t(
                                  'remaining_in_bag',
                                  langCode,
                                ),
                                value: CalculatorLocalization.formatNumber(
                                  _result!.remainingKgInFinalBag,
                                ),
                                unit: 'kg loose',
                                color: const Color(0xFF0277BD),
                                icon: Icons.inventory_2_outlined,
                              ),
                              ResultMetricBox(
                                label: _areaUnit == 'Bigha'
                                    ? CalculatorLocalization.t(
                                        'quantity_per_bigha',
                                        langCode,
                                      )
                                    : CalculatorLocalization.t(
                                        'quantity_per_acre',
                                        langCode,
                                      ),
                                value: CalculatorLocalization.formatNumber(
                                  _areaUnit == 'Bigha'
                                      ? _result!.kgPerBigha
                                      : _result!.kgPerAcre,
                                ),
                                unit: _areaUnit == 'Bigha'
                                    ? (langCode == 'gu'
                                          ? 'કિગ્રા/વીઘા'
                                          : (langCode == 'hi'
                                                ? 'किग्रा/बीघा'
                                                : 'kg/Bigha'))
                                    : 'kg/acre',
                                color: const Color(0xFF558B2F),
                                icon: Icons.straighten_rounded,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _areaUnit == 'Bigha'
                                      ? (langCode == 'gu'
                                            ? 'એકર દીઠ સમકક્ષ: ${_result!.kgPerAcre.toStringAsFixed(1)} કિગ્રા/એકર'
                                            : (langCode == 'hi'
                                                  ? 'एकड़ समतुल्य: ${_result!.kgPerAcre.toStringAsFixed(1)} किग्रा/एकड़'
                                                  : 'Acre Equivalent: ${_result!.kgPerAcre.toStringAsFixed(1)} kg/acre'))
                                      : (langCode == 'gu'
                                            ? 'વીઘા દીઠ સમકક્ષ: ${_result!.kgPerBigha.toStringAsFixed(1)} કિગ્રા/વીઘા'
                                            : (langCode == 'hi'
                                                  ? 'બીघा समतुल्य: ${_result!.kgPerBigha.toStringAsFixed(1)} किग्रा/बीघा'
                                                  : 'Bigha Equivalent: ${_result!.kgPerBigha.toStringAsFixed(1)} kg/Bigha')),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                Text(
                                  langCode == 'gu'
                                      ? 'બેગ: ${_result!.bagWeightKg.toStringAsFixed(0)} કિગ્રા'
                                      : (langCode == 'hi'
                                            ? 'बोरी: ${_result!.bagWeightKg.toStringAsFixed(0)} किग्रा'
                                            : 'Bag: ${_result!.bagWeightKg.toStringAsFixed(0)} kg'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_result!.suppliedN > 0 ||
                              _result!.suppliedP > 0 ||
                              _result!.suppliedK > 0) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC8E6C9),
                                ),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    'Pure N: ${_result!.suppliedN.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  Text(
                                    'Pure P₂O₅: ${_result!.suppliedP.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                  Text(
                                    'Pure K₂O: ${_result!.suppliedK.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF0277BD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: _areaUnit == 'Bigha'
                    ? 'Total Fertilizer = Field Area (Bigha) × Dose (kg/Bigha)'
                    : 'Total Fertilizer = Field Area (Acres) × Recommended Dose (kg/acre)',
                steps: [
                  _areaUnit == 'Bigha'
                      ? 'Selected Area: ${_areaController.text} Bigha (${_result!.acres.toStringAsFixed(2)} Acres)'
                      : 'Selected Area: ${_areaController.text} $_areaUnit (${_result!.acres.toStringAsFixed(2)} Acres)',
                  _areaUnit == 'Bigha'
                      ? 'Recommended Application: ${_result!.kgPerBigha.toStringAsFixed(1)} kg/Bigha (${_result!.kgPerAcre.toStringAsFixed(1)} kg/acre) for $_selectedCrop at $_growthStage'
                      : 'Recommended Application: ${_result!.kgPerAcre.toStringAsFixed(1)} kg/acre (${_result!.kgPerBigha.toStringAsFixed(1)} kg/Bigha) for $_selectedCrop at $_growthStage',
                  'Total Product Needed: ${_result!.totalKgRequired.toStringAsFixed(1)} kg',
                  'Bag Calculation (${_result!.bagWeightKg.toStringAsFixed(0)} kg Bags): ${_result!.totalKgRequired.toStringAsFixed(1)} kg ÷ ${_result!.bagWeightKg.toStringAsFixed(0)} kg/bag = ${_result!.totalBagsDecimal.toStringAsFixed(2)} bags (${_result!.fullBags} full bags + ${_result!.remainingKgInFinalBag.toStringAsFixed(1)} kg loose remainder).',
                  _fertilizerType.toLowerCase().contains('urea') ||
                          _fertilizerType.toLowerCase().contains('યુરિયા') ||
                          _fertilizerType.toLowerCase().contains('यूरिया')
                      ? 'Note: Standard commercial Neem Coated Urea bag weight in India is 45 kg.'
                      : 'Note: Standard commercial DAP/MOP/NPK bag weight in India is 50 kg.',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
