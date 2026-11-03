import 'package:flutter/material.dart';

import '../../models/farmer_profile.dart';
import '../../models/mandi_market.dart';
import '../../services/mandi_discovery_service.dart';
import '../onboarding/smart_location_detection_page.dart';
import 'mandi_comparison_page.dart';

/// Screen enabling farmers to discover nearby APMC and wholesale markets
/// with real-time geo-distance calculation, Agmarknet commodity prices, and filtering.
class MandiDiscoveryPage extends StatefulWidget {
  final FarmerProfile profile;

  const MandiDiscoveryPage({super.key, required this.profile});

  @override
  State<MandiDiscoveryPage> createState() => _MandiDiscoveryPageState();
}

class _MandiDiscoveryPageState extends State<MandiDiscoveryPage> {
  final _searchController = TextEditingController();
  MandiMarketType? _selectedTypeFilter;
  String? _selectedCommodity;

  late double _farmerLat;
  late double _farmerLon;
  late String _locationSummary;

  @override
  void initState() {
    super.initState();
    _initCoordinates();
  }

  void _initCoordinates() {
    final p = widget.profile;
    _farmerLat =
        p.latitude ??
        (p.effectiveState.toLowerCase().contains('punjab') ? 30.9010 : 23.0225);
    _farmerLon =
        p.longitude ??
        (p.effectiveState.toLowerCase().contains('punjab') ? 75.8573 : 72.5714);
    _locationSummary = '${p.effectiveDistrict}, ${p.effectiveState}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChangeLocation() async {
    final updated = await Navigator.of(context).push<FarmerProfile>(
      MaterialPageRoute(
        builder: (_) => SmartLocationDetectionPage(
          profile: widget.profile,
          isEditMode: true,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _farmerLat = updated.latitude ?? _farmerLat;
        _farmerLon = updated.longitude ?? _farmerLon;
        _locationSummary =
            '${updated.effectiveDistrict}, ${updated.effectiveState}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketsWithDistance = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: _farmerLat,
      longitude: _farmerLon,
      typeFilter: _selectedTypeFilter,
      commodityFilter: _selectedCommodity,
      searchQuery: _searchController.text,
      maxDistanceKm: 350.0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Mandi & Wholesale Markets',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Compare Mandi Rates',
            icon: const Icon(
              Icons.compare_arrows_rounded,
              color: Color(0xFFFFD54F),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MandiComparisonPage(profile: widget.profile),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Location Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Markets near $_locationSummary',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _openChangeLocation,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search market, commodity, district, PIN...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF2E7D32),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Type Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Markets', null),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          '🥦 Sabzi Mandi',
                          MandiMarketType.vegetableWholesale,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          '🌾 Grain (Anaaj)',
                          MandiMarketType.grainMarket,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          '🏛️ APMC Principal',
                          MandiMarketType.apmcMandi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Market Listings
            Expanded(
              child: marketsWithDistance.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.store_mall_directory_outlined,
                            size: 64,
                            color: Color(0xFFBDBDBD),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No mandis matched your search radius.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedTypeFilter = null;
                                _selectedCommodity = null;
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: marketsWithDistance.length,
                      itemBuilder: (ctx, index) {
                        final item = marketsWithDistance[index];
                        return _buildMandiCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, MandiMarketType? type) {
    final isSel = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFFE8F5E9),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSel ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? const Color(0xFF1B5E20) : const Color(0xFF616161),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedTypeFilter = selected ? type : null;
        });
      },
    );
  }

  Widget _buildMandiCard(MandiMarketWithDistance item) {
    final m = item.market;
    final distFormatted = item.distanceKm < 1.0
        ? '${(item.distanceKm * 1000).toStringAsFixed(0)} meters'
        : '${item.distanceKm.toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Card Header with Type & Distance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            m.type.iconEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: Color(0xFF2E7D32),
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distFormatted,
                        style: const TextStyle(
                          fontSize: 11.5,
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

          // Operational Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 4),
                Text(
                  m.openingHours,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF616161),
                  ),
                ),
                if (m.contactPhone.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.contactPhone,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Commodity Prices Ticker
          if (m.commodityPrices.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFAFAFA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Verified Mandi Rates:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: m.commodityPrices.take(4).map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.commodity,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${p.modalPrice.toStringAsFixed(0)}/Q',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Market directions to ${m.name} (${m.latitude}, ${m.longitude})',
                          ),
                          backgroundColor: const Color(0xFF1B5E20),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.directions_rounded,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                    label: const Text(
                      'Directions',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MandiComparisonPage(
                            profile: widget.profile,
                            initialCommodity: m.commodityPrices.isNotEmpty
                                ? m.commodityPrices.first.commodity
                                : 'Wheat',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text(
                      'Compare Rates',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
