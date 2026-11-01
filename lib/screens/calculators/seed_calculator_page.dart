import 'package:flutter/material.dart';
import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class SeedCalculatorPage extends StatefulWidget {
  const SeedCalculatorPage({super.key});

  @override
  State<SeedCalculatorPage> createState() => _SeedCalculatorPageState();
}

class _SeedCalculatorPageState extends State<SeedCalculatorPage> {
  final _areaController = TextEditingController(text: '2.0');
  final _seedRateController = TextEditingController(text: '20.0');
  final _bufferController = TextEditingController(text: '5.0');
  final _packetSizeController = TextEditingController(text: '10.0');

  String _areaUnit = 'Acre';
  String _selectedCrop = 'Wheat / ઘઉં / गेहूं';
  SeedResult? _result;
  String? _errorMsg;

  final List<String> _crops = [
    'Wheat / ઘઉં / गेहूं',
    'Paddy (Rice) / ડાંગર / धान',
    'Cotton / કપાસ / कपास',
    'Groundnut / મગફળી / मूंगफली',
    'Gram (Chana) / ચણા / चना',
    'Mustard / રાયડો / सरसों',
    'Soybean / સોયાબીન / सोयाबीन',
    'Bajra (Pearl Millet) / બાજરી / बाजरा',
    'Custom Crop / અન્ય પાક',
  ];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _seedRateController.dispose();
    _bufferController.dispose();
    _packetSizeController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);

    final area = double.tryParse(_areaController.text.trim());
    final rate = double.tryParse(_seedRateController.text.trim());
    final buffer = double.tryParse(_bufferController.text.trim()) ?? 0.0;

    if (area == null || area <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid field area (> 0).';
        _result = null;
      });
      return;
    }

    if (rate == null || rate <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid seed rate in kg/acre (> 0).';
        _result = null;
      });
      return;
    }

    final res = AgricultureCalculatorService.calculateSeed(
      area: area,
      areaUnit: _areaUnit,
      seedRatePerAcre: rate,
      extraBufferPercent: buffer,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _areaController.text = '2.0';
      _seedRateController.text = '20.0';
      _bufferController.text = '5.0';
      _packetSizeController.text = '10.0';
      _areaUnit = 'Acre';
      _selectedCrop = _crops.first;
      _errorMsg = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final packetSize = double.tryParse(_packetSizeController.text.trim()) ?? 10.0;
    final packetsNeeded = (_result != null && packetSize > 0) ? (_result!.totalKg / packetSize).ceil() : 0;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('seed_calc_name', langCode),
      subtitle: CalculatorLocalization.t('seed_calc_desc', langCode),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCrop,
                      decoration: InputDecoration(
                        labelText: CalculatorLocalization.t('crop_selection', langCode),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F1),
                      ),
                      items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (c) {
                        if (c != null) setState(() => _selectedCrop = c);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t('field_area', langCode),
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
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _areaUnit,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: ['Acre', 'Hectare', 'Bigha', 'Guntha'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
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
                            label: CalculatorLocalization.t('seed_rate', langCode),
                            controller: _seedRateController,
                            prefixIcon: Icons.grain_rounded,
                            suffixText: 'kg/ac',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: CalculatorLocalization.t('seed_buffer', langCode),
                            controller: _bufferController,
                            prefixIcon: Icons.add_circle_outline_rounded,
                            suffixText: '%',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    CalculatorInputField(
                      label: 'Packet / Bag Size (kg)',
                      controller: _packetSizeController,
                      prefixIcon: Icons.inventory_2_outlined,
                      suffixText: 'kg/bag',
                      onChanged: (_) => setState(() {}),
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
                        color: Color(0xFF1B5E20),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFFD54F), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            CalculatorLocalization.t('results_title', langCode),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                            label: 'Total Seed (with Buffer)',
                            value: CalculatorLocalization.formatNumber(_result!.totalKg),
                            unit: 'kg',
                            color: const Color(0xFF1B5E20),
                            icon: Icons.grain_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Base Seed Requirement',
                            value: CalculatorLocalization.formatNumber(_result!.baseKg),
                            unit: 'kg',
                            color: const Color(0xFFE65100),
                            icon: Icons.scale_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Extra Buffer Quantity',
                            value: '+${CalculatorLocalization.formatNumber(_result!.bufferKg)}',
                            unit: 'kg (${_result!.bufferPercent.toStringAsFixed(0)}%)',
                            color: const Color(0xFF0277BD),
                            icon: Icons.shield_outlined,
                          ),
                          ResultMetricBox(
                            label: 'Packets to Buy',
                            value: '$packetsNeeded',
                            unit: 'bags (${packetSize.toStringAsFixed(0)}kg)',
                            color: const Color(0xFF558B2F),
                            icon: Icons.shopping_bag_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: 'Total Seed (kg) = (Field Area in Acres × Seed Rate) × (1 + Buffer% / 100)',
                steps: [
                  'Area: ${_areaController.text} $_areaUnit = ${_result!.acres.toStringAsFixed(2)} Acres.',
                  'Base Requirement: ${_result!.acres.toStringAsFixed(2)} × ${_seedRateController.text} = ${_result!.baseKg.toStringAsFixed(2)} kg.',
                  'Buffer: +${_result!.bufferPercent.toStringAsFixed(0)}% safety reserve for germination loss = +${_result!.bufferKg.toStringAsFixed(2)} kg.',
                  'Final Purchase Recommendation: ${_result!.totalKg.toStringAsFixed(2)} kg (Buy $packetsNeeded bags of ${packetSize.toStringAsFixed(0)} kg).',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
