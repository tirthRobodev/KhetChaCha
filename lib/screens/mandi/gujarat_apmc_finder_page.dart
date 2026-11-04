import 'package:flutter/material.dart';

import '../../models/farmer_profile.dart';
import '../../services/gujarat_apmc_service.dart';
import '../../services/language_service.dart';
import '../../services/location_service.dart';
import '../../services/mandi_map_navigation_helper.dart';
import 'gujarat_apmc_detail_page.dart';
import 'gujarat_apmc_profit_page.dart';

/// Gujarat Smart APMC Mandi Finder
/// Loads 226 APMC entries from bundled directory, finds nearby mandis,
/// filters by crop, district and radius, and launches profit comparison.
class GujaratApmcFinderPage extends StatefulWidget {
  final FarmerProfile profile;

  const GujaratApmcFinderPage({super.key, required this.profile});

  @override
  State<GujaratApmcFinderPage> createState() => _GujaratApmcFinderPageState();
}

class _GujaratApmcFinderPageState extends State<GujaratApmcFinderPage> {
  final _searchController = TextEditingController();
  final _service = GujaratApmcService.instance;

  bool _loading = true;
  bool _locating = false;
  String _errorMsg = '';

  double _farmerLat = 23.0225;
  double _farmerLon = 72.5714;
  String _locationLabel = '';
  bool _locationDetected = false;

  String _selectedDistrict = '';
  String _selectedCrop = '';
  double _radiusKm = 50.0;
  String _searchQuery = '';

  // Sort options
  static const int _sortNearest = 0;
  static const int _sortDistrict = 1;
  int _sortMode = _sortNearest;

  List<ApmcWithDistance> _results = [];
  List<String> _districts = [];

  static const List<Map<String, String>> _crops = [
    {'en': 'All Crops', 'gu': 'બધા પાક', 'key': ''},
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
    {'en': 'Fruits', 'gu': 'ફળ', 'key': 'fruits'},
    {'en': 'Vegetables', 'gu': 'શાકભાજી', 'key': 'vegetables'},
  ];

  @override
  void initState() {
    super.initState();
    _initFromProfile();
    _loadData();
  }

  void _initFromProfile() {
    final p = widget.profile;
    _farmerLat = p.latitude ?? 23.0225;
    _farmerLon = p.longitude ?? 72.5714;
    final loc = p.effectiveDistrict.isNotEmpty
        ? '${p.effectiveDistrict}, ${p.effectiveState}'
        : p.effectiveState;
    _locationLabel = loc;
    _locationDetected = p.latitude != null;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      await _service.ensureLoaded();
      _districts = _service.allDistricts;
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMsg = 'ડેટા લોડ કરવામાં ભૂલ. / Error loading APMC data.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var results = _service.getNearby(
      farmerLat: _farmerLat,
      farmerLon: _farmerLon,
      maxRadiusKm: _radiusKm,
      districtFilter: _selectedDistrict,
      commodityFilter: _selectedCrop,
      searchQuery: _searchQuery,
    );

    if (_sortMode == _sortDistrict) {
      results.sort((a, b) => a.apmc.district.compareTo(b.apmc.district));
    }

