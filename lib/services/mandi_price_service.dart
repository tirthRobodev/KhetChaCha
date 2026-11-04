import '../models/mandi_market.dart';
import 'location_service.dart';
import 'mandi_discovery_service.dart';

/// Evaluated comparison for a specific mandi selling transaction.
class MandiComparisonResult {
  final MandiMarket market;
  final double distanceKm;
  final String commodity;
  final String variety;
  final String grade;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final double quantityQuintals;
  final double grossRevenue;
  final double totalTransportCost;
  final double mandiHandlingCharges;
  final double netSellingAmount;
  final DateTime priceTime;
  final String officialSource;
  final String verificationStatus;
  final double? previousModalPrice;
  final GovernmentMspRecord? mspRecord;
  final bool isRecommended;
  final String recommendationNote;

  const MandiComparisonResult({
    required this.market,
    required this.distanceKm,
    this.commodity = '',
    this.variety = 'FAQ',
    this.grade = 'FAQ',
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.quantityQuintals,
    required this.grossRevenue,
    required this.totalTransportCost,
    required this.mandiHandlingCharges,
    required this.netSellingAmount,
    required this.priceTime,
    this.officialSource = 'AGMARKNET / State Agriculture Marketing Board',
    this.verificationStatus = 'Verified',
    this.previousModalPrice,
    this.mspRecord,
    required this.isRecommended,
    required this.recommendationNote,
  });

  /// Whether a statutory MSP applies to this commodity.
  bool get hasMsp => mspRecord != null && mspRecord!.isApplicable;

  /// Price difference: Modal Mandi Rate minus Government Announced MSP.
  /// Positive means market is paying above MSP; negative means below MSP.
  double? get mspDifference =>
      hasMsp ? modalPrice - mspRecord!.officialMsp : null;
}

/// Service computing real-time net selling revenue across nearby mandis.
/// Incorporates transport freight per km/quintal and APMC cess/handling.
class MandiPriceService {
  MandiPriceService._internal();
  static final MandiPriceService instance = MandiPriceService._internal();

  /// Compares verified mandis for a specific agricultural produce
  List<MandiComparisonResult> compareMandis({
    required String commodity,
    required double quantityQuintals,
    required double farmerLat,
    required double farmerLon,
    double transportRatePerKmPerQuintal =
        3.50, // Standard tractor/small truck rate in ₹
    double handlingRatePerQuintal = 15.0, // Weighment & loading/unloading
  }) {
    final allMarkets = MandiDiscoveryService.instance.getAllMarkets();
    final results = <MandiComparisonResult>[];
    final msp = GovernmentMspRecord.getMspForCommodity(commodity);

    for (final market in allMarkets) {
      final priceEntry = market.getPriceForCommodity(commodity);
      if (priceEntry == null) continue;

      final dist = LocationService.instance.calculateDistanceKm(
        farmerLat,
        farmerLon,
        market.latitude,
        market.longitude,
      );

      final gross = priceEntry.modalPrice * quantityQuintals;
      final transportCost =
          dist * transportRatePerKmPerQuintal * quantityQuintals;
      final handlingCost = handlingRatePerQuintal * quantityQuintals;
      final net = gross - transportCost - handlingCost;

      results.add(
        MandiComparisonResult(
          market: market,
          distanceKm: dist,
          commodity: commodity,
          variety: priceEntry.variety,
          grade: priceEntry.grade,
          minPrice: priceEntry.minPrice,
          maxPrice: priceEntry.maxPrice,
          modalPrice: priceEntry.modalPrice,
          quantityQuintals: quantityQuintals,
          grossRevenue: gross,
          totalTransportCost: transportCost,
          mandiHandlingCharges: handlingCost,
          netSellingAmount: net,
          priceTime: priceEntry.lastUpdated,
          officialSource: priceEntry.officialSource,
          verificationStatus: priceEntry.verificationStatus,
          previousModalPrice: priceEntry.previousModalPrice,
          mspRecord: msp,
          isRecommended: false,
          recommendationNote: '',
        ),
      );
    }

    if (results.isEmpty) return [];

    // Sort descending by net profit
    results.sort((a, b) => b.netSellingAmount.compareTo(a.netSellingAmount));

    // Best market is the top net profit generator
    final best = results.first;

    final updatedResults = <MandiComparisonResult>[];
    for (int i = 0; i < results.length; i++) {
      final item = results[i];
      final isTop = (i == 0);
      final note = isTop
          ? 'Highest Net Return (₹${item.netSellingAmount.toStringAsFixed(0)}) after subtracting ₹${item.totalTransportCost.toStringAsFixed(0)} transport cost.'
          : 'Net return is ₹${(best.netSellingAmount - item.netSellingAmount).toStringAsFixed(0)} lower due to lower rate or travel distance.';

      updatedResults.add(
        MandiComparisonResult(
          market: item.market,
          distanceKm: item.distanceKm,
          commodity: item.commodity,
          variety: item.variety,
          grade: item.grade,
          minPrice: item.minPrice,
          maxPrice: item.maxPrice,
          modalPrice: item.modalPrice,
          quantityQuintals: item.quantityQuintals,
          grossRevenue: item.grossRevenue,
          totalTransportCost: item.totalTransportCost,
          mandiHandlingCharges: item.mandiHandlingCharges,
          netSellingAmount: item.netSellingAmount,
          priceTime: item.priceTime,
          officialSource: item.officialSource,
          verificationStatus: item.verificationStatus,
          previousModalPrice: item.previousModalPrice,
          mspRecord: item.mspRecord,
          isRecommended: isTop,
          recommendationNote: note,
        ),
      );
    }

    return updatedResults;
  }

  /// Official CCEA Minimum Support Price (MSP) statutory registry lookup
  GovernmentMspRecord? getMspRecord(String commodity) {
    return GovernmentMspRecord.getMspForCommodity(commodity);
  }
}
