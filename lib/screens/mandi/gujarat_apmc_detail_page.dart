import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/gujarat_apmc_service.dart';
import '../../services/language_service.dart';
import '../../services/mandi_map_navigation_helper.dart';
import 'gujarat_apmc_profit_page.dart';

/// Detailed view of a single Gujarat APMC entry.
class GujaratApmcDetailPage extends StatelessWidget {
  final GujaratApmcEntry apmc;
  final double farmerLat;
  final double farmerLon;

  const GujaratApmcDetailPage({
    super.key,
    required this.apmc,
    required this.farmerLat,
    required this.farmerLon,
  });

  String _t(String gu, String en) {
    final lang = LanguageService.instance.currentLanguage.code;
    return lang == 'gu' ? gu : en;
  }

  double get _distanceKm => GujaratApmcService.haversineKm(
    farmerLat,
    farmerLon,
    apmc.latitude ?? farmerLat,
    apmc.longitude ?? farmerLon,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          apmc.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Calculate Profit',
            icon: const Icon(Icons.calculate_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GujaratApmcProfitPage(
                  profile: null,
                  initialApmc: apmc,
                  farmerLat: farmerLat,
                  farmerLon: farmerLon,
                  nearbyResults: [],
                  initialCrop: '',
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 14),
            // Market Info
            _buildSection(
              icon: Icons.store_rounded,
              title: _t('બજારની માહિતી', 'Market Information'),
              children: [
                _infoRow(
                  Icons.location_on_rounded,
                  _t('સ્થાન', 'Location'),
                  '${apmc.district}, ${apmc.taluka}${apmc.pincode.isNotEmpty ? ", PIN ${apmc.pincode}" : ""}',
                ),
                if (apmc.address.isNotEmpty && apmc.address != '-')
                  _infoRow(
                    Icons.map_rounded,
                    _t('સરનામું', 'Address'),
                    apmc.address,
                  ),
                if (apmc.marketType.isNotEmpty && apmc.marketType != '-')
                  _infoRow(
                    Icons.warehouse_rounded,
                    _t('બજાર પ્રકાર', 'Market Type'),
                    apmc.marketType,
                  ),
                if (apmc.hasCoordinates)
                  _infoRow(
                    Icons.my_location_rounded,
                    _t('અંદાજિત અંતર', 'Est. Distance'),
                    '${_distanceKm.toStringAsFixed(1)} km ${_t('(સીધી રેખા)', '(straight line)')}',
                  ),
                _infoRow(
                  Icons.verified_rounded,
                  _t('સ્ત્રોત', 'Source'),
                  'Gujarat_All_APMC_List.pdf ${_t("(સ્થળ ચકાસ્યું નથી)", "(Location not GPS-verified)")}',
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Commodities
            if (apmc.commodities.isNotEmpty) ...[
              _buildSection(
                icon: Icons.grass_rounded,
                title: _t('ટ્રેડ કરાતી ચીજવસ્તુઓ', 'Traded Commodities'),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: apmc.commodities
                        .map((c) => _commodityChip(c))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Live Price Notice
            _buildPriceNotice(),

            const SizedBox(height: 14),

            // Contact
            if (apmc.contactPerson.isNotEmpty || apmc.contactSummary.isNotEmpty)
              _buildSection(
                icon: Icons.contact_phone_rounded,
                title: _t('સંપર્ક વિગત', 'Contact Details'),
                children: [
                  if (apmc.contactPerson.isNotEmpty &&
                      apmc.contactPerson != '-')
                    _infoRow(
                      Icons.person_rounded,
                      _t('સંપર્ક', 'Contact'),
                      apmc.contactPerson,
                    ),
                  if (apmc.mobile.isNotEmpty && apmc.mobile != '-')
                    _infoRowTap(
                      context,
                      Icons.phone_rounded,
                      _t('મોબાઇલ', 'Mobile'),
                      apmc.mobile,
                    ),
                  if (apmc.officePhone.isNotEmpty && apmc.officePhone != '-')
                    _infoRowTap(
                      context,
                      Icons.phone_in_talk_rounded,
                      _t('ઓફિસ ફોન', 'Office Phone'),
                      apmc.officePhone,
                    ),
                  if (apmc.email.isNotEmpty && apmc.email != '-')
                    _infoRow(
                      Icons.email_rounded,
                      _t('ઇ-મેઇલ', 'Email'),
                      apmc.email,
                    ),
                ],
              ),

            const SizedBox(height: 20),

            // CTA 1: Google Maps Navigation Directions
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  MandiMapNavigationHelper.openDirections(
                    context: context,
                    marketName: apmc.displayName,
                    address: apmc.address,
                    marketLat: apmc.latitude,
                    marketLon: apmc.longitude,
                    farmerLat: farmerLat,
                    farmerLon: farmerLon,
                  );
                },
                icon: const Icon(Icons.directions_rounded),
                label: Text(
                  _t(
                    'ગુગલ મેપ્સ પર દિશા-નિર્દેશ મેળવો',
                    'Get Directions on Google Maps',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CTA 2: Calculate Profit
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GujaratApmcProfitPage(
                      profile: null,
                      initialApmc: apmc,
                      farmerLat: farmerLat,
                      farmerLon: farmerLon,
                      nearbyResults: [],
                      initialCrop: '',
                    ),
                  ),
                ),
                icon: const Icon(Icons.calculate_rounded),
                label: Text(
                  _t(
                    'ખેડૂત નફો કેલ્ક્યુલેટર ખોલો',
                    'Open Farmer Profit Calculator',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Text(
                _t(
                  '⚠️ નોંધ: આ ડિરેક્ટ્રી Gujarat_All_APMC_List.pdf માંથી છે. સ્થળ, ફોન નંબર અને ઓપરેશનલ વિગતો ઉપયોગ પહેલાં ચકાસો.',
                  '⚠️ Note: Directory sourced from Gujarat_All_APMC_List.pdf. Verify location, phone numbers, and operational status before visiting.',
                ),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text('🏛️', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apmc.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${apmc.district} • ${apmc.state}',
                  style: const TextStyle(
                    color: Color(0xFFB9F6CA),
                    fontSize: 12,
                  ),
                ),
                if (apmc.hasCoordinates) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_distanceKm.toStringAsFixed(1)} km away (est.)',
                    style: const TextStyle(
                      color: Color(0xFFB9F6CA),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF757575)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowTap(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF757575)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: value)),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commodityChip(String commodity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Text(
        commodity,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriceNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Prices / ભાવ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'આ મંડીનો તાજેતરનો ભાવ ઉપલબ્ધ નથી.\n'
            '(Live prices for this mandi are not available in this offline directory.)\n\n'
            'Official live prices: agmarknet.gov.in | data.gov.in\n'
            'Gujarat AMCO: gujrat.nic.in/agri',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF388E3C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
