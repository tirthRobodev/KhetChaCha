import 'package:flutter/material.dart';

import '../../models/farmer_profile.dart';
import '../../services/mandi_price_service.dart';

/// Screen allowing farmers to compare multiple nearby APMC mandis for a specific crop,
/// calculating transport costs and net estimated selling profit.
class MandiComparisonPage extends StatefulWidget {
  final FarmerProfile profile;
  final String? initialCommodity;

  const MandiComparisonPage({
    super.key,
    required this.profile,
    this.initialCommodity,
  });

  @override
  State<MandiComparisonPage> createState() => _MandiComparisonPageState();
}

class _MandiComparisonPageState extends State<MandiComparisonPage> {
  final _quantityController = TextEditingController(text: '20');

  late String _selectedCommodity;
  String _quantityUnit = 'Quintal';
  double _transportRatePerKmQtl = 3.50;

  static const List<String> _commonCommodities = [
    'Wheat',
    'Tomato',
    'Potato',
    'Onion',
    'Cotton',
    'Mustard',
    'Groundnut',
    'Cumin (Jeera)',
    'Maize',
    'Paddy (Rice)',
    'Soybean',
    'Banana',
  ];

  static const List<Map<String, dynamic>> _transportOptions = [
    {'name': 'Tractor-Trolley', 'rate': 3.50, 'icon': '🚜'},
    {'name': 'Pickup / Small Tempo', 'rate': 4.50, 'icon': '🛻'},
    {'name': 'Truck / Canter', 'rate': 2.80, 'icon': '🚛'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCommodity =
        widget.initialCommodity ??
        (widget.profile.effectiveProducts.isNotEmpty
            ? widget.profile.effectiveProducts.first
            : 'Wheat');

    // Ensure selected commodity exists in supported list
    if (!_commonCommodities.contains(_selectedCommodity)) {
      final match = _commonCommodities.where(
        (c) => c.toLowerCase().contains(_selectedCommodity.toLowerCase()),
      );
      if (match.isNotEmpty) {
        _selectedCommodity = match.first;
      } else {
        _selectedCommodity = 'Wheat';
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _effectiveQuintals {
    final raw = double.tryParse(_quantityController.text.trim()) ?? 20.0;
    if (_quantityUnit == 'Kg') {
      return (raw / 100.0).clamp(0.1, 1000.0);
    }
    return raw.clamp(0.1, 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final farmerLat =
        p.latitude ??
        (p.effectiveState.toLowerCase().contains('punjab') ? 30.9010 : 23.0225);
    final farmerLon =
        p.longitude ??
        (p.effectiveState.toLowerCase().contains('punjab') ? 75.8573 : 72.5714);

    final comparisonResults = MandiPriceService.instance.compareMandis(
      commodity: _selectedCommodity,
      quantityQuintals: _effectiveQuintals,
      farmerLat: farmerLat,
      farmerLon: farmerLon,
      transportRatePerKmPerQuintal: _transportRatePerKmQtl,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Compare Mandi Net Returns',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Selector & Quantity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Select Crop / Commodity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCommodity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF2E7D32),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _commonCommodities.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCommodity = val);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Quantity Row
                    const Text(
                      '2. Produce Quantity to Sell',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'e.g. 25',
                              prefixIcon: const Icon(
                                Icons.scale_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _quantityUnit,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Quintal',
                                child: Text('Quintal'),
                              ),
                              DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                            ],
                            onChanged: (u) {
                              if (u != null) setState(() => _quantityUnit = u);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Transport Vehicle Mode
                    const Text(
                      '3. Transport Vehicle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _transportOptions.map((opt) {
                        final rate = (opt['rate'] as num).toDouble();
                        final isSel = _transportRatePerKmQtl == rate;
                        return ChoiceChip(
                          label: Text(
                            '${opt['icon']} ${opt['name']} (₹$rate/km/Q)',
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFFE8F5E9),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSel
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE0E0E0),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSel
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF616161),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _transportRatePerKmQtl = rate);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Formula Indicator Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Net Profit = Selling Revenue - Transportation - Mandi Handling',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Comparison Results Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${comparisonResults.length} Mandis Reporting $_selectedCommodity',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Qty: ${_effectiveQuintals.toStringAsFixed(1)} Qtl',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (comparisonResults.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 48,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No active nearby mandis recorded recent prices for $_selectedCommodity.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...comparisonResults.map((r) => _buildComparisonCard(r)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(MandiComparisonResult item) {
    final m = item.market;
    final isTop = item.isRecommended;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
          width: isTop ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop
                ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isTop ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Recommendation Badge
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isTop ? const Color(0xFFE8F5E9) : const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTop) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '★ HIGHEST NET PROFIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isTop
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF212121),
                        ),
                      ),
                      Text(
                        '${m.district}, ${m.state}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 15,
                        color: Color(0xFF2E7D32),
                      ),
                      Text(
                        '${item.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Financial Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Modal Rate & Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Modal Mandi Rate:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${item.modalPrice.toStringAsFixed(0)} / Quintal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Expected Gross Revenue:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${item.grossRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Estimated Transport Cost (${item.distanceKm.toStringAsFixed(0)} km):',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFC62828),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '- ₹${item.totalTransportCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'APMC Cess & Handling Fee:',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF757575),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '- ₹${item.mandiHandlingCharges.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 18),

                // Net Profit Result
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'NET ESTIMATED AMOUNT:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${item.netSellingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTop
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Note
                Text(
                  item.recommendationNote,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isTop
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF757575),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
