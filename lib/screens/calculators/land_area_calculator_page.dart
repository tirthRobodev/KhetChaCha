import 'package:flutter/material.dart';

import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class LandAreaCalculatorPage extends StatefulWidget {
  const LandAreaCalculatorPage({super.key});

  @override
  State<LandAreaCalculatorPage> createState() => _LandAreaCalculatorPageState();
}

class _LandAreaCalculatorPageState extends State<LandAreaCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Direct Unit Conversion Tab
  final _inputController = TextEditingController(text: '1.0');
  String _selectedFromUnit = 'Acre';
  double _bighaPerAcre =
      1.6; // Default Gujarat standard: 1 Acre = 1.6 Bigha (or 2.5 Kaccha)
  LandAreaResult? _unitResult;

  // Length x Width Dimensions Tab
  final _lengthController = TextEditingController(text: '200');
  final _widthController = TextEditingController(text: '217.8');
  bool _isDimensionsInMeters = false; // default Feet
  LandAreaResult? _dimResult;

  String? _errorMsg;

  final Map<String, double> _bighaPresets = {
    'Gujarat / Saurashtra (1 Acre = 1.6 Bigha)': 1.6,
    'Gujarat / Rajasthan Kaccha (1 Acre = 2.5 Bigha)': 2.5,
    'UP / Haryana / Punjab (1 Acre = 4.8 Bigha)': 4.8,
    'Bihar / Bengal (1 Acre = 3.025 Bigha)': 3.025,
    'Madhya Pradesh (1 Acre = 1.75 Bigha)': 1.75,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateUnitConversion();
    _calculateDimensions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _calculateUnitConversion() {
    final val = double.tryParse(_inputController.text.trim());
    if (val == null || val <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid area (> 0).';
        _unitResult = null;
      });
      return;
    }
    setState(() {
      _errorMsg = null;
      _unitResult = AgricultureCalculatorService.calculateLandArea(
        value: val,
        fromUnit: _selectedFromUnit,
        bighaPerAcre: _bighaPerAcre,
      );
    });
  }

  void _calculateDimensions() {
    final length = double.tryParse(_lengthController.text.trim());
    final width = double.tryParse(_widthController.text.trim());
    if (length == null || length <= 0 || width == null || width <= 0) {
      setState(() {
        _dimResult = null;
      });
      return;
    }
    setState(() {
      _dimResult = AgricultureCalculatorService.calculateFromDimensions(
        length: length,
        width: width,
        isMeters: _isDimensionsInMeters,
        bighaPerAcre: _bighaPerAcre,
      );
    });
  }

  void _reset() {
    setState(() {
      _inputController.text = '1.0';
      _lengthController.text = '200';
      _widthController.text = '217.8';
      _selectedFromUnit = 'Acre';
      _bighaPerAcre = 1.6;
      _isDimensionsInMeters = false;
      _errorMsg = null;
    });
    _calculateUnitConversion();
    _calculateDimensions();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('land_calc_name', langCode),
      subtitle: CalculatorLocalization.t('land_calc_desc', langCode),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1B5E20),
              unselectedLabelColor: const Color(0xFF757575),
              indicatorColor: const Color(0xFF1B5E20),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.sync_alt_rounded),
                  text: 'Unit Conversion / રૂપાંતરણ',
                ),
                Tab(
                  icon: Icon(Icons.straighten_rounded),
                  text: 'Length × Width / લંબાઈ × પહોળાઈ',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUnitConversionTab(langCode),
                _buildDimensionsTab(langCode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBighaConfigSection(String langCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: Color(0xFFE65100)),
              SizedBox(width: 6),
              Text(
                'Regional Bigha Standard / પ્રાદેશિક વીઘા માપ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            initialValue: _bighaPerAcre,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            items: _bighaPresets.entries.map((e) {
              return DropdownMenuItem(
                value: e.value,
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _bighaPerAcre = val);
                _calculateUnitConversion();
                _calculateDimensions();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitConversionTab(String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBighaConfigSection(langCode),
          const SizedBox(height: 14),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CalculatorInputField(
                          label: 'Enter Land Area / જમીનનું માપ',
                          controller: _inputController,
                          prefixIcon: Icons.square_foot_rounded,
                          onChanged: (_) => _calculateUnitConversion(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From Unit / એકમ',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedFromUnit,
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
                                        'Sqft',
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
                                  setState(() => _selectedFromUnit = u);
                                  _calculateUnitConversion();
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

          CalculatorActionButtons(
            onCalculate: _calculateUnitConversion,
            onReset: _reset,
          ),

          if (_unitResult != null) ...[
            const SizedBox(height: 8),
            _buildResultGrid(_unitResult!),
            CalculationBreakdownCard(
              formula:
                  '1 Acre = 40 Guntha = 43,560 Sq.Ft = 4,046.86 Sq.M = $_bighaPerAcre Bigha',
              steps: [
                'Input: ${_inputController.text} $_selectedFromUnit converts to ${_unitResult!.acres.toStringAsFixed(3)} Acres.',
                'Hectares: 1 Hectare = 2.471 Acres. Equivalent to ${_unitResult!.hectares.toStringAsFixed(3)} Hectares.',
                'Guntha: 1 Acre = 40 Guntha (1 Guntha = 1,089 Sq.Ft). Equivalent to ${_unitResult!.guntha.toStringAsFixed(2)} Guntha.',
                'Bigha: Based on your selected regional factor ($_bighaPerAcre Bigha/Acre), this is ${_unitResult!.bigha.toStringAsFixed(2)} Bigha.',
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDimensionsTab(String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBighaConfigSection(langCode),
          const SizedBox(height: 14),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plot Dimensions / ખેતરની લંબાઈ-પહોળાઈ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Feet / ફૂટ'),
                            selected: !_isDimensionsInMeters,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _isDimensionsInMeters = false);
                                _calculateDimensions();
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Meters / મીટર'),
                            selected: _isDimensionsInMeters,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _isDimensionsInMeters = true);
                                _calculateDimensions();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CalculatorInputField(
                          label: 'Length / લંબાઈ',
                          controller: _lengthController,
                          prefixIcon: Icons.straighten_rounded,
                          suffixText: _isDimensionsInMeters ? 'm' : 'ft',
                          onChanged: (_) => _calculateDimensions(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CalculatorInputField(
                          label: 'Width / પહોળાઈ',
                          controller: _widthController,
                          prefixIcon: Icons.straighten_rounded,
                          suffixText: _isDimensionsInMeters ? 'm' : 'ft',
                          onChanged: (_) => _calculateDimensions(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          CalculatorActionButtons(
            onCalculate: _calculateDimensions,
            onReset: _reset,
          ),

          if (_dimResult != null) ...[
            const SizedBox(height: 8),
            _buildResultGrid(_dimResult!),
            CalculationBreakdownCard(
              formula: 'Total Area = Length × Width',
              steps: [
                'Dimensions: ${_lengthController.text} × ${_widthController.text} ${_isDimensionsInMeters ? "Meters" : "Feet"}',
                'Square Area: ${_dimResult!.sqft.toStringAsFixed(1)} Sq.Ft (${_dimResult!.sqm.toStringAsFixed(1)} Sq.Meters)',
                'Converted: ${_dimResult!.acres.toStringAsFixed(3)} Acres = ${_dimResult!.guntha.toStringAsFixed(2)} Guntha = ${_dimResult!.bigha.toStringAsFixed(2)} Bigha.',
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultGrid(LandAreaResult res) {
    return Container(
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
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFFFFD54F),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'All Equivalent Units / તમામ માપ પરિણામ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                ResultMetricBox(
                  label: 'Acre / એકર',
                  value: CalculatorLocalization.formatNumber(
                    res.acres,
                    maxDecimals: 3,
                  ),
                  unit: 'Acres',
                  color: const Color(0xFF1B5E20),
                ),
                ResultMetricBox(
                  label: 'Bigha / વીઘા',
                  value: CalculatorLocalization.formatNumber(
                    res.bigha,
                    maxDecimals: 2,
                  ),
                  unit: 'Bigha',
                  color: const Color(0xFFE65100),
                ),
                ResultMetricBox(
                  label: 'Guntha / ગૂંઠા',
                  value: CalculatorLocalization.formatNumber(
                    res.guntha,
                    maxDecimals: 2,
                  ),
                  unit: 'Guntha',
                  color: const Color(0xFF0277BD),
                ),
                ResultMetricBox(
                  label: 'Hectare / હેક્ટર',
                  value: CalculatorLocalization.formatNumber(
                    res.hectares,
                    maxDecimals: 3,
                  ),
                  unit: 'Ha',
                  color: const Color(0xFF558B2F),
                ),
                ResultMetricBox(
                  label: 'Sq. Feet / ચો.ફૂટ',
                  value: CalculatorLocalization.formatNumber(
                    res.sqft,
                    maxDecimals: 0,
                  ),
                  unit: 'Sq.Ft',
                  color: const Color(0xFF6A1B9A),
                ),
                ResultMetricBox(
                  label: 'Sq. Metre / ચો.મીટર',
                  value: CalculatorLocalization.formatNumber(
                    res.sqm,
                    maxDecimals: 1,
                  ),
                  unit: 'Sq.M',
                  color: const Color(0xFF00695C),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
