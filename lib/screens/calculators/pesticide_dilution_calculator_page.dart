import 'package:flutter/material.dart';
import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class PesticideDilutionCalculatorPage extends StatefulWidget {
  const PesticideDilutionCalculatorPage({super.key});

  @override
  State<PesticideDilutionCalculatorPage> createState() => _PesticideDilutionCalculatorPageState();
}

class _PesticideDilutionCalculatorPageState extends State<PesticideDilutionCalculatorPage> {
  final _tankCapacityController = TextEditingController(text: '16.0'); // Standard 16L knapsack
  final _dosageController = TextEditingController(text: '2.5'); // 2.5 ml/L
  final _tankCountController = TextEditingController(text: '5'); // 5 pumps

  String _doseUnit = 'ml / Litre';
  PesticideResult? _result;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _tankCapacityController.dispose();
    _dosageController.dispose();
    _tankCountController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);

    final capacity = double.tryParse(_tankCapacityController.text.trim());
    final dosage = double.tryParse(_dosageController.text.trim());
    final count = int.tryParse(_tankCountController.text.trim());

    if (capacity == null || capacity <= 0) {
      setState(() {
        _errorMsg = 'Please enter valid tank capacity in litres (> 0).';
        _result = null;
      });
      return;
    }

    if (dosage == null || dosage <= 0) {
      setState(() {
        _errorMsg = 'Please enter recommended product dosage (> 0).';
        _result = null;
      });
      return;
    }

    if (count == null || count <= 0) {
      setState(() {
        _errorMsg = 'Please enter valid number of spray tanks / pumps (>= 1).';
        _result = null;
      });
      return;
    }

    final res = AgricultureCalculatorService.calculatePesticide(
      tankCapacityLitres: capacity,
      dosePerLitre: dosage,
      doseUnit: _doseUnit.contains('gram') ? 'g' : 'ml',
      numberOfTanks: count,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _tankCapacityController.text = '16.0';
      _dosageController.text = '2.5';
      _tankCountController.text = '5';
      _doseUnit = 'ml / Litre';
      _errorMsg = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('pesticide_calc_name', langCode),
      subtitle: CalculatorLocalization.t('pesticide_calc_desc', langCode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t('tank_capacity', langCode),
                            controller: _tankCapacityController,
                            prefixIcon: Icons.propane_tank_rounded,
                            suffixText: 'Litres',
                            hint: '16',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t('number_of_tanks', langCode),
                            controller: _tankCountController,
                            prefixIcon: Icons.format_list_numbered_rounded,
                            suffixText: 'Tanks',
                            isDecimal: false,
                            hint: '5',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t('dose_per_litre', langCode),
                            controller: _dosageController,
                            prefixIcon: Icons.science_rounded,
                            hint: '2.5',
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
                                'Dosage Unit',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _doseUnit,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: ['ml / Litre', 'gram / Litre'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (u) {
                                  if (u != null) {
                                    setState(() => _doseUnit = u);
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
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            CalculatorActionButtons(onCalculate: _calculate, onReset: _reset),

            if (_result != null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6A1B9A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.science_rounded, color: Color(0xFFFFD54F), size: 20),
                          SizedBox(width: 8),
                          Text('Mixing Ratio / મિશ્રણ પ્રમાણ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
                            label: 'Chemical per Tank / પંપ',
                            value: CalculatorLocalization.formatNumber(_result!.productPerTank),
                            unit: _result!.doseUnit,
                            color: const Color(0xFF6A1B9A),
                            icon: Icons.science_outlined,
                          ),
                          ResultMetricBox(
                            label: 'Total Chemical Needed',
                            value: _result!.totalProduct >= 1000
                                ? '${(_result!.totalProduct / 1000).toStringAsFixed(2)} ${_result!.doseUnit == "ml" ? "L" : "kg"}'
                                : '${CalculatorLocalization.formatNumber(_result!.totalProduct)} ${_result!.doseUnit}',
                            color: const Color(0xFFC62828),
                            icon: Icons.inventory_2_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Total Spray Solution',
                            value: _result!.totalSpraySolutionLitres.toStringAsFixed(0),
                            unit: 'Litres Water',
                            color: const Color(0xFF0277BD),
                            icon: Icons.water_drop_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Tanks to Prepare',
                            value: _result!.numberOfTanks.toString(),
                            unit: 'Pumps (${_result!.tankCapacityLitres.toStringAsFixed(0)}L)',
                            color: const Color(0xFF2E7D32),
                            icon: Icons.done_all_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Safety Alert
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CalculatorLocalization.t('pesticide_warning', langCode),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: 'Product per Tank = Tank Capacity (L) × Dose per Litre',
                steps: [
                  'Per Tank Dose: ${_result!.tankCapacityLitres.toStringAsFixed(0)} L × ${_result!.dosePerLitre} ${_result!.doseUnit}/L = ${_result!.productPerTank.toStringAsFixed(1)} ${_result!.doseUnit} of chemical per tank.',
                  'For ${_result!.numberOfTanks} Tanks: ${_result!.numberOfTanks} × ${_result!.productPerTank.toStringAsFixed(1)} ${_result!.doseUnit} = ${_result!.totalProduct.toStringAsFixed(1)} ${_result!.doseUnit} total product.',
                  'Total Water Requirement: ${_result!.totalSpraySolutionLitres.toStringAsFixed(0)} Litres.',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
