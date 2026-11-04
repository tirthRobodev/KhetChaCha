import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';
import '../../models/mandi_market.dart';
import '../../services/gujarat_apmc_service.dart';
import '../../services/language_service.dart';
import '../../services/location_service.dart';
import '../../services/mandi_discovery_service.dart';
import '../../services/mandi_map_navigation_helper.dart';
import '../../services/mandi_price_service.dart';
import '../mandi/gujarat_apmc_detail_page.dart';
import '../mandi/gujarat_apmc_finder_page.dart';
import '../mandi/mandi_comparison_page.dart';
import '../mandi/mandi_discovery_page.dart';

/// Natural Farming Marketplace & Smart APMC Mandi Hub.
///
/// Integrates all three primary agricultural market features on Page 1:
/// 1. Nearby Mandi (નજીકની મંડી) - Complete APMC discovery, GPS detection, radius/district filters.
/// 2. Highest Price (સૌથી વધુ ભાવ) - Crop price comparison sorted Highest Modal Price First.
/// 3. Best Estimated Net Return (વધુ ચોખ્ખી આવક) - Interactive profit calculator computing net proceeds after transport.
class NaturalFarmingMarketplacePage extends StatefulWidget {
  final FarmerProfile profile;
  final int initialTabIndex;

  const NaturalFarmingMarketplacePage({
    super.key,
    required this.profile,
    this.initialTabIndex = 0,
  });

  @override
  State<NaturalFarmingMarketplacePage> createState() =>
      _NaturalFarmingMarketplacePageState();
}

