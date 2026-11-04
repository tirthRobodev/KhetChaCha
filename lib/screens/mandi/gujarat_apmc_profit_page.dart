import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/farmer_profile.dart';
import '../../services/gujarat_apmc_service.dart';
import '../../services/language_service.dart';
import '../../services/mandi_map_navigation_helper.dart';

/// Profit estimation calculator across nearby Gujarat APMCs.
/// Farmer inputs crop, quantity and transport cost — app shows net return per APMC.
/// NOTE: Actual market prices are NOT available from the PDF directory.
/// This calculator uses farmer-entered price or estimates clearly labeled as such.
class GujaratApmcProfitPage extends StatefulWidget {
  final FarmerProfile? profile;
  final GujaratApmcEntry? initialApmc;
  final double farmerLat;
  final double farmerLon;
  final List<ApmcWithDistance> nearbyResults;
  final String initialCrop;

  const GujaratApmcProfitPage({
    super.key,
    required this.profile,
    required this.initialApmc,
    required this.farmerLat,
    required this.farmerLon,
    required this.nearbyResults,
    required this.initialCrop,
  });

  @override
  State<GujaratApmcProfitPage> createState() => _GujaratApmcProfitPageState();
}

class _GujaratApmcProfitPageState extends State<GujaratApmcProfitPage> {
  final _quantityCtrl = TextEditingController(text: '20');
  final _priceCtrl = TextEditingController();
  final _transportCtrl = TextEditingController(text: '5');
  final _otherCtrl = TextEditingController(text: '0');

  String _quantityUnit = 'Quintal';
  bool _calculated = false;
  List<_ProfitRow> _rows = [];

  static const List<Map<String, String>> _crops = [
    {'en': 'Wheat', 'gu': 'ઘઉં', 'key': 'wheat'},
    {'en': 'Cotton', 'gu': 'કપાસ', 'key': 'cotton'},
    {'en': 'Groundnut', 'gu': 'મગફળી', 'key': 'groundnut'},
    {'en': 'Cumin', 'gu': 'જીરું', 'key': 'cumin'},
    {'en': 'Castor', 'gu': 'એરંડા', 'key': 'castor'},
    {'en': 'Maize', 'gu': 'મકાઈ', 'key': 'maize'},
    {'en': 'Paddy', 'gu': 'ડાંગર', 'key': 'paddy'},
    {'en': 'Onion', 'gu': 'ડુંગળી', 'key': 'onion'},
    {'en': 'Potato', 'gu': 'બટાકા', 'key': 'potato'},
    {'en': 'Tomato', 'gu': 'ટામેટાં', 'key': 'tomato'},
    {'en': 'Bajra', 'gu': 'બાજરી', 'key': 'bajra'},
    {'en': 'Sesame', 'gu': 'તલ', 'key': 'sesame'},
    {'en': 'Gram', 'gu': 'ચણા', 'key': 'gram'},
    {'en': 'Soybean', 'gu': 'સોયાબીન', 'key': 'soybean'},
    {'en': 'Mustard', 'gu': 'સરસવ', 'key': 'mustard'},
  ];

  late String _selectedCropKey;

