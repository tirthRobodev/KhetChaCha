import 'package:flutter/material.dart';
import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

class FarmCostProfitCalculatorPage extends StatefulWidget {
  const FarmCostProfitCalculatorPage({super.key});

  @override
  State<FarmCostProfitCalculatorPage> createState() => _FarmCostProfitCalculatorPageState();
}

class _FarmCostProfitCalculatorPageState extends State<FarmCostProfitCalculatorPage> {
  final _areaController = TextEditingController(text: '3.0');
  String _areaUnit = 'Acre';

  // Expense controllers
  final _seedCostController = TextEditingController(text: '4500');
  final _fertilizerCostController = TextEditingController(text: '8200');
  final _pesticideCostController = TextEditingController(text: '3500');
  final _labourCostController = TextEditingController(text: '12000');
  final _irrigationCostController = TextEditingController(text: '4000');
  final _machineryCostController = TextEditingController(text: '6500');
  final _otherCostController = TextEditingController(text: '2000');

  // Revenue controllers
  final _harvestQtyController = TextEditingController(text: '50.0'); // Quintals
  final _sellingPriceController = TextEditingController(text: '2400'); // ₹ per Quintal

  FarmCostProfitResult? _result;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _seedCostController.dispose();
    _fertilizerCostController.dispose();
    _pesticideCostController.dispose();
    _labourCostController.dispose();
    _irrigationCostController.dispose();
    _machineryCostController.dispose();
    _otherCostController.dispose();
    _harvestQtyController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);

    final area = double.tryParse(_areaController.text.trim()) ?? 0;
    if (area <= 0) {
      setState(() {
        _errorMsg = 'Please enter a valid field area (> 0).';
        _result = null;
      });
      return;
    }

    final harvest = double.tryParse(_harvestQtyController.text.trim()) ?? 0;
    final price = double.tryParse(_sellingPriceController.text.trim()) ?? 0;

    final res = AgricultureCalculatorService.calculateCostProfit(
      area: area,
      areaUnit: _areaUnit,
      seedCost: double.tryParse(_seedCostController.text.trim()) ?? 0,
      fertilizerCost: double.tryParse(_fertilizerCostController.text.trim()) ?? 0,
      pesticideCost: double.tryParse(_pesticideCostController.text.trim()) ?? 0,
      labourCost: double.tryParse(_labourCostController.text.trim()) ?? 0,
      irrigationCost: double.tryParse(_irrigationCostController.text.trim()) ?? 0,
      machineryCost: double.tryParse(_machineryCostController.text.trim()) ?? 0,
      otherExpenses: double.tryParse(_otherCostController.text.trim()) ?? 0,
      harvestQuantity: harvest,
      sellingPricePerUnit: price,
    );

    setState(() {
      _result = res;
    });
  }

  void _reset() {
    setState(() {
      _areaController.text = '3.0';
      _areaUnit = 'Acre';
      _seedCostController.text = '4500';
      _fertilizerCostController.text = '8200';
      _pesticideCostController.text = '3500';
      _labourCostController.text = '12000';
      _irrigationCostController.text = '4000';
      _machineryCostController.text = '6500';
      _otherCostController.text = '2000';
      _harvestQtyController.text = '50.0';
      _sellingPriceController.text = '2400';
      _errorMsg = null;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('cost_profit_calc_name', langCode),
      subtitle: CalculatorLocalization.t('cost_profit_calc_desc', langCode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field Area
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
              ),
            ),
            const SizedBox(height: 12),

            // All Farming Expenses Breakdown
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: Color(0xFFC62828), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Farming Expenses / ખેતી ખર્ચ (₹)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFFC62828)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Seed Cost (₹)',
                            controller: _seedCostController,
                            prefixIcon: Icons.grain_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Fertilizer Cost (₹)',
                            controller: _fertilizerCostController,
                            prefixIcon: Icons.scale_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Pesticide / Spray (₹)',
                            controller: _pesticideCostController,
                            prefixIcon: Icons.pest_control_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Labour Cost / મજૂરી (₹)',
                            controller: _labourCostController,
                            prefixIcon: Icons.groups_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Irrigation & Power (₹)',
                            controller: _irrigationCostController,
                            prefixIcon: Icons.water_drop_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Tractor / Diesel (₹)',
                            controller: _machineryCostController,
                            prefixIcon: Icons.agriculture_rounded,
                            suffixText: '₹',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    CalculatorInputField(
                      label: 'Other / Misc Expenses (₹)',
                      controller: _otherCostController,
                      prefixIcon: Icons.more_horiz_rounded,
                      suffixText: '₹',
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Harvest Revenue Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monetization_on_rounded, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Harvest & Selling / વેચાણ અને આવક',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Total Harvest (Quintals)',
                            controller: _harvestQtyController,
                            prefixIcon: Icons.inventory_2_rounded,
                            suffixText: 'Qtl',
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CalculatorInputField(
                            label: 'Selling Price / ભાવ (₹/Qtl)',
                            controller: _sellingPriceController,
                            prefixIcon: Icons.currency_rupee_rounded,
                            suffixText: '₹/Qtl',
                            onChanged: (_) => _calculate(),
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
                  border: Border.all(
                    color: _result!.isProfit ? const Color(0xFF81C784) : const Color(0xFFE57373),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _result!.isProfit ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.isProfit ? 'NET PROFIT / ચોખ્ખો નફો' : 'NET LOSS / નુકસાન',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'ROI: ${_result!.roiPercent.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            CalculatorLocalization.formatINR(_result!.netProfit),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
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
                            label: 'Gross Revenue / કુલ આવક',
                            value: CalculatorLocalization.formatINR(_result!.grossRevenue),
                            color: const Color(0xFF1B5E20),
                            icon: Icons.payments_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Total Expenses / કુલ ખર્ચ',
                            value: CalculatorLocalization.formatINR(_result!.totalExpenses),
                            color: const Color(0xFFC62828),
                            icon: Icons.receipt_long_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Profit per Acre / એકર નફો',
                            value: CalculatorLocalization.formatINR(_result!.profitPerAcre),
                            color: const Color(0xFFE65100),
                            icon: Icons.area_chart_rounded,
                          ),
                          ResultMetricBox(
                            label: 'Break-Even Selling Price',
                            value: CalculatorLocalization.formatINR(_result!.breakEvenPrice),
                            unit: '/Qtl',
                            color: const Color(0xFF0277BD),
                            icon: Icons.balance_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              CalculationBreakdownCard(
                formula: 'Net Profit = (Harvest Quantity × Selling Price) − Total Farming Expenses',
                steps: [
                  'Gross Revenue: ${_harvestQtyController.text} Quintals × ₹${_sellingPriceController.text} = ${CalculatorLocalization.formatINR(_result!.grossRevenue)}',
                  'Total Expenses: Sum of Seed + Fertilizer + Spray + Labour + Irrigation + Tractor + Misc = ${CalculatorLocalization.formatINR(_result!.totalExpenses)} (${CalculatorLocalization.formatINR(_result!.costPerAcre)}/acre).',
                  'Net Bottom Line: ${CalculatorLocalization.formatINR(_result!.grossRevenue)} − ${CalculatorLocalization.formatINR(_result!.totalExpenses)} = ${CalculatorLocalization.formatINR(_result!.netProfit)}.',
                  'Break-Even Warning: You must sell produce at least at ${CalculatorLocalization.formatINR(_result!.breakEvenPrice)} per Quintal to recover all costs.',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