    setState(() {
      _results = results;
    });
  }

  Future<void> _detectGpsLocation() async {
    setState(() {
      _locating = true;
    });
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (loc != null && mounted) {
        setState(() {
          _farmerLat = loc.latitude;
          _farmerLon = loc.longitude;
          _locationDetected = true;
          _locationLabel = loc.district.isNotEmpty
              ? '${loc.district}, ${loc.state}'
              : loc.state;
        });
        _applyFilters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 $_locationLabel'),
              backgroundColor: const Color(0xFF1B5E20),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS unavailable. Please select district manually.'),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location error. Check GPS/permission settings.'),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  void _openDistrictPicker() async {
    final lang = LanguageService.instance.currentLanguage.code;
    final title = lang == 'gu' ? 'જિલ્લો પસંદ કરો' : 'Select District';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _DistrictPickerDialog(
        districts: _districts,
        selected: _selectedDistrict,
        title: title,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedDistrict = result;
      });
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _t(String gu, String en) {
    final lang = LanguageService.instance.currentLanguage.code;
    return lang == 'gu' ? gu : (lang == 'hi' ? en : en);
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
              _t('ગુજરાત APMC મંડી ફાઇન્ડર', 'Gujarat APMC Mandi Finder'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _t(
                '226 સત્તાવાર APMC • ${_results.length} મળ્યા',
                '226 Official APMCs • ${_results.length} found',
              ),
              style: const TextStyle(fontSize: 11, color: Color(0xFFB9F6CA)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _t('ફ઼િલ્ટર', 'Filters'),
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : Column(
              children: [
                _buildTopSection(lang),
                _buildSearchBar(lang),
                _buildSortAndCount(lang),
                Expanded(child: _buildResultsList(lang)),
              ],
            ),
      bottomNavigationBar: _buildProfitFab(),
    );
  }

  Widget _buildTopSection(String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Location row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _locationDetected
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: _locationDetected
                      ? const Color(0xFF69F0AE)
                      : Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationLabel.isNotEmpty
                        ? '${_t('તમારું સ્થાન:', 'Your location:')} $_locationLabel'
                        : _t('સ્થાન ઓળખ્યું નથી', 'Location not detected'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _locating ? null : _detectGpsLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1B5E20),
                            ),
                          )
                        : Text(
                            _t('GPS', 'GPS'),
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Crop selection chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final crop = _crops[i];
                final key = crop['key']!;
                final label = lang == 'gu' ? crop['gu']! : crop['en']!;
                final selected = _selectedCrop == key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCrop = key;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF69F0AE)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: selected
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? const Color(0xFF1B5E20)
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: _t(
            'APMC, જિલ્લો, તાલુકો, PIN શોધો...',
            'Search APMC, district, taluka, PIN...',
          ),
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1B5E20),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
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

  Widget _buildSortAndCount(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedDistrict.isNotEmpty
                  ? '$_selectedDistrict • ${_results.length} ${_t('મંડીઓ', 'APMCs')}'
                  : '${_results.length} ${_t('APMC મળ્યા', 'APMCs found')} • ${_radiusKm.toInt()} km',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Sort toggle
          Row(
            children: [
              _sortChip(
                _t('નજીક', 'Nearest'),
                _sortNearest,
                Icons.near_me_rounded,
              ),
              const SizedBox(width: 6),
              _sortChip(
                _t('જિલ્લો', 'District'),
                _sortDistrict,
                Icons.location_city_rounded,
              ),
            ],
          ),
          if (_selectedDistrict.isNotEmpty) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDistrict = '';
                });
                _applyFilters();
              },
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sortChip(String label, int mode, IconData icon) {
    final selected = _sortMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortMode = mode;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1B5E20) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? Colors.white : const Color(0xFF616161),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF616161),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(String lang) {
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMsg,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(lang);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildApmcCard(_results[i], lang),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'પસંદ કરેલ ત્રિજ્યામાં APMC મળ્યા નથી.\nત્રિજ્યા વધારો અથવા જિલ્લો બદલો.',
              'No APMCs found in selected radius.\nIncrease radius or change district.',
            ),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: Text(_t('ફ઼િલ્ટર બદલો', 'Change Filters')),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2E7D32)),
              foregroundColor: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApmcCard(ApmcWithDistance item, String lang) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(a),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commodity icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnverified
                          ? const Color(0xFFFFFDE7)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _commodityEmoji(a.commodities),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a.district}, ${a.taluka}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF616161),
                          ),
                        ),
                        if (a.pincode.isNotEmpty)
                          Text(
                            'PIN: ${a.pincode}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Distance badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isUnverified
                              ? const Color(0xFFFFF9C4)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnverified
                                ? const Color(0xFFFFEE58)
                                : const Color(0xFFA5D6A7),
                          ),
                        ),
                        child: Text(
                          isUnverified
                              ? _t('GPS અ.', 'Unverif.')
                              : '${item.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isUnverified
                                ? const Color(0xFFF9A825)
                                : const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (a.hasPhysicalYard) ...[
                        const SizedBox(height: 4),
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
                            _t('ખુલ્લું', 'Open'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              if (a.commodities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: a.commodities
                      .take(5)
                      .map((c) => _commodityChip(c))
                      .toList(),
                ),
              ],

              const Divider(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _openDetail(a),
                      child: Text(
                        _t('વિગતો', 'Details'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _openProfit(a),
                      child: Text(
                        _t('નફો ગણો', 'Profit'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    tooltip: _t('દિશા-નિર્દેશ', 'Directions'),
                    icon: const Icon(
                      Icons.directions_rounded,
                      size: 20,
                      color: Color(0xFF1B5E20),
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
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    tooltip: _t('સરખાવો', 'Compare'),
                    icon: const Icon(
                      Icons.compare_arrows_rounded,
                      size: 20,
                      color: Color(0xFF2E7D32),
                    ),
                    onPressed: () => _openProfit(a),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _commodityChip(String commodity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Text(
        commodity,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF33691E),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProfitFab() {
    final lang = LanguageService.instance.currentLanguage.code;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            onPressed: () => _openProfitComparison(),
            icon: const Icon(Icons.calculate_rounded, size: 20),
            label: Text(
              lang == 'gu'
                  ? '${_results.length} મંડીઓ માટે ભાવ સરખામણી અને નફો ગણો'
                  : 'Compare Prices & Calculate Profit (${_results.length} APMCs)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(GujaratApmcEntry apmc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GujaratApmcDetailPage(
          apmc: apmc,
          farmerLat: _farmerLat,
          farmerLon: _farmerLon,
        ),
      ),
    );
  }

  void _openProfit(GujaratApmcEntry apmc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GujaratApmcProfitPage(
          profile: widget.profile,
          initialApmc: apmc,
          farmerLat: _farmerLat,
          farmerLon: _farmerLon,
          nearbyResults: _results,
          initialCrop: _selectedCrop,
        ),
      ),
    );
  }

  void _openProfitComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GujaratApmcProfitPage(
          profile: widget.profile,
          initialApmc: _results.isNotEmpty ? _results.first.apmc : null,
          farmerLat: _farmerLat,
          farmerLon: _farmerLon,
          nearbyResults: _results,
          initialCrop: _selectedCrop,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final lang = LanguageService.instance.currentLanguage.code;
    final radii = [10.0, 25.0, 50.0, 100.0, 200.0, 500.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang == 'gu' ? 'ફ઼િલ્ટર' : 'Filters',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDistrict = '';
                          _selectedCrop = '';
                          _radiusKm = 50.0;
                        });
                        _applyFilters();
                        Navigator.pop(ctx);
                      },
                      child: Text(lang == 'gu' ? 'સાફ' : 'Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  lang == 'gu' ? 'શોધ ત્રિજ્યા' : 'Search Radius',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: radii.map((r) {
                    final sel = _radiusKm == r;
                    return ChoiceChip(
                      label: Text('${r.toInt()} km'),
                      selected: sel,
                      selectedColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _radiusKm = r;
                        });
                        setS(() {});
                        _applyFilters();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  lang == 'gu' ? 'જિલ્લો' : 'District',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openDistrictPicker();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFBDBDBD)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDistrict.isNotEmpty
                                ? _selectedDistrict
                                : (lang == 'gu'
                                      ? 'બધા જિલ્લા'
                                      : 'All Districts'),
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDistrict.isNotEmpty
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(lang == 'gu' ? 'લાગુ કરો' : 'Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _commodityEmoji(List<String> commodities) {
    if (commodities.isEmpty) return '🏛️';
    final first = commodities.first.toLowerCase();
    if (first.contains('cotton')) return '🌿';
    if (first.contains('wheat') || first.contains('grain')) return '🌾';
    if (first.contains('paddy') || first.contains('rice')) return '🌾';
    if (first.contains('onion')) return '🧅';
    if (first.contains('potato')) return '🥔';
    if (first.contains('tomato')) return '🍅';
    if (first.contains('groundnut')) return '🥜';
    if (first.contains('cumin') || first.contains('jeera')) return '🌱';
    if (first.contains('castor')) return '🌱';
    if (first.contains('fruits') ||
        first.contains('mango') ||
        first.contains('banana')) {
      return '🍎';
    }
    if (first.contains('vegetable') || first.contains('sabji')) return '🥦';
    if (first.contains('mustard')) return '🌻';
    if (first.contains('spice')) return '🌶️';
    return '🏛️';
  }
}

/// Simple district picker dialog
class _DistrictPickerDialog extends StatefulWidget {
  final List<String> districts;
  final String selected;
  final String title;

  const _DistrictPickerDialog({
    required this.districts,
    required this.selected,
    required this.title,
  });

  @override
  State<_DistrictPickerDialog> createState() => _DistrictPickerDialogState();
}

class _DistrictPickerDialogState extends State<_DistrictPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.districts
        : widget.districts
              .where((d) => d.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() {
                _query = v;
              }),
              decoration: InputDecoration(
                hintText: 'Search district...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.public_rounded,
                size: 16,
                color: Color(0xFF2E7D32),
              ),
              title: const Text(
                'All Districts',
                style: TextStyle(fontSize: 13),
              ),
              selected: widget.selected.isEmpty,
              selectedColor: const Color(0xFF1B5E20),
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_city_rounded,
                    size: 16,
                    color: filtered[i] == widget.selected
                        ? const Color(0xFF1B5E20)
                        : Colors.grey,
                  ),
                  title: Text(
                    filtered[i],
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: filtered[i] == widget.selected,
                  selectedColor: const Color(0xFF1B5E20),
                  onTap: () => Navigator.pop(context, filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
