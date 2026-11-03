import 'package:flutter/material.dart';

import '../../models/crop_recommendation.dart';
import '../../models/farmer_profile.dart';
import '../../services/crop_recommendation_service.dart';
import '../../services/language_service.dart';

/// Interactive Smart Crop Profitability & Investment Calculator.
/// Computes itemized costs, gross revenue, net profit per acre and total farm size,
/// with conservative, moderate, and optimistic sensitivity scenarios.
class SmartCropProfitCalculatorPage extends StatefulWidget {
  final FarmerProfile profile;
  final CropRecommendation? initialCrop;

  const SmartCropProfitCalculatorPage({
    super.key,
    required this.profile,
    this.initialCrop,
  });

  @override
  State<SmartCropProfitCalculatorPage> createState() =>
      _SmartCropProfitCalculatorPageState();
}

class _SmartCropProfitCalculatorPageState
    extends State<SmartCropProfitCalculatorPage> {
  late List<CropRecommendation> _availableCrops;
  late CropRecommendation _selectedCrop;

  // Farm Size
  late double _farmAcres;
  bool _isPerAcreView = false;

  // Controllers for itemized costs
  late TextEditingController _seedCtrl;
  late TextEditingController _fertCtrl;
  late TextEditingController _pestCtrl;
  late TextEditingController _labourCtrl;
  late TextEditingController _irrigCtrl;
  late TextEditingController _machCtrl;
  late TextEditingController _transCtrl;
  late TextEditingController _otherCtrl;

  // Yield & Price Controllers
  late TextEditingController _yieldCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _availableCrops = CropRecommendationService.instance.getRecommendations(widget.profile);
    _selectedCrop = widget.initialCrop ?? (_availableCrops.isNotEmpty ? _availableCrops.first : _availableCrops.first);

    double parsedAcres = double.tryParse(widget.profile.effectiveFarmSize) ?? 2.0;
    if (parsedAcres <= 0) parsedAcres = 2.0;
    _farmAcres = parsedAcres;

    _initControllersForCrop(_selectedCrop);
  }

  void _initControllersForCrop(CropRecommendation crop) {
    _seedCtrl = TextEditingController(text: crop.seedCostPerAcre.toStringAsFixed(0));
    _fertCtrl = TextEditingController(text: crop.fertilizerCostPerAcre.toStringAsFixed(0));
    _pestCtrl = TextEditingController(text: crop.pesticideCostPerAcre.toStringAsFixed(0));
    _labourCtrl = TextEditingController(text: crop.labourCostPerAcre.toStringAsFixed(0));
    _irrigCtrl = TextEditingController(text: crop.irrigationCostPerAcre.toStringAsFixed(0));
    _machCtrl = TextEditingController(text: crop.machineryCostPerAcre.toStringAsFixed(0));
    _transCtrl = TextEditingController(text: '800');
    _otherCtrl = TextEditingController(text: crop.otherCostPerAcre.toStringAsFixed(0));

    _yieldCtrl = TextEditingController(text: crop.expectedYieldQuintalsPerAcre.toStringAsFixed(1));
    _priceCtrl = TextEditingController(text: crop.mandiSellingPricePerQuintal.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _seedCtrl.dispose();
    _fertCtrl.dispose();
    _pestCtrl.dispose();
    _labourCtrl.dispose();
    _irrigCtrl.dispose();
    _machCtrl.dispose();
    _transCtrl.dispose();
    _otherCtrl.dispose();
    _yieldCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double _getVal(TextEditingController ctrl) => double.tryParse(ctrl.text.trim()) ?? 0.0;

  double get _totalCostPerAcre =>
      _getVal(_seedCtrl) +
      _getVal(_fertCtrl) +
      _getVal(_pestCtrl) +
      _getVal(_labourCtrl) +
      _getVal(_irrigCtrl) +
      _getVal(_machCtrl) +
      _getVal(_transCtrl) +
      _getVal(_otherCtrl);

  double get _yieldPerAcre => _getVal(_yieldCtrl);
  double get _sellingPrice => _getVal(_priceCtrl);

  double get _grossRevenuePerAcre => _yieldPerAcre * _sellingPrice;
  double get _netProfitPerAcre => _grossRevenuePerAcre - _totalCostPerAcre;

  double get _effectiveMultiplier => _isPerAcreView ? 1.0 : (_farmAcres > 0 ? _farmAcres : 1.0);

  double get _displayTotalCost => _totalCostPerAcre * _effectiveMultiplier;
  double get _displayGrossRevenue => _grossRevenuePerAcre * _effectiveMultiplier;
  double get _displayNetProfit => _netProfitPerAcre * _effectiveMultiplier;
  double get _displayProduction => _yieldPerAcre * _effectiveMultiplier;

  double get _breakEvenPrice => _yieldPerAcre > 0 ? _totalCostPerAcre / _yieldPerAcre : 0.0;

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'પાક નફાકારકતા કેલ્ક્યુલેટર'
              : (langCode == 'hi' ? 'फसल लाभ कैलकुलेटर' : 'Smart Crop Profit Calculator'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Crop Selector & Farm Size Header
            _buildCropSelectorCard(langCode),

            const SizedBox(height: 16),

            // 2. View Toggle (Per Acre vs Whole Farm)
            _buildViewToggleCard(langCode),

            const SizedBox(height: 16),

            // 3. Main Result Profit Banner
            _buildProfitResultsBanner(langCode),

            const SizedBox(height: 16),

            // 4. Itemized Cultivation Investment Inputs
            _buildItemizedCostCard(langCode),

            const SizedBox(height: 16),

            // 5. Yield and Mandi Selling Price Inputs
            _buildProductionInputsCard(langCode),

            const SizedBox(height: 16),

            // 6. Three Sensitivity Scenarios
            _buildSensitivityScenariosCard(langCode),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelectorCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text(
            'Select Target Crop',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<CropRecommendation>(
            initialValue: _selectedCrop,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _availableCrops.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Text(c.iconEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      c.englishName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text('(${c.season})', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newCrop) {
              if (newCrop != null) {
                setState(() {
                  _selectedCrop = newCrop;
                  _initControllersForCrop(newCrop);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleCard(String langCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.square_foot_rounded, color: Color(0xFF1B5E20), size: 20),
              const SizedBox(width: 8),
              Text(
                'Farm Size: ${_farmAcres.toStringAsFixed(1)} Acres',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Per Acre', style: TextStyle(fontSize: 11)),
                selected: _isPerAcreView,
                selectedColor: const Color(0xFF1B5E20),
                labelStyle: TextStyle(
                  color: _isPerAcreView ? Colors.white : const Color(0xFF333333),
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _isPerAcreView = true),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text('Full Farm (${_farmAcres.toStringAsFixed(0)} Ac)', style: const TextStyle(fontSize: 11)),
                selected: !_isPerAcreView,
                selectedColor: const Color(0xFF1B5E20),
                labelStyle: TextStyle(
                  color: !_isPerAcreView ? Colors.white : const Color(0xFF333333),
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _isPerAcreView = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitResultsBanner(String langCode) {
    final isProfit = _displayNetProfit >= 0;
    final scopeLabel = _isPerAcreView ? 'Per Acre' : 'Total Farm (${_farmAcres.toStringAsFixed(1)} Ac)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? const Color(0xFF1B5E20) : Colors.red).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isProfit ? 'ESTIMATED NET PROFIT ($scopeLabel)' : 'ESTIMATED NET LOSS ($scopeLabel)',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Break-even: ₹${_breakEvenPrice.toStringAsFixed(0)}/Q',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_displayNetProfit.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('Total Cost', '₹${_displayTotalCost.toStringAsFixed(0)}'),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildMiniMetric('Gross Revenue', '₹${_displayGrossRevenue.toStringAsFixed(0)}'),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildMiniMetric('Production', '${_displayProduction.toStringAsFixed(1)} Q'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildItemizedCostCard(String langCode) {
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
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: Color(0xFF1B5E20)),
                  SizedBox(width: 8),
                  Text(
                    'Itemized Cultivation Costs (₹ / Acre)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Total: ₹${_totalCostPerAcre.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTwoInputs('Seed Investment (₹)', _seedCtrl, 'Fertilizers & Manure (₹)', _fertCtrl),
          const SizedBox(height: 10),
          _buildTwoInputs('Pest & Disease Control (₹)', _pestCtrl, 'Labour & Weeding (₹)', _labourCtrl),
          const SizedBox(height: 10),
          _buildTwoInputs('Irrigation & Power (₹)', _irrigCtrl, 'Tractor & Machinery (₹)', _machCtrl),
          const SizedBox(height: 10),
          _buildTwoInputs('Transport to Mandi (₹)', _transCtrl, 'Misc / Other Costs (₹)', _otherCtrl),
        ],
      ),
    );
  }

  Widget _buildTwoInputs(String l1, TextEditingController c1, String l2, TextEditingController c2) {
    return Row(
      children: [
        Expanded(child: _buildSmallInputField(l1, c1)),
        const SizedBox(width: 10),
        Expanded(child: _buildSmallInputField(l2, c2)),
      ],
    );
  }

  Widget _buildSmallInputField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF616161))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildProductionInputsCard(String langCode) {
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
              Icon(Icons.trending_up_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Production & Mandi Selling Price',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTwoInputs(
            'Expected Yield (Quintals/Acre)',
            _yieldCtrl,
            'Mandi Selling Price (₹/Quintal)',
            _priceCtrl,
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityScenariosCard(String langCode) {
    final consYield = _yieldPerAcre * 0.85;
    final consPrice = _sellingPrice * 0.90;
    final consProfit = ((consYield * consPrice) - _totalCostPerAcre) * _effectiveMultiplier;

    final optYield = _yieldPerAcre * 1.15;
    final optPrice = _sellingPrice * 1.10;
    final optProfit = ((optYield * optPrice) - _totalCostPerAcre) * _effectiveMultiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensitivity Scenarios (Risk Tolerance)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildScenarioBox(
                  'Conservative',
                  '-15% yield, -10% price',
                  consProfit,
                  Colors.orange.shade800,
                  Colors.orange.shade50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScenarioBox(
                  'Moderate',
                  'Base benchmark',
                  _displayNetProfit,
                  const Color(0xFF1B5E20),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScenarioBox(
                  'Optimistic',
                  '+15% yield, +10% price',
                  optProfit,
                  Colors.teal.shade800,
                  Colors.teal.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioBox(String title, String desc, double amount, Color col, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
          const SizedBox(height: 2),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col),
          ),
          const SizedBox(height: 2),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF757575))),
        ],
      ),
    );
  }
}
