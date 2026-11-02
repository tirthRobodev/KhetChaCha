import 'package:flutter/material.dart';

import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class CropYieldCalculatorPage extends StatefulWidget {
  const CropYieldCalculatorPage({super.key});

  @override
  State<CropYieldCalculatorPage> createState() =>
      _CropYieldCalculatorPageState();
}

class _CropYieldCalculatorPageState extends State<CropYieldCalculatorPage> {
  final _areaController = TextEditingController(text: '3.0');
  final _yieldRateController = TextEditingController(text: '16.0');

  String _areaUnit = 'Acre';
  String _yieldUnit = 'Quintal (100 kg)';
  CropYieldResult? _result;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _yieldRateController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);

    final area = double.tryParse(_areaController.text.trim());
    final rate = double.tryParse(_yieldRateController.text.trim());

    if (area == null || area <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid field area (> 0).';
        _result = null;
      });
      return;
    }

    if (rate == null || rate <= 0) {
      setState(() {
        _errorMsg = 'Please enter expected yield per unit (> 0).';
        _result = null;
      });
      return;
    }

    final res = AgricultureCalculatorService.calculateCropYield(
      area: area,
      areaUnit: _areaUnit,
      yieldRate: rate,
      yieldUnit: _yieldUnit,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _areaController.text = '3.0';
      _yieldRateController.text = '16.0';
      _areaUnit = 'Acre';
      _yieldUnit = 'Quintal (100 kg)';
      _errorMsg = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('yield_calc_name', langCode),
      subtitle: CalculatorLocalization.t('yield_calc_desc', langCode),
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
                                items: ['Acre', 'Hectare', 'Bigha', 'Guntha']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(fontSize: 13),
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
                          flex: 3,
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t(
                              'expected_yield',
                              langCode,
                            ),
                            controller: _yieldRateController,
                            prefixIcon: Icons.eco_rounded,
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yield Unit / એકમ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _yieldUnit,
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
                                          'Quintal (100 kg)',
                                          'Ton (1,000 kg)',
                                          'Kg (Kilogram)',
                                          'Mon / Maund (20 kg)',
                                        ]
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              u,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (u) {
                                  if (u != null) {
                                    setState(() => _yieldUnit = u);
                                    _calculate();
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
                        color: Color(0xFF1B5E20),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Color(0xFFFFD54F),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Harvest Estimates / અંદાજિત ઉત્પાદન',
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
                            label: 'Total Quintals / ક્વિન્ટલ',
                            value: CalculatorLocalization.formatNumber(
                              _result!.totalQuintals,
                            ),
                            unit: 'Quintals',
                            color: const Color(0xFF1B5E20),
                            icon: Icons.inventory_2_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Total Metric Tons / ટન',
                            value: CalculatorLocalization.formatNumber(
                              _result!.totalTons,
                            ),
                            unit: 'Tons',
                            color: const Color(0xFFE65100),
                            icon: Icons.local_shipping_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Maund / મણ (20 kg)',
                            value: CalculatorLocalization.formatNumber(
                              _result!.totalMon,
                            ),
                            unit: 'Mon',
                            color: const Color(0xFF0277BD),
                            icon: Icons.scale_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Yield per Hectare',
                            value: CalculatorLocalization.formatNumber(
                              _result!.yieldPerHectareQuintal,
                            ),
                            unit: 'Qtl/Ha',
                            color: const Color(0xFF558B2F),
                            icon: Icons.area_chart_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Agronomic estimation disclaimer alert
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF57F17),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimate Notice: This is an agronomic projection based on normal weather, balanced fertilization, and pest control. Actual yields depend on season rainfall, soil fertility, and seed variety.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: 'Total Harvest (Quintals) = Field Area (Acres) × Yield Rate (Quintals/Acre)',
                steps: [
                  'Normalized Field Area: ${_result!.acres.toStringAsFixed(2)} Acres.',
                  'Yield per Acre: ${_result!.yieldPerAcreQuintal.toStringAsFixed(2)} Quintals.',
                  'Harvest in Quintals: ${_result!.totalQuintals.toStringAsFixed(2)} Quintals (${_result!.totalKg.toStringAsFixed(0)} kg).',
                  'Harvest in Metric Tons: ${_result!.totalTons.toStringAsFixed(2)} Tons.',
                  'Harvest in Traditional Maund (20 kg): ${_result!.totalMon.toStringAsFixed(1)} Mon.',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
