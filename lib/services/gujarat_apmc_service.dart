import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// A single Gujarat APMC/market entry sourced from the official PDF directory.
class GujaratApmcEntry {
  final String apmcId;
  final String name;
  final String state;
  final String district;
  final String taluka;
  final String pincode;
  final String address;
  final String marketType;
  final List<String> commodities;
  final String contactPerson;
  final String officePhone;
  final String mobile;
  final String email;
  final double? latitude;
  final double? longitude;
  final bool locationVerified;
  final String locationNote;
  final String source;

  const GujaratApmcEntry({
    required this.apmcId,
    required this.name,
    required this.state,
    required this.district,
    required this.taluka,
    required this.pincode,
    required this.address,
    required this.marketType,
    required this.commodities,
    required this.contactPerson,
    required this.officePhone,
    required this.mobile,
    required this.email,
    this.latitude,
    this.longitude,
    this.locationVerified = false,
    this.locationNote = '',
    required this.source,
  });

  factory GujaratApmcEntry.fromJson(Map<String, dynamic> j) {
    return GujaratApmcEntry(
      apmcId: j['apmc_id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      state: j['state'] as String? ?? 'Gujarat',
      district: j['district'] as String? ?? '',
      taluka: j['taluka'] as String? ?? '',
      pincode: j['pincode'] as String? ?? '',
      address: j['address'] as String? ?? '',
      marketType: j['market_type'] as String? ?? '',
      commodities:
          (j['commodities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      contactPerson: j['contact_person'] as String? ?? '',
      officePhone: j['office_phone'] as String? ?? '',
      mobile: j['mobile'] as String? ?? '',
      email: j['email'] as String? ?? '',
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      locationVerified: j['location_verified'] as bool? ?? false,
      locationNote: j['location_note'] as String? ?? '',
      source: j['source'] as String? ?? 'Gujarat_All_APMC_List.pdf',
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasPhysicalYard {
    final mt = marketType.toLowerCase();
    return !mt.contains('no market') && !mt.contains('only office');
  }

  /// Whether this APMC trades a given commodity (English fuzzy match)
  bool tradesCommodity(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return commodities.any(
      (c) =>
          c.toLowerCase().contains(q) ||
          q.contains(c.toLowerCase()) ||
          _synonymMatch(c.toLowerCase(), q),
    );
  }

  static bool _synonymMatch(String commodity, String query) {
    const synonyms = {
      'wheat': ['ઘઉં', 'gehun', 'lokwan', 'sharbati', 'tukdi'],
      'cotton': ['કપાસ', 'kapas', 'narma', 'shankar'],
      'groundnut': ['મગફળી', 'moongphali', 'peanut', 'g-20'],
      'cumin': ['જીરું', 'jeera', 'jiru'],
      'castor': ['એરંડા', 'eranda', 'divela'],
      'maize': ['મકાઈ', 'corn', 'makai', 'makai'],
      'paddy': ['ડાંગર', 'rice', 'dangar', 'dhan'],
      'onion': ['ડુંગળી', 'dungali', 'pyaj', 'kanda'],
      'potato': ['બટાકા', 'bataka', 'aloo', 'alu'],
      'tomato': ['ટામેટાં', 'tamatam', 'tamatar'],
      'bajra': ['બાજરી', 'bajri', 'millet', 'pearl millet'],
      'sesame': ['તલ', 'tal', 'til'],
      'gram': ['ચણા', 'chana', 'chickpea', 'chole'],
      'soybean': ['સોયાબીન', 'soya'],
      'mustard': ['સરસવ', 'sarso', 'sarson', 'raydo'],
      'fennel': ['વરીયાળી', 'saunf'],
      'fruits': ['ફળ', 'phal', 'mango', 'banana', 'keri'],
      'vegetables': ['શાકભાજી', 'sabji', 'subzi'],
    };
    for (final entry in synonyms.entries) {
      if (entry.key.contains(query) || query.contains(entry.key)) return true;
      if (entry.value.any((v) => v.contains(query) || query.contains(v))) {
        return true;
      }
    }
    return false;
  }

  String get displayName {
    final n = name.trim();
    if (n.toLowerCase().startsWith('apmc')) return n;
    return 'APMC $n';
  }

  String get contactSummary {
    if (mobile.isNotEmpty && mobile != '-') return mobile;
    if (officePhone.isNotEmpty && officePhone != '-') return officePhone;
    return '';
  }
}

/// Result wrapping a GujaratApmcEntry with calculated distance from farmer.
class ApmcWithDistance {
  final GujaratApmcEntry apmc;
  final double distanceKm;

  const ApmcWithDistance({required this.apmc, required this.distanceKm});
}

/// Profit calculation result for a specific APMC.
class ApmcProfitEstimate {
  final GujaratApmcEntry apmc;
  final double distanceKm;
  final double quantityQuintals;
  final double? modalPricePerQuintal;
  final double grossRevenue;
  final double transportCost;
  final double otherExpenses;
  final double netReturn;
  final bool isRecommended;
  final String priceSource;
  final String priceNote;

  const ApmcProfitEstimate({
    required this.apmc,
    required this.distanceKm,
    required this.quantityQuintals,
    this.modalPricePerQuintal,
    required this.grossRevenue,
    required this.transportCost,
    required this.otherExpenses,
    required this.netReturn,
    this.isRecommended = false,
    this.priceSource = '',
    this.priceNote = '',
  });
}

/// Service for the complete Gujarat APMC directory from the official PDF.
/// Provides loading, filtering, distance calculation, and profit estimation.
class GujaratApmcService {
  GujaratApmcService._internal();
  static final GujaratApmcService instance = GujaratApmcService._internal();

  List<GujaratApmcEntry> _allEntries = [];
  bool _loaded = false;

  /// Load the APMC directory from the bundled JSON asset.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(
        'assets/translations/gujarat_apmc_directory.json',
      );
      final Map<String, dynamic> data =
          json.decode(raw) as Map<String, dynamic>;
      final list = data['apmc_markets'] as List<dynamic>;
      _allEntries = list
          .map((e) => GujaratApmcEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _loaded = true;
    } catch (e) {
      _allEntries = [];
    }
  }

  List<GujaratApmcEntry> get allEntries => List.unmodifiable(_allEntries);

  /// All unique district names from the directory.
  List<String> get allDistricts {
    final seen = <String>{};
    final result = <String>[];
    for (final e in _allEntries) {
      if (e.district.isNotEmpty && seen.add(e.district)) {
        result.add(e.district);
      }
    }
    result.sort();
    return result;
  }

  /// Find nearby entries sorted by straight-line distance (Haversine).
  List<ApmcWithDistance> getNearby({
    required double farmerLat,
    required double farmerLon,
    double maxRadiusKm = 100.0,
    String? districtFilter,
    String? commodityFilter,
    String? searchQuery,
  }) {
    final results = <ApmcWithDistance>[];

    for (final entry in _allEntries) {
      // District filter
      if (districtFilter != null && districtFilter.isNotEmpty) {
        if (!entry.district.toLowerCase().contains(
          districtFilter.toLowerCase(),
        )) {
          continue;
        }
      }

      // Commodity filter
      if (commodityFilter != null && commodityFilter.isNotEmpty) {
        if (!entry.tradesCommodity(commodityFilter)) continue;
      }

      // Search filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final match =
            entry.name.toLowerCase().contains(q) ||
            entry.district.toLowerCase().contains(q) ||
            entry.taluka.toLowerCase().contains(q) ||
            entry.pincode.contains(q) ||
            entry.commodities.any((c) => c.toLowerCase().contains(q));
        if (!match) continue;
      }

      if (!entry.hasCoordinates) {
        // Add to unverified section — distance = double.infinity
        results.add(ApmcWithDistance(apmc: entry, distanceKm: double.infinity));
        continue;
      }

      final dist = haversineKm(
        farmerLat,
        farmerLon,
        entry.latitude!,
        entry.longitude!,
      );

      if (dist <= maxRadiusKm) {
        results.add(ApmcWithDistance(apmc: entry, distanceKm: dist));
      }
    }

    // Sort: verified coords first by distance, then unverified at end
    results.sort((a, b) {
      final aInf = a.distanceKm == double.infinity;
      final bInf = b.distanceKm == double.infinity;
      if (aInf && bInf) return a.apmc.name.compareTo(b.apmc.name);
      if (aInf) return 1;
      if (bInf) return -1;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    return results;
  }

  /// Profit comparison across all matching entries for a given crop and quantity.
  /// Note: Price data is NOT available from this directory; it must come from
  /// a live source (AGMARKNET). When no live price is available, priceNote
  /// will indicate unavailability — estimates are NOT fabricated.
  List<ApmcProfitEstimate> estimateProfit({
    required double farmerLat,
    required double farmerLon,
    required String commodity,
    required double quantityQuintals,
    required double transportRatePerKm, // ₹ per km (total, not per quintal)
    double otherExpenses = 0.0,
    double maxRadiusKm = 200.0,
    Map<String, double>? livePricePerQuintal, // apmcId → price from AGMARKNET
  }) {
    final nearby = getNearby(
      farmerLat: farmerLat,
      farmerLon: farmerLon,
      maxRadiusKm: maxRadiusKm,
      commodityFilter: commodity,
    );

    final results = <ApmcProfitEstimate>[];

    for (final item in nearby) {
      if (item.distanceKm == double.infinity) continue;

      final price = livePricePerQuintal?[item.apmc.apmcId];
      final double gross = price != null ? price * quantityQuintals : 0.0;
      final double transport = transportRatePerKm * item.distanceKm;
      final double net = gross - transport - otherExpenses;

      results.add(
        ApmcProfitEstimate(
          apmc: item.apmc,
          distanceKm: item.distanceKm,
          quantityQuintals: quantityQuintals,
          modalPricePerQuintal: price,
          grossRevenue: gross,
          transportCost: transport,
          otherExpenses: otherExpenses,
          netReturn: net,
          priceSource: price != null ? 'AGMARKNET / Live Price' : '',
          priceNote: price != null ? '' : 'આ મંડીનો તાજેતરનો ભાવ ઉપલબ્ધ નથી.\n(Recent price not available for this mandi.)',
        ),
      );
    }

    if (results.isEmpty) return [];

    // Sort by net return descending (only entries with price)
    final withPrice =
        results.where((r) => r.modalPricePerQuintal != null).toList()
          ..sort((a, b) => b.netReturn.compareTo(a.netReturn));
    final withoutPrice =
        results.where((r) => r.modalPricePerQuintal == null).toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final merged = [...withPrice, ...withoutPrice];

    // Mark best
    if (merged.isNotEmpty && merged.first.modalPricePerQuintal != null) {
      final best = merged.first;
      return merged.map((r) {
        return ApmcProfitEstimate(
          apmc: r.apmc,
          distanceKm: r.distanceKm,
          quantityQuintals: r.quantityQuintals,
          modalPricePerQuintal: r.modalPricePerQuintal,
          grossRevenue: r.grossRevenue,
          transportCost: r.transportCost,
          otherExpenses: r.otherExpenses,
          netReturn: r.netReturn,
          isRecommended: r.apmc.apmcId == best.apmc.apmcId,
          priceSource: r.priceSource,
          priceNote: r.priceNote,
        );
      }).toList();
    }

    return merged;
  }

  /// Public for use by detail/profit pages.
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}