  @override
  void initState() {
    super.initState();
    _selectedCropKey = widget.initialCrop.isNotEmpty
        ? widget.initialCrop
        : 'wheat';
    if (!_crops.any((c) => c['key'] == _selectedCropKey)) {
      _selectedCropKey = 'wheat';
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _transportCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  String _t(String gu, String en) {
    final lang = LanguageService.instance.currentLanguage.code;
    return lang == 'gu' ? gu : en;
  }

  double get _quintals {
    final raw = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    return _quantityUnit == 'Kg' ? raw / 100.0 : raw;
  }

  void _calculate() {
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'કૃપા કરીને ₹/ક્વિન્ટલ ભાવ દાખલ કરો',
              'Please enter a price in ₹/quintal',
            ),
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    final qty = _quintals;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('માત્રા દાખલ કરો', 'Please enter quantity')),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    final transportPerKm = double.tryParse(_transportCtrl.text.trim()) ?? 5.0;
    final otherExp = double.tryParse(_otherCtrl.text.trim()) ?? 0.0;

    final gross = price * qty;

    // Use nearby results if available, else fallback to initialApmc alone
    final List<ApmcWithDistance> source = widget.nearbyResults.isNotEmpty
        ? widget.nearbyResults
        : (widget.initialApmc != null
              ? [
                  ApmcWithDistance(
                    apmc: widget.initialApmc!,
                    distanceKm: GujaratApmcService.haversineKm(
                      widget.farmerLat,
                      widget.farmerLon,
                      widget.initialApmc!.latitude ?? widget.farmerLat,
                      widget.initialApmc!.longitude ?? widget.farmerLon,
                    ),
                  ),
                ]
              : []);

    final rows = source.where((r) => r.distanceKm != double.infinity).map((r) {
      final transportCost = transportPerKm * r.distanceKm;
      final net = gross - transportCost - otherExp;
      return _ProfitRow(
        apmc: r.apmc,
        distanceKm: r.distanceKm,
        grossRevenue: gross,
        transportCost: transportCost,
        otherExpenses: otherExp,
        netReturn: net,
      );
    }).toList()..sort((a, b) => b.netReturn.compareTo(a.netReturn));

    // Mark best
    if (rows.isNotEmpty) rows[0] = rows[0].copyWith(isRecommended: true);

    setState(() {
      _rows = rows;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance.currentLanguage.code;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('ખેડૂત નફો કેલ્ક્યુલેટર', 'Farmer Profit Calculator'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _t(
                'APMC પ્રમાણે સૌથી વધુ ચોખ્ખી આવક',
                'Best Net Return Across APMCs',
              ),
              style: const TextStyle(fontSize: 11, color: Color(0xFFB9F6CA)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input card
            _buildInputCard(lang),
            const SizedBox(height: 14),

            // Disclaimer about live prices
            _buildPriceDisclaimer(lang),

            const SizedBox(height: 14),

            // Calculate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_rounded, size: 20),
                label: Text(
                  _t('ચોખ્ખી આવક ગણો', 'Calculate Net Return'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (_calculated) ...[
              const SizedBox(height: 20),
              _buildResultsHeader(lang),
              const SizedBox(height: 10),
              ..._rows.map((r) => _buildResultCard(r, lang)),
              const SizedBox(height: 14),
              _buildResultsDisclaimer(lang),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('ખેડૂત ઇનપુટ', 'Farmer Input'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const Divider(height: 16),

          // Crop
          Text(_t('પાક', 'Crop'), style: _labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedCropKey,
            decoration: _inputDecoration(),
            items: _crops
                .map(
                  (c) => DropdownMenuItem(
                    value: c['key'],
                    child: Text(lang == 'gu' ? c['gu']! : c['en']!),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCropKey = v ?? 'wheat';
            }),
          ),

          const SizedBox(height: 12),

          // Quantity + unit
          Text(_t('જથ્થો', 'Quantity'), style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: _inputDecoration(hint: '20'),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _quantityUnit,
                onChanged: (v) => setState(() {
                  _quantityUnit = v ?? 'Quintal';
                }),
                items: ['Quintal', 'Kg']
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Price
          Text(
            _t(
              'ભાવ (₹/ક્વિન્ટલ) — AGMARKNET / બજાર ભાવ',
              'Price (₹/Quintal) — AGMARKNET / Market Rate',
            ),
            style: _labelStyle,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: _inputDecoration(hint: _t('દા.ત. 2500', 'e.g. 2500')),
          ),

          const SizedBox(height: 12),

          // Transport cost per km
          Text(
            _t('ટ્રાન્સપોર્ટ ખર્ચ (₹/કિમી)', 'Transport Cost (₹ per km)'),
            style: _labelStyle,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _transportCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: _inputDecoration(hint: '5'),
          ),

          const SizedBox(height: 12),

          // Other expenses
          Text(
            _t(
              'અન્ય ખર્ચ (₹ — વજન, લોડ, APMC ફી)',
              'Other Expenses (₹ — weighing, loading, fees)',
            ),
            style: _labelStyle,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otherCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: _inputDecoration(hint: '0'),
          ),
        ],
      ),
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF424242),
  );

  InputDecoration _inputDecoration({String hint = ''}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  Widget _buildPriceDisclaimer(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, size: 18, color: Color(0xFFF57F17)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(
                '⚠️ PDF ડિરેક્ટ્રીમાં ભાવ ઉપલબ્ધ નથી. '
                    'સત્તાવાર ભાવ agmarknet.gov.in પર ચકાસો. '
                    'ઉપર દાખલ કરેલ ભાવ ખેડૂત-આપ્યો અંદાજ છે.',
                '⚠️ The PDF directory does not contain live market prices. '
                    'Verify official prices at agmarknet.gov.in. '
                    'The price you enter above is your own estimate.',
              ),
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF5D4037),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(String lang) {
    final cropLabel = _crops.firstWhere(
      (c) => c['key'] == _selectedCropKey,
      orElse: () => {'en': _selectedCropKey, 'gu': _selectedCropKey},
    )[lang == 'gu' ? 'gu' : 'en']!;

    return Row(
      children: [
        const Icon(
          Icons.leaderboard_rounded,
          size: 18,
          color: Color(0xFF1B5E20),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _t(
              '${_rows.length} APMC • $cropLabel • ${_quintals.toStringAsFixed(1)} ક્વિ.',
              '${_rows.length} APMCs • $cropLabel • ${_quintals.toStringAsFixed(1)} qtl',
            ),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(_ProfitRow row, String lang) {
    final isTop = row.isRecommended;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.apmc.displayName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isTop
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _t('★ સૌથી વધુ', '★ Best'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              '${row.apmc.district} • ${row.distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
            ),
            const Divider(height: 14),
            Row(
              children: [
                _statBox(
                  _t('સ. આવક', 'Gross'),
                  '₹${_fmt(row.grossRevenue)}',
                  const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 8),
                _statBox(
                  _t('ટ્રાન્સ.', 'Transport'),
                  '₹${_fmt(row.transportCost)}',
                  const Color(0xFFE65100),
                ),
                const SizedBox(width: 8),
                _statBox(
                  _t('ચોખ્ખી', 'Net'),
                  '₹${_fmt(row.netReturn)}',
                  row.netReturn >= 0
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFB71C1C),
                  bold: true,
                ),
              ],
            ),
            if (row.otherExpenses > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_t("અન્ય ખર્ચ", "Other exp.")}: ₹${_fmt(row.otherExpenses)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                  icon: const Icon(
                    Icons.directions_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  label: Text(
                    _t('દિશા-નિર્દેશ (મેપ્સ)', 'Directions (Maps)'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  onPressed: () {
                    MandiMapNavigationHelper.openDirections(
                      context: context,
                      marketName: row.apmc.displayName,
                      address: row.apmc.address,
                      marketLat: row.apmc.latitude,
                      marketLon: row.apmc.longitude,
                      farmerLat: widget.farmerLat,
                      farmerLon: widget.farmerLon,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsDisclaimer(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Text(
        _t(
          '📋 આ ગણતરીઓ ખેડૂત-આપ્યા ભાવ પર આધારિત અંદાજ છે. '
              'વાસ્તવિક ભાવ ગુણવત્તા, ગ્રેડ, માંગ, APMC ફી અને '
              'ખરીદ-વેચ પ્રક્રિયા પ્રમાણે બદલાય. AGMARKNET (agmarknet.gov.in) '
              'પર સત્તાવાર ભાવ ચકાસો.',
          '📋 These calculations are estimates based on farmer-entered price. '
              'Actual prices vary by quality, grade, demand, APMC charges, and '
              'auction process. Always verify official prices at agmarknet.gov.in '
              'before making decisions.',
        ),
        style: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF5D4037),
          height: 1.4,
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v.abs() >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

class _ProfitRow {
  final GujaratApmcEntry apmc;
  final double distanceKm;
  final double grossRevenue;
  final double transportCost;
  final double otherExpenses;
  final double netReturn;
  final bool isRecommended;

  const _ProfitRow({
    required this.apmc,
    required this.distanceKm,
    required this.grossRevenue,
    required this.transportCost,
    required this.otherExpenses,
    required this.netReturn,
    this.isRecommended = false,
  });

  _ProfitRow copyWith({bool? isRecommended}) {
    return _ProfitRow(
      apmc: apmc,
      distanceKm: distanceKm,
      grossRevenue: grossRevenue,
      transportCost: transportCost,
      otherExpenses: otherExpenses,
      netReturn: netReturn,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}