class _NaturalFarmingMarketplacePageState
    extends State<NaturalFarmingMarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mandiSearchController = TextEditingController();

  late FarmerProfile _currentProfile;
  bool _isLoading = true;
  String _searchQuery = '';

  // Tab 0 (Nearby Mandis) State
  List<MandiMarketWithDistance> _allNearbyMarkets = [];
  List<MandiMarketWithDistance> _filteredMarkets = [];
  List<ApmcWithDistance> _gujaratApmcResults = [];
  double _radiusKm = 100.0;
  String _selectedDistrict = '';
  String _selectedNearbyCrop = '';

  // Tab 1 (Highest Price First) State
  String _selectedComparisonCrop = 'Wheat';
  int _comparisonSortMode = 0; // 0: Highest Price, 1: Nearest, 2: Lowest Price

  // Tab 2 (Profit Calculator) State
  final TextEditingController _quantityController = TextEditingController(
    text: '20',
  );
  final TextEditingController _customPriceController = TextEditingController();
  final TextEditingController _transportRateController = TextEditingController(
    text: '5',
  );
  final TextEditingController _otherExpensesController = TextEditingController(
    text: '0',
  );
  String _quantityUnit = 'Quintal'; // 'Quintal' or 'Kg'
  String _profitCrop = 'Wheat';
  List<_ProfitMarketItem> _profitRankedResults = [];

  static const List<Map<String, String>> _supportedCrops = [
    {'en': 'Wheat', 'gu': 'ઘઉં', 'hi': 'गेहूं', 'key': 'wheat'},
    {'en': 'Cotton', 'gu': 'કપાસ', 'hi': 'कपास', 'key': 'cotton'},
    {'en': 'Groundnut', 'gu': 'મગફળી', 'hi': 'मूंगफली', 'key': 'groundnut'},
    {'en': 'Cumin', 'gu': 'જીરું', 'hi': 'जीरा', 'key': 'cumin'},
    {'en': 'Castor', 'gu': 'એરંડા', 'hi': 'अरंडी', 'key': 'castor'},
    {'en': 'Potato', 'gu': 'બટાકા', 'hi': 'आलू', 'key': 'potato'},
    {'en': 'Onion', 'gu': 'ડુંગળી', 'hi': 'प्याज', 'key': 'onion'},
    {'en': 'Tomato', 'gu': 'ટામેટાં', 'hi': 'टमाटर', 'key': 'tomato'},
    {'en': 'Mustard', 'gu': 'સરસવ', 'hi': 'सरसों', 'key': 'mustard'},
    {'en': 'Maize', 'gu': 'મકાઈ', 'hi': 'मक्का', 'key': 'maize'},
    {'en': 'Paddy', 'gu': 'ડાંગર', 'hi': 'धान', 'key': 'paddy'},
    {'en': 'Gram', 'gu': 'ચણા', 'hi': 'चना', 'key': 'gram'},
    {'en': 'Soybean', 'gu': 'સોયાબીન', 'hi': 'सोयाबीन', 'key': 'soybean'},
    {'en': 'Bajra', 'gu': 'બાજરી', 'hi': 'बाजरा', 'key': 'bajra'},
  ];

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    // Initial crop from farmer profile if available
    if (_currentProfile.effectiveProducts.isNotEmpty) {
      final p0 = _currentProfile.effectiveProducts.first;
      for (final c in _supportedCrops) {
        if (p0.toLowerCase().contains(c['key']!) ||
            c['en']!.toLowerCase().contains(p0.toLowerCase())) {
          _selectedComparisonCrop = c['en']!;
          _profitCrop = c['en']!;
          break;
        }
      }
    }

    _refreshMandiLists();
    _isLoading = false;
    _loadGujaratDirectory();
  }

  Future<void> _loadGujaratDirectory() async {
    try {
      await GujaratApmcService.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _refreshMandiLists();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mandiSearchController.dispose();
    _quantityController.dispose();
    _customPriceController.dispose();
    _transportRateController.dispose();
    _otherExpensesController.dispose();
    super.dispose();
  }

  double get _farmerLat =>
      _currentProfile.latitude ??
      (_currentProfile.effectiveState.toLowerCase().contains('punjab')
          ? 30.9010
          : 23.0225);

  double get _farmerLon =>
      _currentProfile.longitude ??
      (_currentProfile.effectiveState.toLowerCase().contains('punjab')
          ? 75.8573
          : 72.5714);

  void _refreshMandiLists() {
    // 1. National Discovery Service
    final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: _farmerLat,
      longitude: _farmerLon,
      maxDistanceKm: _radiusKm < 250 ? 250.0 : _radiusKm,
    );
    _allNearbyMarkets = nearby;

    // 2. Gujarat 226 Directory
    _gujaratApmcResults = GujaratApmcService.instance.getNearby(
      farmerLat: _farmerLat,
      farmerLon: _farmerLon,
      maxRadiusKm: _radiusKm,
      districtFilter: _selectedDistrict,
      commodityFilter: _selectedNearbyCrop,
      searchQuery: _searchQuery,
    );

    _applyNearbySearchFilter();
    _computeProfitResults();
  }

  void _applyNearbySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredMarkets = List.from(_allNearbyMarkets);
    } else {
      final q = _searchQuery.trim().toLowerCase();
      _filteredMarkets = _allNearbyMarkets.where((m) {
        final nameMatch = m.market.name.toLowerCase().contains(q);
        final distMatch = m.market.district.toLowerCase().contains(q);
        final stateMatch = m.market.state.toLowerCase().contains(q);
        return nameMatch || distMatch || stateMatch;
      }).toList();
    }
  }

  Future<void> _refreshGpsLocation() async {
    final loc = await LocationService.instance.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _currentProfile = _currentProfile.copyWith(
          state: loc.state,
          district: loc.district,
          selectedState: loc.state,
          selectedDistrict: loc.district,
          village: loc.village.isNotEmpty
              ? loc.village
              : _currentProfile.village,
          taluka: loc.taluka.isNotEmpty ? loc.taluka : _currentProfile.taluka,
          pincode: loc.pincode.isNotEmpty
              ? loc.pincode
              : _currentProfile.pincode,
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      });
      _refreshMandiLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS Mandi location updated successfully!'),
            backgroundColor: Color(0xFF1B5E20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _t(String en, String gu, [String? hi]) {
    try {
      final loc = Localizations.localeOf(context);
      if (loc.languageCode == 'gu') return gu;
      if (loc.languageCode == 'hi' && hi != null) return hi;
    } catch (_) {}
    final lang = LanguageService.instance.currentLanguage.code;
    if (lang == 'gu') return gu;
    if (lang == 'hi' && hi != null) return hi;
    return en;
  }

  String _formatCleanLocation(String raw, String langCode) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final match = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(trimmed);
    if (match != null) {
      final part1 = match.group(1)!.trim();
      final part2 = match.group(2)!.trim();
      if (langCode == 'gu') {
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part2)) return part2;
      } else if (langCode == 'hi') {
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part2)) return part2;
      }
      return part1.isNotEmpty ? part1 : trimmed;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final langCode = LanguageService.instance.currentLanguage.code;

    final pageTitle = _t(
      'Natural Market & APMC Mandis',
      'પ્રાકૃતિક બજાર અને APMC મંડી',
      'प्राकृतिक बाजार एवं APMC मंडी',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        actions: [
          IconButton(
            tooltip: _t('GPS લોકેશન ચાલુ કરો', 'Refresh Location'),
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _refreshGpsLocation,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF1B5E20),
              unselectedLabelColor: const Color(0xFF757575),
              indicatorColor: const Color(0xFF1B5E20),
              indicatorWeight: 3.5,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: [
                // Option 1: Nearby Mandi
                Tab(
                  icon: const Icon(Icons.near_me_rounded, size: 18),
                  text: _t('Nearby Mandi', 'નજીકની મંડી', 'नजदीकी मंडी'),
                ),
                // Option 2: Highest Price
                Tab(
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  text: _t('Highest Price', 'સૌથી વધુ ભાવ', 'सबसे अधिक भाव'),
                ),
                // Option 3: Best Estimated Net Return
                Tab(
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  text: _t(
                    'Best Estimated Net Return',
                    'વધુ ચોખ્ખી આવક',
                    'अधिक शुद्ध मुनाफा',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Feature Option 1: Nearby Mandis Directory & Relocated Snapshot
                _buildNearbyMandiTab(loc, langCode),
                // Feature Option 2: Highest Price First Rate Comparison
                _buildHighestPriceTab(langCode),
                // Feature Option 3: Profit & Net Returns Calculator
                _buildProfitCalculatorTab(langCode),
              ],
            ),
    );
  }

  // ===========================================================================
  // FEATURE OPTION 1: NEARBY MANDIS (નજીકની મંડી)
  // ===========================================================================

  Widget _buildNearbyMandiTab(AppLocalizations loc, String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Relocated Complete APMC Snapshot & Information Section
          _buildCompleteApmcSection(loc, langCode),

          const SizedBox(height: 14),

          // 2. Interactive Mandi Search Bar
          _buildMandiSearchBar(langCode),

          const SizedBox(height: 12),

          // 3. Quick Radius & District Filter Chips
          _buildRadiusAndDistrictFilters(langCode),

          const SizedBox(height: 14),

          // 4. Wholesale Market Rates & Nearby Mandis Directory Header
          _buildMandiDirectoryHeader(langCode),

          const SizedBox(height: 10),

          // 5. Market Cards
          if (_filteredMarkets.isEmpty && _gujaratApmcResults.isEmpty)
            _buildEmptyMandiState(langCode)
          else ...[
            // Verified Mandis with live rates from national database
            ..._filteredMarkets.map(
              (res) => _buildMandiRateCard(res, langCode),
            ),

            // Gujarat 226 Directory APMCs
            if (_gujaratApmcResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_shared_rounded,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _t(
                          'Gujarat APMC Directory (226 Mandis)',
                          'ગુજરાત APMC ડિરેક્ટરી (226 મંડીઓ)',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _t('226 Imported', '226 ઉપલબ્ધ'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ..._gujaratApmcResults
                  .take(20)
                  .map((item) => _buildGujaratDirectoryCard(item, langCode)),
            ],
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Complete Relocated APMC Section with original components
  Widget _buildCompleteApmcSection(AppLocalizations loc, String langCode) {
    final nearest = _allNearbyMarkets.isNotEmpty
        ? _allNearbyMarkets.first
        : null;

    final mandiTitle = _t(
      'Nearby Mandis & Wholesale Rates',
      'નજીકની મંડીઓ અને બજાર ભાવો',
      'नजदीकी मंडियां एवं बाजार भाव',
    );

    final findMandisLabel = _t('Find Mandis', 'મંડીઓ શોધો', 'मंडियां खोजें');

    final compareRatesLabel = _t(
      'Compare Rates',
      'ભાવો સરખાવો',
      'भाव तुलना करें',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE65100),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mandiTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MandiDiscoveryPage(profile: _currentProfile),
                    ),
                  );
                },
                child: Text(
                  loc.viewAll,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),

          if (nearest != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      nearest.market.type.iconEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nearest.market.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _t('Open', 'ચાલુ છે', 'खुला है'),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${nearest.distanceKm.toStringAsFixed(1)} ${_t('km away', 'કિમી દૂર', 'किमी दूर')} • ${_formatCleanLocation(nearest.market.district, langCode)}, ${_formatCleanLocation(nearest.market.state, langCode)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Primary Mandi Buttons: "મંડીઓ શોધો" and "ભાવો સરખાવો"
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GujaratApmcFinderPage(profile: _currentProfile),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.near_me_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      findMandisLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Switch to Tab 1 (Highest Price / Compare Rates)
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      compareRatesLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMandiSearchBar(String langCode) {
    final hint = _t(
      'Search Mandi or city (e.g. Ahmedabad, Rajkot)...',
      'મંડી અથવા શહેર શોધો (દા.ત. અમદાવાદ, રાજકોટ)...',
      'मंडी या शहर खोजें (उदा. अहमदाबाद, राजकोट)...',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: _mandiSearchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _refreshMandiLists();
          });
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1B5E20),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _mandiSearchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _refreshMandiLists();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusAndDistrictFilters(String langCode) {
    const radii = [25.0, 50.0, 100.0, 200.0, 500.0];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // GPS Location chip
          ActionChip(
            avatar: const Icon(
              Icons.my_location_rounded,
              size: 15,
              color: Color(0xFF1B5E20),
            ),
            label: Text(
              _currentProfile.effectiveDistrict.isNotEmpty
                  ? _currentProfile.effectiveDistrict
                  : _t('GPS Location', 'મારું લોકેશન'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFE8F5E9),
            side: const BorderSide(color: Color(0xFFA5D6A7)),
            onPressed: _refreshGpsLocation,
          ),
          const SizedBox(width: 8),

          // District filter chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: const Icon(
                Icons.location_city_rounded,
                size: 14,
                color: Color(0xFF1B5E20),
              ),
              label: Text(
                _selectedDistrict.isNotEmpty
                    ? _selectedDistrict
                    : _t('All Districts', 'બધા જિલ્લા'),
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () async {
                final districts = GujaratApmcService.instance.allDistricts;
                final picked = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(_t('Select District', 'જિલ્લો પસંદ કરો')),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: Text(_t('All Districts', 'બધા જિલ્લા')),
                      ),
                      ...districts.map(
                        (d) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, d),
                          child: Text(d),
                        ),
                      ),
                    ],
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDistrict = picked;
                    _refreshMandiLists();
                  });
                }
              },
            ),
          ),

          // Crop filter chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: const Icon(
                Icons.grass_rounded,
                size: 14,
                color: Color(0xFF1B5E20),
              ),
              label: Text(
                _selectedNearbyCrop.isNotEmpty
                    ? _selectedNearbyCrop
                    : _t('All Crops', 'બધા પાક'),
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () async {
                final picked = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(_t('Select Crop', 'પાક પસંદ કરો')),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: Text(_t('All Crops', 'બધા પાક')),
                      ),
                      ..._supportedCrops.map(
                        (c) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, c['key']),
                          child: Text(_t(c['en']!, c['gu']!)),
                        ),
                      ),
                    ],
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _selectedNearbyCrop = picked;
                    _refreshMandiLists();
                  });
                }
              },
            ),
          ),

          // Radius filter chips
          ...radii.map((r) {
            final isSelected = _radiusKm == r;
            final label = r >= 500
                ? _t('All India', 'સમગ્ર ભારત')
                : '${r.toInt()} km';
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                selected: isSelected,
                label: Text(label, style: const TextStyle(fontSize: 11)),
                selectedColor: const Color(0xFF1B5E20),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF424242),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFE0E0E0),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _radiusKm = r;
                      _refreshMandiLists();
                    });
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMandiDirectoryHeader(String langCode) {
    final title = _t(
      'Nearby Government APMC Mandis',
      'નજીકની સરકારી APMC મંડીઓ',
      'निकटवर्ती सरकारी APMC मंडियां',
    );

    final totalCount = _filteredMarkets.length + _gujaratApmcResults.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF2E7D32),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$totalCount ${_t('Mandis', 'મંડીઓ', 'मंडियां')}',
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Live Mandi Card with verified rates and Directions button
  Widget _buildMandiRateCard(MandiMarketWithDistance res, String langCode) {
    final m = res.market;
    final comparisons = MandiPriceService.instance.compareMandis(
      commodity: _selectedComparisonCrop,
      quantityQuintals: 10.0,
      farmerLat: _farmerLat,
      farmerLon: _farmerLon,
    );
    final match = comparisons.firstWhere(
      (c) => c.market.id == m.id,
      orElse: () => MandiComparisonResult(
        market: m,
        distanceKm: res.distanceKm,
        minPrice: 2200,
        maxPrice: 2600,
        modalPrice: 2450,
        quantityQuintals: 10,
        grossRevenue: 24500,
        totalTransportCost: 400,
        mandiHandlingCharges: 150,
        netSellingAmount: 23950,
        priceTime: DateTime.now(),
        isRecommended: true,
        recommendationNote: 'Official Agmarknet Price',
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8F5E9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    m.type.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCleanLocation(m.district, langCode)}, ${_formatCleanLocation(m.state, langCode)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF757575),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Text(
                    '${res.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_selectedComparisonCrop ${_t('Rate:', 'ભાવ:', 'भाव:')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${match.modalPrice.toStringAsFixed(0)} / Quintal',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Min ₹${match.minPrice.toStringAsFixed(0)} - Max ₹${match.maxPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (match.hasMsp)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFFB74D),
                                ),
                              ),
                              child: Text(
                                'MSP ₹${match.mspRecord!.officialMsp.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Directions Button
                IconButton.filledTonal(
                  tooltip: _t('Directions (Google Maps)', 'દિશા-નિર્દેશ'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  onPressed: () {
                    MandiMapNavigationHelper.openDirections(
                      context: context,
                      marketName: m.name,
                      address: m.address,
                      marketLat: m.latitude,
                      marketLon: m.longitude,
                      farmerLat: _farmerLat,
                      farmerLon: _farmerLon,
                    );
                  },
                ),
                const SizedBox(width: 6),

                // Compare Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MandiComparisonPage(profile: _currentProfile),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.compare_arrows_rounded,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                  label: Text(
                    _t('Compare', 'સરખાવો', 'तुलना'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gujarat 226 Directory Card with Directions & Details
  Widget _buildGujaratDirectoryCard(ApmcWithDistance item, String langCode) {
    final a = item.apmc;
    final isUnverified = item.distanceKm == double.infinity;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUnverified
              ? const Color(0xFFFFF9C4)
              : const Color(0xFFE8F5E9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏛️', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.displayName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${a.district}, ${a.taluka}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF616161),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isUnverified
                        ? const Color(0xFFFFF9C4)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isUnverified
                        ? _t('Gujarat', 'ગુજરાત')
                        : '${item.distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUnverified
                          ? const Color(0xFFF9A825)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Call button
                if (a.contactSummary.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                    ),
                    icon: const Icon(
                      Icons.call_rounded,
                      size: 14,
                      color: Color(0xFF1B5E20),
                    ),
                    label: Text(
                      _t('Call', 'કોલ કરો'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    onPressed: () {
                      MandiMapNavigationHelper.makePhoneCall(
                        context: context,
                        rawPhone: a.contactSummary,
                      );
                    },
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      side: const BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    icon: const Icon(
                      Icons.phone_disabled_rounded,
                      size: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    label: Text(
                      _t('Contact not verified', 'સંપર્ક ઉપલબ્ધ નથી'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    onPressed: null,
                  ),

                // Directions button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                  icon: const Icon(
                    Icons.directions_rounded,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                  label: Text(
                    _t('Directions', 'દિશા-નિર્દેશ'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  onPressed: () {
                    MandiMapNavigationHelper.openDirections(
                      context: context,
                      marketName: a.displayName,
                      address: a.address,
                      marketLat: a.latitude,
                      marketLon: a.longitude,
                      farmerLat: _farmerLat,
                      farmerLon: _farmerLon,
                    );
                  },
                ),

                // Details button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GujaratApmcDetailPage(
                          apmc: a,
                          farmerLat: _farmerLat,
                          farmerLon: _farmerLon,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _t('Details', 'વિગતો'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMandiState(String langCode) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'No APMC mandis match your search.',
              'કોઈ મંડી મળી નથી.',
              'कोई मंडी नहीं मिली।',
            ),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FEATURE OPTION 2: HIGHEST PRICE FIRST (સૌથી વધુ ભાવ)
  // ===========================================================================

  Widget _buildHighestPriceTab(String langCode) {
    // 1. Fetch all comparable mandis for selected crop
    final comparisons = MandiPriceService.instance.compareMandis(
      commodity: _selectedComparisonCrop,
      quantityQuintals: 10.0,
      farmerLat: _farmerLat,
      farmerLon: _farmerLon,
    );

    // 2. Apply sorting:
    // 0 = Highest Price First (numeric modalPrice descending; tie-break: nearer distance, then name)
    // 1 = Nearest Mandi First (numeric distanceKm ascending; tie-break: higher price, then name)
    // 2 = Lowest Price First (numeric modalPrice ascending; tie-break: nearer distance, then name)
    final sorted = List<MandiComparisonResult>.from(comparisons);
    if (_comparisonSortMode == 0) {
      sorted.sort((a, b) {
        final cmp = b.modalPrice.compareTo(a.modalPrice);
        if (cmp != 0) return cmp;
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        return a.market.name.compareTo(b.market.name);
      });
    } else if (_comparisonSortMode == 1) {
      sorted.sort((a, b) {
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        final cmp = b.modalPrice.compareTo(a.modalPrice);
        if (cmp != 0) return cmp;
        return a.market.name.compareTo(b.market.name);
      });
    } else if (_comparisonSortMode == 2) {
      sorted.sort((a, b) {
        final cmp = a.modalPrice.compareTo(b.modalPrice);
        if (cmp != 0) return cmp;
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        return a.market.name.compareTo(b.market.name);
      });
    }

    final sortLabel = _comparisonSortMode == 0
        ? _t(
            'Sort By: Highest Price First',
            'ક્રમ: સૌથી વધુ ભાવ પ્રથમ',
            'क्रम: सबसे अधिक भाव पहले',
          )
        : (_comparisonSortMode == 1
              ? _t(
                  'Sort By: Nearest Mandi First',
                  'ક્રમ: સૌથી નજીકની મંડી પ્રથમ',
                  'क्रम: नजदीकी मंडी पहले',
                )
              : _t(
                  'Sort By: Lowest Price First',
                  'ક્રમ: સૌથી ઓછો ભાવ પ્રથમ',
                  'क्रम: सबसे कम भाव पहले',
                ));

    final topBannerLabel = _comparisonSortMode == 0
        ? _t('🏆 Highest Verified Rate Today', '🏆 આજના સૌથી વધુ ચકાસાયેલા ભાવ')
        : (_comparisonSortMode == 1
              ? _t('📍 Nearest Verified Mandi', '📍 સૌથી નજીકની ચકાસાયેલી મંડી')
              : _t('📉 Lowest Available Rate', '📉 સૌથી ઓછો ઉપલબ્ધ ભાવ'));

    final topRateMarket = sorted.isNotEmpty ? sorted.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Crop Selector
          _buildCropSelectorRow(langCode),

          const SizedBox(height: 12),

          // Sort Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                initialValue: _comparisonSortMode,
                onSelected: (mode) =>
                    setState(() => _comparisonSortMode = mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _comparisonSortMode == 0
                            ? _t('Highest Price', 'સૌથી વધુ ભાવ')
                            : (_comparisonSortMode == 1
                                  ? _t('Nearest', 'સૌથી નજીક')
                                  : _t('Lowest Price', 'સૌથી ઓછો ભાવ')),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 0,
                    child: Text(
                      _t('Highest Price First', 'સૌથી વધુ ભાવ પ્રથમ'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Text(_t('Nearest Mandi First', 'સૌથી નજીકની મંડી')),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(_t('Lowest Price First', 'સૌથી ઓછો ભાવ')),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Top Rate Highlight Card
          if (topRateMarket != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            topBannerLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Agmarknet',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topRateMarket.market.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${topRateMarket.distanceKm.toStringAsFixed(1)} km away • ${topRateMarket.market.district}, ${topRateMarket.market.state}',
                    style: const TextStyle(
                      color: Color(0xFFC8E6C9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('Modal Rate:', 'મોડલ ભાવ:'),
                              style: const TextStyle(
                                color: Color(0xFFA5D6A7),
                                fontSize: 11,
                              ),
                            ),
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₹${topRateMarket.modalPrice.toStringAsFixed(0)} / Quintal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: Text(_t('Directions', 'દિશા-નિર્દેશ')),
                        onPressed: () {
                          MandiMapNavigationHelper.openDirections(
                            context: context,
                            marketName: topRateMarket.market.name,
                            address: topRateMarket.market.address,
                            marketLat: topRateMarket.market.latitude,
                            marketLon: topRateMarket.market.longitude,
                            farmerLat: _farmerLat,
                            farmerLon: _farmerLon,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // List of All Comparable Mandis
          Text(
            '${sorted.length} ${_t('Mandis reporting prices for', 'મંડીઓમાં ભાવ ઉપલબ્ધ:')} $_selectedComparisonCrop',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),

          if (sorted.isEmpty)
            _buildEmptyMandiState(langCode)
          else
            ...sorted.map(
              (item) => _buildComparisonRateCard(item, topRateMarket, langCode),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCropSelectorRow(String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(
            'Select Crop for Rate Comparison:',
            'ભાવ સરખામણી માટે પાક પસંદ કરો:',
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _supportedCrops.map((c) {
              final isSelected = _selectedComparisonCrop == c['en'];
              final label = langCode == 'gu' ? c['gu']! : c['en']!;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1B5E20),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF424242),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE0E0E0),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedComparisonCrop = c['en']!;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRateCard(
    MandiComparisonResult item,
    MandiComparisonResult? topItem,
    String langCode,
  ) {
    final isTop = topItem != null && item.market.id == topItem.market.id;
    final priceDiff = topItem != null
        ? topItem.modalPrice - item.modalPrice
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isTop ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.market.type.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.market.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.market.district}, ${item.market.state} • ${item.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF757575),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.modalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const Text(
                      'per Quintal',
                      style: TextStyle(fontSize: 10, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Min ₹${item.minPrice.toStringAsFixed(0)} - Max ₹${item.maxPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.hasMsp) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFB74D)),
                          ),
                          child: Text(
                            'MSP ₹${item.mspRecord!.officialMsp.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        if (item.mspDifference != null)
                          Text(
                            item.mspDifference! >= 0
                                ? '+₹${item.mspDifference!.toStringAsFixed(0)} vs MSP'
                                : '-₹${item.mspDifference!.abs().toStringAsFixed(0)} vs MSP',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: item.mspDifference! >= 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD32F2F),
                            ),
                          ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _t('MSP N/A', 'MSP લાગુ નથી'),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                        ),
                      ],
                      if (!isTop && priceDiff > 0)
                        Text(
                          '-₹${priceDiff.toStringAsFixed(0)} vs Top',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Directions Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: _t('Directions', 'દિશા-નિર્દેશ'),
                  icon: const Icon(
                    Icons.directions_rounded,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                  onPressed: () {
                    MandiMapNavigationHelper.openDirections(
                      context: context,
                      marketName: item.market.name,
                      address: item.market.address,
                      marketLat: item.market.latitude,
                      marketLon: item.market.longitude,
                      farmerLat: _farmerLat,
                      farmerLon: _farmerLon,
                    );
                  },
                ),

                // Details Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    // Pre-fill profit tab with this mandi
                    setState(() {
                      _profitCrop = _selectedComparisonCrop;
                      _customPriceController.text = item.modalPrice
                          .toStringAsFixed(0);
                    });
                    _tabController.animateTo(2);
                  },
                  child: Text(
                    _t('Profit', 'નફો'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FEATURE OPTION 3: BEST ESTIMATED NET RETURN (વધુ ચોખ્ખી આવક)
  // ===========================================================================

  Widget _buildProfitCalculatorTab(String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Interactive Inputs Card
          _buildProfitInputCard(langCode),

          const SizedBox(height: 16),

          // 2. Results Section
          if (_profitRankedResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                _t(
                  'Tap "Calculate Net Return" above to compare proceeds across all mandis.',
                  'મંડીઓની ચોખ્ખી આવક સરખાવવા ઉપર "ચોખ્ખી આવક ગણો" બટન દબાવો.',
                ),
                style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Text(
              _t(
                'Ranked by Best Estimated Net Return (After Transport):',
                'ચોખ્ખી આવક પ્રમાણે ક્રમ (પરિવહન ખર્ચ બાદ):',
                'शुद्ध मुनाफे के अनुसार क्रम (परिवहन खर्च बाद):',
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),

            ..._profitRankedResults.map(
              (item) => _buildProfitResultCard(item, langCode),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfitInputCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
            children: [
              const Icon(
                Icons.calculate_rounded,
                color: Color(0xFF1B5E20),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(
                    'Farmer Net Proceeds Calculator',
                    'ખેડૂત ચોખ્ખી આવક કેલ્ક્યુલેટર',
                    'किसान शुद्ध मुनाफा कैलकुलेटर',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          // Crop Selector
          Text(
            _t('Crop produce:', 'પાક:'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _profitCrop,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: _supportedCrops.map((c) {
              final label = langCode == 'gu' ? c['gu']! : c['en']!;
              return DropdownMenuItem(value: c['en'], child: Text(label));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _profitCrop = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          // Quantity & Unit
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Quantity:', 'જથ્થો:'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: 'e.g. 20',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Unit:', 'એકમ:'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _quantityUnit = 'Quintal'),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _quantityUnit == 'Quintal'
                                      ? const Color(0xFF1B5E20)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Qtl',
                                  style: TextStyle(
                                    color: _quantityUnit == 'Quintal'
                                        ? Colors.white
                                        : const Color(0xFF424242),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _quantityUnit = 'Kg'),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _quantityUnit == 'Kg'
                                      ? const Color(0xFF1B5E20)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Kg',
                                  style: TextStyle(
                                    color: _quantityUnit == 'Kg'
                                        ? Colors.white
                                        : const Color(0xFF424242),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transport Rate & Other Expenses
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Transport (₹/km):', 'વાહન ખર્ચ (₹/કિમી):'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _transportRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: '5.0',
                      ),
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
                      _t('Other Exp. (₹):', 'અન્ય ખર્ચ (₹):'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _otherExpensesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: '0',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action: Calculate Net Return
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calculate_rounded, size: 18),
              label: Text(
                _t(
                  'Calculate Best Net Return',
                  'વધુ ચોખ્ખી આવક ગણો',
                  'अधिकतम शुद्ध मुनाफा निकालें',
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _computeProfitResults();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _computeProfitResults() {
    final rawQty = double.tryParse(_quantityController.text.trim()) ?? 20.0;
    final double qtyQuintals = _quantityUnit == 'Kg' ? rawQty / 100.0 : rawQty;
    final transportPerKm =
        double.tryParse(_transportRateController.text.trim()) ?? 5.0;
    final otherExp =
        double.tryParse(_otherExpensesController.text.trim()) ?? 0.0;

    final comparisons = MandiPriceService.instance.compareMandis(
      commodity: _profitCrop,
      quantityQuintals: qtyQuintals,
      farmerLat: _farmerLat,
      farmerLon: _farmerLon,
    );

    final results = <_ProfitMarketItem>[];

    for (final c in comparisons) {
      final gross = c.modalPrice * qtyQuintals;
      final transport = c.distanceKm * transportPerKm;
      final net = gross - transport - otherExp;

      results.add(
        _ProfitMarketItem(
          marketName: c.market.name,
          address: c.market.address,
          district: c.market.district,
          state: c.market.state,
          distanceKm: c.distanceKm,
          modalPrice: c.modalPrice,
          quantityQuintals: qtyQuintals,
          grossRevenue: gross,
          transportCost: transport,
          otherExpenses: otherExp,
          netProceeds: net,
          latitude: c.market.latitude,
          longitude: c.market.longitude,
          isBest: false,
        ),
      );
    }

    // Sort descending by net proceeds
    results.sort((a, b) => b.netProceeds.compareTo(a.netProceeds));

    if (results.isNotEmpty) {
      results[0] = results[0].copyWith(isBest: true);
    }

    setState(() {
      _profitRankedResults = results;
    });
  }

  Widget _buildProfitResultCard(_ProfitMarketItem item, String langCode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: item.isBest ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isBest
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE0E0E0),
          width: item.isBest ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.isBest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 15,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _t(
                          '🏆 Best Estimated Net Return',
                          '🏆 સૌથી વધુ ચોખ્ખી આવક',
                          '🏆 सबसे अधिक शुद्ध मुनाफा',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.marketName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.district}, ${item.state} • ${item.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.netProceeds.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: item.isBest
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      _t('Net Proceeds', 'ચોખ્ખી આવક', 'शुद्ध राशि'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Financial Breakdown Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _costColumn(
                      label: _t('Gross', 'કુલ વેચાણ'),
                      value: '₹${item.grossRevenue.toStringAsFixed(0)}',
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Expanded(
                    child: _costColumn(
                      label: _t('Transport', 'પરિવહન'),
                      value: '-₹${item.transportCost.toStringAsFixed(0)}',
                      color: const Color(0xFFD32F2F),
                    ),
                  ),
                  Expanded(
                    child: _costColumn(
                      label: _t('Rate/Qtl', 'ભાવ/ક્વિ.'),
                      value: '₹${item.modalPrice.toStringAsFixed(0)}',
                      color: const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Directions button
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
                    _t('Directions', 'દિશા-નિર્દેશ'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  onPressed: () {
                    MandiMapNavigationHelper.openDirections(
                      context: context,
                      marketName: item.marketName,
                      address: item.address,
                      marketLat: item.latitude,
                      marketLon: item.longitude,
                      farmerLat: _farmerLat,
                      farmerLon: _farmerLon,
                    );
                  },
                ),

                // Details / Gujarat APMC detail
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GujaratApmcFinderPage(profile: _currentProfile),
                      ),
                    );
                  },
                  child: Text(
                    _t('View Mandi', 'મંડી જુઓ'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _costColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProfitMarketItem {
  final String marketName;
  final String address;
  final String district;
  final String state;
  final double distanceKm;
  final double modalPrice;
  final double quantityQuintals;
  final double grossRevenue;
  final double transportCost;
  final double otherExpenses;
  final double netProceeds;
  final double? latitude;
  final double? longitude;
  final bool isBest;

  const _ProfitMarketItem({
    required this.marketName,
    required this.address,
    required this.district,
    required this.state,
    required this.distanceKm,
    required this.modalPrice,
    required this.quantityQuintals,
    required this.grossRevenue,
    required this.transportCost,
    required this.otherExpenses,
    required this.netProceeds,
    this.latitude,
    this.longitude,
    this.isBest = false,
  });

  _ProfitMarketItem copyWith({bool? isBest}) {
    return _ProfitMarketItem(
      marketName: marketName,
      address: address,
      district: district,
      state: state,
      distanceKm: distanceKm,
      modalPrice: modalPrice,
      quantityQuintals: quantityQuintals,
      grossRevenue: grossRevenue,
      transportCost: transportCost,
      otherExpenses: otherExpenses,
      netProceeds: netProceeds,
      latitude: latitude,
      longitude: longitude,
      isBest: isBest ?? this.isBest,
    );
  }
}
