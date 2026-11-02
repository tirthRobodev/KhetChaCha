import 'package:flutter/material.dart';

import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class IrrigationCalculatorPage extends StatefulWidget {
  const IrrigationCalculatorPage({super.key});

  @override
  State<IrrigationCalculatorPage> createState() =>
      _IrrigationCalculatorPageState();
}

class _IrrigationCalculatorPageState extends State<IrrigationCalculatorPage> {
  final _areaController = TextEditingController(text: '1.0');
  final _depthController = TextEditingController(
    text: '50.0',
  ); // 50 mm standard irrigation
  final _pumpDischargeController = TextEditingController(
    text: '30000',
  ); // 30,000 L/hr (~ 5 HP pump)

  String _areaUnit = 'Acre';
  double _efficiencyPercent = 75.0; // default Sprinkler / Semi-efficient
  String _irrigationMethod = 'Sprinkler (75% Efficiency)';

  IrrigationResult? _result;
  String? _errorMsg;

  final Map<String, double> _methodEfficiencies = {
    'Drip Irrigation (90% Efficiency)': 90.0,
    'Sprinkler System (75% Efficiency)': 75.0,
    'Flood / Furrow Canal (50% Efficiency)': 50.0,
    'Theoretical 100% (Zero Loss)': 100.0,
  };

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _depthController.dispose();
    _pumpDischargeController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);

    final area = double.tryParse(_areaController.text.trim());
    final depth = double.tryParse(_depthController.text.trim());
    final discharge =
        double.tryParse(_pumpDischargeController.text.trim()) ?? 30000.0;

    if (area == null || area <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid field area (> 0).';
        _result = null;
      });
      return;
    }

    if (depth == null || depth <= 0) {
      setState(() {
        _errorMsg = 'Please enter desired irrigation depth in mm (> 0).';
        _result = null;
      });
      return;
    }

    final res = AgricultureCalculatorService.calculateIrrigation(
      area: area,
      areaUnit: _areaUnit,
      depthMm: depth,
      efficiencyPercent: _efficiencyPercent,
      pumpDischargeLph: discharge,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _areaController.text = '1.0';
      _depthController.text = '50.0';
      _pumpDischargeController.text = '30000';
      _areaUnit = 'Acre';
      _efficiencyPercent = 75.0;
      _irrigationMethod = _methodEfficiencies.keys.elementAt(1);
      _errorMsg = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('irrigation_calc_name', langCode),
      subtitle: CalculatorLocalization.t('irrigation_calc_desc', langCode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                                items:
                                    [
                                          'Acre',
                                          'Hectare',
                                          'Bigha',
                                          'Guntha',
                                          'Sqm',
                                        ]
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              u,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (u) {
                                  if (u != null) {
                                    setState(() => _areaUnit = u);
                                    _calculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t(
                              'irrigation_depth',
                              langCode,
                            ),
                            controller: _depthController,
                            prefixIcon: Icons.water_drop_rounded,
                            suffixText: 'mm',
                            hint: '50',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Pump Discharge (L/hr)',
                            controller: _pumpDischargeController,
                            prefixIcon: Icons.speed_rounded,
                            suffixText: 'L/h',
                            hint: '30000',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Irrigation System Efficiency / પદ્ધતિ',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _irrigationMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F1),
                      ),
                      items: _methodEfficiencies.keys
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (m) {
                        if (m != null) {
                          setState(() {
                            _irrigationMethod = m;
                            _efficiencyPercent = _methodEfficiencies[m]!;
                          });
                          _calculate();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            CalculatorActionButtons(onCalculate: _calculate, onReset: _reset),

            if (_result != null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF81C784),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0277BD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Water Volume Required / જરૂરી પાણી',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.45,
                        children: [
                          ResultMetricBox(
                            label: 'Total Litres / લીટર',
                            value: CalculatorLocalization.formatNumber(
                              _result!.adjustedLitres,
                              maxDecimals: 0,
                            ),
                            unit: 'Litres',
                            color: const Color(0xFF0277BD),
                            icon: Icons.water_drop_outlined,
                          ),
                          ResultMetricBox(
                            label: 'Cubic Metres (m³)',
                            value: CalculatorLocalization.formatNumber(
                              _result!.adjustedCubicMeters,
                              maxDecimals: 1,
                            ),
                            unit: 'm³',
                            color: const Color(0xFF00695C),
                            icon: Icons.waves_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Pump Running Time',
                            value:
                                '${_result!.estimatedPumpHours.toStringAsFixed(1)} hrs',
                            unit: 'approx',
                            color: const Color(0xFFE65100),
                            icon: Icons.timer_outlined,
                          ),
                          ResultMetricBox(
                            label: 'Field Surface Area',
                            value: CalculatorLocalization.formatNumber(
                              _result!.areaSqm,
                              maxDecimals: 0,
                            ),
                            unit: 'm²',
                            color: const Color(0xFF1B5E20),
                            icon: Icons.square_foot_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB3E5FC)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco_rounded, color: Color(0xFF0288D1), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agronomic Notice: Actual water requirements depend on local temperature, soil type (sandy vs black cotton), root depth, and current moisture.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF01579B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: 'Water Volume (m³) = Area (m²) × Irrigation Depth (mm) ÷ 1000',
                steps: [
                  'Field Surface: ${_result!.acres.toStringAsFixed(2)} Acres = ${_result!.areaSqm.toStringAsFixed(1)} m².',
                  'Target Irrigation Depth: ${_depthController.text} mm across the whole field.',
                  'Theoretical Volume: (${_result!.areaSqm.toStringAsFixed(0)} × ${_depthController.text}) ÷ 1000 = ${_result!.theoreticalCubicMeters.toStringAsFixed(1)} m³ (${CalculatorLocalization.formatNumber(_result!.theoreticalLitres, maxDecimals: 0)} Litres).',
                  'Method Efficiency Adjusted (${_efficiencyPercent.toStringAsFixed(0)}%): ${_result!.adjustedCubicMeters.toStringAsFixed(1)} m³ (${CalculatorLocalization.formatNumber(_result!.adjustedLitres, maxDecimals: 0)} Litres).',
                  'Tubewell Runtime: Approx ${_result!.estimatedPumpHours.toStringAsFixed(1)} hours for a 5-7 HP pump delivering ${_pumpDischargeController.text} L/hr.',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
