import 'package:flutter/material.dart';

import '../../services/agriculture_calculator_service.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/calculator_ui_components.dart';

enum FarmerCalcMode {
  profitAndLoss,
  seedRequirement,
  yieldEstimation,
  costPerAcre,
  producePrice,
}

class FarmerCalculatorPage extends StatefulWidget {
  const FarmerCalculatorPage({super.key});

  @override
  State<FarmerCalculatorPage> createState() => _FarmerCalculatorPageState();
}

class _FarmerCalculatorPageState extends State<FarmerCalculatorPage> {
  FarmerCalcMode _mode = FarmerCalcMode.profitAndLoss;

  // Controllers
  final _areaController = TextEditingController(text: '2.0');
  final _seedRateController = TextEditingController(text: '25.0');
  final _yieldRateController = TextEditingController(text: '18.0');
  final _totalCostController = TextEditingController(text: '45000');
  final _harvestQtyController = TextEditingController(text: '35.0'); // Quintals
  final _sellingPriceController = TextEditingController(
    text: '2200',
  ); // ₹ per Quintal

  String _areaUnit = 'Acre';
  String _sellingPriceUnit = '₹/Quintal';
  String _harvestUnit = 'Quintal';
  String? _validationError;
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _seedRateController.dispose();
    _yieldRateController.dispose();
    _totalCostController.dispose();
    _harvestQtyController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      _validationError = null;
    });

    final area = double.tryParse(_areaController.text.trim()) ?? 0;
    if (area <= 0) {
      setState(() {
        _validationError = 'Please enter a valid field area (> 0).';
        _results = null;
      });
      return;
    }

    final acres = AgricultureCalculatorService.toAcres(area, _areaUnit);

    switch (_mode) {
      case FarmerCalcMode.profitAndLoss:
        final harvest = double.tryParse(_harvestQtyController.text.trim()) ?? 0;
        final price = double.tryParse(_sellingPriceController.text.trim()) ?? 0;
        final cost = double.tryParse(_totalCostController.text.trim()) ?? 0;

        if (harvest <= 0 || price <= 0 || cost < 0) {
          setState(() {
            _validationError =
                'Please enter valid harvest quantity, price, and total cost.';
            _results = null;
          });
          return;
        }

        final isPriceMaund =
            _sellingPriceUnit.contains('Maund') ||
            _sellingPriceUnit.contains('મણ') ||
            _sellingPriceUnit.contains('मन');
        final isHarvestMaund =
            _harvestUnit.contains('Maund') ||
            _harvestUnit.contains('મણ') ||
            _harvestUnit.contains('मन');

        final double harvestInQuintals = isHarvestMaund
            ? harvest / 5.0
            : harvest;
        final double harvestInMaunds = isHarvestMaund ? harvest : harvest * 5.0;

        final double revenue = isPriceMaund
            ? harvestInMaunds * price
            : harvestInQuintals * price;
        final double profit = revenue - cost;

        final double breakEven = isPriceMaund
            ? (harvestInMaunds > 0 ? cost / harvestInMaunds : 0.0)
            : (harvestInQuintals > 0 ? cost / harvestInQuintals : 0.0);

        setState(() {
          _results = {
            'revenue': revenue,
            'cost': cost,
            'profit': profit,
            'isProfit': profit >= 0,
            'profitPerAcre': acres > 0 ? profit / acres : 0.0,
            'breakEven': breakEven,
            'acres': acres,
            'isPriceMaund': isPriceMaund,
            'isHarvestMaund': isHarvestMaund,
            'harvestQty': harvest,
            'harvestInQuintals': harvestInQuintals,
            'harvestInMaunds': harvestInMaunds,
            'price': price,
          };
        });
        break;

      case FarmerCalcMode.seedRequirement:
        final seedRate = double.tryParse(_seedRateController.text.trim()) ?? 0;
        if (seedRate <= 0) {
          setState(() {
            _validationError = 'Please enter a valid seed rate in kg/acre.';
            _results = null;
          });
          return;
        }
        final totalSeed = acres * seedRate;
        setState(() {
          _results = {
            'seedTotal': totalSeed,
            'seedRate': seedRate,
            'acres': acres,
          };
        });
        break;

      case FarmerCalcMode.yieldEstimation:
        final yieldRate =
            double.tryParse(_yieldRateController.text.trim()) ?? 0;
        if (yieldRate <= 0) {
          setState(() {
            _validationError =
                'Please enter expected yield per acre in Quintals.';
            _results = null;
          });
          return;
        }
        final totalQuintals = acres * yieldRate;
        setState(() {
          _results = {
            'totalQuintals': totalQuintals,
            'totalTons': totalQuintals / 10.0,
            'totalMon': totalQuintals * 5.0, // 1 Quintal = 5 Mon (20kg each)
            'yieldPerAcre': yieldRate,
            'acres': acres,
          };
        });
        break;

      case FarmerCalcMode.costPerAcre:
        final cost = double.tryParse(_totalCostController.text.trim()) ?? 0;
        if (cost <= 0) {
          setState(() {
            _validationError = 'Please enter total farming cost.';
            _results = null;
          });
          return;
        }
        setState(() {
          _results = {
            'totalCost': cost,
            'costPerAcre': acres > 0 ? cost / acres : cost,
            'acres': acres,
          };
        });
        break;

      case FarmerCalcMode.producePrice:
        final cost = double.tryParse(_totalCostController.text.trim()) ?? 0;
        final harvest = double.tryParse(_harvestQtyController.text.trim()) ?? 0;
        if (cost <= 0 || harvest <= 0) {
          setState(() {
            _validationError = 'Please enter total cost and harvest quantity to compute break-even produce price.';
            _results = null;
          });
          return;
        }

        final isPriceMaund =
            _sellingPriceUnit.contains('Maund') ||
            _sellingPriceUnit.contains('મણ') ||
            _sellingPriceUnit.contains('मन');
        final isHarvestMaund =
            _harvestUnit.contains('Maund') ||
            _harvestUnit.contains('મણ') ||
            _harvestUnit.contains('मन');

        final double effectiveHarvestInPriceUnit = isPriceMaund
            ? (isHarvestMaund ? harvest : harvest * 5.0)
            : (isHarvestMaund ? harvest / 5.0 : harvest);

        final minPrice = effectiveHarvestInPriceUnit > 0
            ? cost / effectiveHarvestInPriceUnit
            : 0.0;
        final target15 = minPrice * 1.15;
        final target25 = minPrice * 1.25;
        setState(() {
          _results = {
            'minPrice': minPrice,
            'target15': target15,
            'target25': target25,
            'harvest': harvest,
            'effectiveHarvest': effectiveHarvestInPriceUnit,
            'cost': cost,
            'isPriceMaund': isPriceMaund,
          };
        });
        break;
    }
  }

  void _reset() {
    setState(() {
      _areaController.text = '2.0';
      _seedRateController.text = '25.0';
      _yieldRateController.text = '18.0';
      _totalCostController.text = '45000';
      _harvestQtyController.text = '35.0';
      _sellingPriceController.text = '2200';
      _areaUnit = 'Acre';
      _sellingPriceUnit = '₹/Quintal';
      _harvestUnit = 'Quintal';
      _validationError = null;
    });
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return CalculatorScaffold(
      title: CalculatorLocalization.t('farmer_calc_name', langCode),
      subtitle: CalculatorLocalization.t('farmer_calc_desc', langCode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip(
                    'Profit & Loss / નફો-નુકસાન',
                    FarmerCalcMode.profitAndLoss,
                  ),
                  _buildModeChip(
                    'Seed / બિયારણ',
                    FarmerCalcMode.seedRequirement,
                  ),
                  _buildModeChip(
                    'Crop Yield / ઉત્પાદન',
                    FarmerCalcMode.yieldEstimation,
                  ),
                  _buildModeChip(
                    'Cost per Acre / એકર ખર્ચ',
                    FarmerCalcMode.costPerAcre,
                  ),
                  _buildModeChip(
                    'Produce Price / વેચાણ ભાવ',
                    FarmerCalcMode.producePrice,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inputs Card
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
                            onChanged: (_) => _recalculate(),
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
                                    _recalculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Contextual Inputs based on mode
                    if (_mode == FarmerCalcMode.profitAndLoss) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CalculatorLocalization.t(
                                    'harvest_unit',
                                    langCode,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _harvestUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9F7F1),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Quintal',
                                      child: Text(
                                        langCode == 'gu'
                                            ? 'ક્વિન્ટલ (૧૦૦ કિગ્રા)'
                                            : (langCode == 'hi'
                                                  ? 'क्विंटल (100 kg)'
                                                  : 'Quintal (100 kg)'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Maund',
                                      child: Text(
                                        langCode == 'gu'
                                            ? 'મણ (૨૦ કિગ્રા)'
                                            : (langCode == 'hi'
                                                  ? 'मन (20 kg)'
                                                  : 'Maund (20 kg)'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _harvestUnit = val);
                                      _recalculate();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CalculatorLocalization.t(
                                    'selling_price_unit',
                                    langCode,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _sellingPriceUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9F7F1),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: '₹/Quintal',
                                      child: Text(
                                        CalculatorLocalization.t(
                                          'unit_quintal',
                                          langCode,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: '₹/Maund',
                                      child: Text(
                                        CalculatorLocalization.t(
                                          'unit_maund',
                                          langCode,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _sellingPriceUnit = val);
                                      _recalculate();
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
                        label: 'Total Farming Expenses / કુલ ખેતી ખર્ચ (₹)',
                        controller: _totalCostController,
                        prefixIcon: Icons.receipt_long_rounded,
                        suffixText: '₹',
                        onChanged: (_) => _recalculate(),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CalculatorInputField(
                              label: 'Total Harvest / કુલ ઉત્પાદન',
                              controller: _harvestQtyController,
                              prefixIcon: Icons.inventory_2_rounded,
                              suffixText: _harvestUnit == 'Maund'
                                  ? (langCode == 'gu' ? 'મણ' : 'Maund')
                                  : (langCode == 'gu' ? 'ક્વિન્ટલ' : 'Qtl'),
                              onChanged: (_) => _recalculate(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CalculatorInputField(
                              label: 'Selling Price / વેચાણ ભાવ',
                              controller: _sellingPriceController,
                              prefixIcon: Icons.currency_rupee_rounded,
                              suffixText: _sellingPriceUnit == '₹/Maund'
                                  ? (langCode == 'gu' ? '₹/મણ' : '₹/Maund')
                                  : (langCode == 'gu' ? '₹/ક્વિ' : '₹/Qtl'),
                              onChanged: (_) => _recalculate(),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_mode == FarmerCalcMode.seedRequirement) ...[
                      CalculatorInputField(
                        label: 'Seed Rate / બિયારણ દર (kg/acre)',
                        controller: _seedRateController,
                        prefixIcon: Icons.grain_rounded,
                        suffixText: 'kg/ac',
                        onChanged: (_) => _recalculate(),
                      ),
                    ] else if (_mode == FarmerCalcMode.yieldEstimation) ...[
                      CalculatorInputField(
                        label:
                            'Expected Yield / અપેક્ષિત ઉત્પાદન (Quintals/acre)',
                        controller: _yieldRateController,
                        prefixIcon: Icons.eco_rounded,
                        suffixText: 'Qtl/ac',
                        onChanged: (_) => _recalculate(),
                      ),
                    ] else if (_mode == FarmerCalcMode.costPerAcre) ...[
                      CalculatorInputField(
                        label: 'Total Farming Cost / કુલ ખર્ચ (₹)',
                        controller: _totalCostController,
                        prefixIcon: Icons.receipt_long_rounded,
                        suffixText: '₹',
                        onChanged: (_) => _recalculate(),
                      ),
                    ] else if (_mode == FarmerCalcMode.producePrice) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CalculatorLocalization.t(
                                    'harvest_unit',
                                    langCode,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _harvestUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9F7F1),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Quintal',
                                      child: Text(
                                        langCode == 'gu'
                                            ? 'ક્વિન્ટલ (૧૦૦ કિગ્રા)'
                                            : (langCode == 'hi'
                                                  ? 'क्विंटल (100 kg)'
                                                  : 'Quintal (100 kg)'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Maund',
                                      child: Text(
                                        langCode == 'gu'
                                            ? 'મણ (૨૦ કિગ્રા)'
                                            : (langCode == 'hi'
                                                  ? 'मन (20 kg)'
                                                  : 'Maund (20 kg)'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _harvestUnit = val);
                                      _recalculate();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CalculatorLocalization.t(
                                    'selling_price_unit',
                                    langCode,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _sellingPriceUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9F7F1),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: '₹/Quintal',
                                      child: Text(
                                        CalculatorLocalization.t(
                                          'unit_quintal',
                                          langCode,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: '₹/Maund',
                                      child: Text(
                                        CalculatorLocalization.t(
                                          'unit_maund',
                                          langCode,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _sellingPriceUnit = val);
                                      _recalculate();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CalculatorInputField(
                              label: 'Total Cost / કુલ ખર્ચ (₹)',
                              controller: _totalCostController,
                              prefixIcon: Icons.receipt_long_rounded,
                              suffixText: '₹',
                              onChanged: (_) => _recalculate(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CalculatorInputField(
                              label: 'Harvest / ઉત્પાદન',
                              controller: _harvestQtyController,
                              prefixIcon: Icons.inventory_2_rounded,
                              suffixText: _harvestUnit == 'Maund'
                                  ? (langCode == 'gu' ? 'મણ' : 'Maund')
                                  : (langCode == 'gu' ? 'ક્વિન્ટલ' : 'Qtl'),
                              onChanged: (_) => _recalculate(),
                            ),
                          ),
                        ],
                      ),
                    ],
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

            CalculatorActionButtons(onCalculate: _recalculate, onReset: _reset),

            if (_results != null) ...[
              const SizedBox(height: 8),
              _buildResultsView(langCode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, FarmerCalcMode mode) {
    final isSelected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF1B5E20),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _mode = mode;
            });
            _recalculate();
          }
        },
      ),
    );
  }

  Widget _buildResultsView(String langCode) {
    switch (_mode) {
      case FarmerCalcMode.profitAndLoss:
        final bool isProfit = _results!['isProfit'] as bool;
        final double profit = _results!['profit'] as double;
        final double revenue = _results!['revenue'] as double;
        final double cost = _results!['cost'] as double;
        final double breakEven = _results!['breakEven'] as double;
        final double profitPerAcre = _results!['profitPerAcre'] as double;
        final bool isPriceMaund = (_results!['isPriceMaund'] as bool?) ?? false;
        final double harvestInQuintals =
            (_results!['harvestInQuintals'] as double?) ?? 0.0;
        final double harvestInMaunds =
            (_results!['harvestInMaunds'] as double?) ?? 0.0;
        final double harvestQty = (_results!['harvestQty'] as double?) ?? 0.0;
        final double price = (_results!['price'] as double?) ?? 0.0;

        final String unitSuffix = isPriceMaund
            ? (langCode == 'gu' ? '/મણ' : (langCode == 'hi' ? '/मन' : '/Maund'))
            : (langCode == 'gu'
                  ? '/ક્વિન્ટલ'
                  : (langCode == 'hi' ? '/क्विंटल' : '/Qtl'));

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isProfit
                      ? const Color(0xFF81C784)
                      : const Color(0xFFE57373),
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
                    decoration: BoxDecoration(
                      color: isProfit
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFC62828),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isProfit ? 'PROFIT / ચોખ્ખો નફો' : 'LOSS / નુકસાન',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          CalculatorLocalization.formatINR(profit),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
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
                      childAspectRatio: 1.5,
                      children: [
                        ResultMetricBox(
                          label: 'Total Revenue / કુલ આવક',
                          value: CalculatorLocalization.formatINR(revenue),
                          color: const Color(0xFF1B5E20),
                          icon: Icons.payments_rounded,
                        ),
                        ResultMetricBox(
                          label: 'Total Expenses / કુલ ખર્ચ',
                          value: CalculatorLocalization.formatINR(cost),
                          color: const Color(0xFFC62828),
                          icon: Icons.receipt_long_rounded,
                        ),
                        ResultMetricBox(
                          label: 'Net per Acre / એકર નફો',
                          value: CalculatorLocalization.formatINR(
                            profitPerAcre,
                          ),
                          color: const Color(0xFFE65100),
                          icon: Icons.area_chart_rounded,
                        ),
                        ResultMetricBox(
                          label: 'Break-Even / મૂળ કિંમત',
                          value: CalculatorLocalization.formatINR(breakEven),
                          unit: unitSuffix,
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
              formula: 'Profit = Total Revenue − Total Farming Cost',
              steps: [
                isPriceMaund
                    ? 'Harvest Revenue: ${harvestQty.toStringAsFixed(1)} ${_harvestUnit == "Maund" ? "Maund" : "Quintal"} (${harvestInMaunds.toStringAsFixed(1)} Maunds) × ₹${price.toStringAsFixed(0)}/Maund = ${CalculatorLocalization.formatINR(revenue)}'
                    : 'Harvest Revenue: ${harvestQty.toStringAsFixed(1)} ${_harvestUnit == "Maund" ? "Maund" : "Quintal"} (${harvestInQuintals.toStringAsFixed(1)} Quintals) × ₹${price.toStringAsFixed(0)}/Qtl = ${CalculatorLocalization.formatINR(revenue)}',
                'Farming Expenses: ${CalculatorLocalization.formatINR(cost)}',
                'Net Result: ${CalculatorLocalization.formatINR(revenue)} − ${CalculatorLocalization.formatINR(cost)} = ${CalculatorLocalization.formatINR(profit)}',
                isPriceMaund
                    ? 'Break-Even Rate: You need at least ${CalculatorLocalization.formatINR(breakEven)}/Maund (${CalculatorLocalization.formatINR(breakEven * 5.0)}/Quintal) to avoid loss.'
                    : 'Break-Even Rate: You need at least ${CalculatorLocalization.formatINR(breakEven)}/Quintal (${CalculatorLocalization.formatINR(breakEven / 5.0)}/Maund) to avoid loss.',
              ],
            ),
          ],
        );

      case FarmerCalcMode.seedRequirement:
        final double totalSeed = _results!['seedTotal'] as double;
        final double acres = _results!['acres'] as double;
        return Column(
          children: [
            ResultMetricBox(
              label: 'Total Seed Needed / જરૂરી કુલ બિયારણ',
              value: CalculatorLocalization.formatNumber(totalSeed),
              unit: 'kg',
              color: const Color(0xFF1B5E20),
              icon: Icons.grain_rounded,
            ),
            CalculationBreakdownCard(
              formula: 'Total Seed (kg) = Standard Acres × Seed Rate (kg/acre)',
              steps: [
                'Field Area: ${acres.toStringAsFixed(2)} acres',
                'Seed Rate: ${_results!['seedRate']} kg/acre',
                'Calculation: ${acres.toStringAsFixed(2)} × ${_results!['seedRate']} = ${totalSeed.toStringAsFixed(2)} kg',
              ],
            ),
          ],
        );

      case FarmerCalcMode.yieldEstimation:
        final double totalQtl = _results!['totalQuintals'] as double;
        final double totalTons = _results!['totalTons'] as double;
        final double totalMon = _results!['totalMon'] as double;
        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                ResultMetricBox(
                  label: 'Quintals',
                  value: CalculatorLocalization.formatNumber(totalQtl),
                  unit: 'Qtl',
                ),
                ResultMetricBox(
                  label: 'Metric Tons',
                  value: CalculatorLocalization.formatNumber(totalTons),
                  unit: 'Tons',
                  color: const Color(0xFFE65100),
                ),
                ResultMetricBox(
                  label: 'Maund / મણ',
                  value: CalculatorLocalization.formatNumber(totalMon),
                  unit: 'Mon',
                  color: const Color(0xFF0277BD),
                ),
              ],
            ),
            CalculationBreakdownCard(
              formula: 'Harvest = Field Area (Acres) × Expected Yield per Acre',
              steps: [
                'Total expected harvest is ${totalQtl.toStringAsFixed(2)} Quintals (${totalTons.toStringAsFixed(2)} Metric Tons or ${totalMon.toStringAsFixed(1)} Maund).',
                'Actual harvest can vary based on soil, monsoon, and crop management.',
              ],
            ),
          ],
        );

      case FarmerCalcMode.costPerAcre:
        final double costPerAcre = _results!['costPerAcre'] as double;
        final double totalCost = _results!['totalCost'] as double;
        return Column(
          children: [
            ResultMetricBox(
              label: 'Cost per Acre / એકર દીઠ ખર્ચ',
              value: CalculatorLocalization.formatINR(costPerAcre),
              unit: '/acre',
              color: const Color(0xFFC62828),
              icon: Icons.monetization_on_outlined,
            ),
            CalculationBreakdownCard(
              formula: 'Cost per Acre = Total Expenses ÷ Total Acres',
              steps: [
                'Total Expenses: ${CalculatorLocalization.formatINR(totalCost)}',
                'Field Area: ${_results!['acres'].toStringAsFixed(2)} acres',
                'Average Cost: ${CalculatorLocalization.formatINR(costPerAcre)} per acre',
              ],
            ),
          ],
        );

      case FarmerCalcMode.producePrice:
        final double minPrice = _results!['minPrice'] as double;
        final double target15 = _results!['target15'] as double;
        final double target25 = _results!['target25'] as double;
        final bool isPriceMaund = (_results!['isPriceMaund'] as bool?) ?? false;

        final String unitSuffix = isPriceMaund
            ? (langCode == 'gu' ? '/મણ' : (langCode == 'hi' ? '/मन' : '/Maund'))
            : (langCode == 'gu'
                  ? '/ક્વિન્ટલ'
                  : (langCode == 'hi' ? '/क्विंटલ' : '/Qtl'));

        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                ResultMetricBox(
                  label: 'Break-Even',
                  value: CalculatorLocalization.formatINR(minPrice),
                  unit: unitSuffix,
                  color: const Color(0xFFC62828),
                ),
                ResultMetricBox(
                  label: 'Target +15%',
                  value: CalculatorLocalization.formatINR(target15),
                  unit: unitSuffix,
                  color: const Color(0xFFE65100),
                ),
                ResultMetricBox(
                  label: 'Target +25%',
                  value: CalculatorLocalization.formatINR(target25),
                  unit: unitSuffix,
                  color: const Color(0xFF1B5E20),
                ),
              ],
            ),
            CalculationBreakdownCard(
              formula: 'Break-Even Price = Total Cost ÷ Total Harvest Quantity',
              steps: [
                'Minimum selling price to cover all expenses is ${CalculatorLocalization.formatINR(minPrice)}$unitSuffix.',
                'To secure a 15% profit margin, sell at or above ${CalculatorLocalization.formatINR(target15)}$unitSuffix.',
                'To secure a 25% profit margin, sell at or above ${CalculatorLocalization.formatINR(target25)}$unitSuffix.',
                'Unit Ratio: 1 Quintal (100 kg) = 5 Maunds (20 kg each).',
              ],
            ),
          ],
        );
    }
  }
}
