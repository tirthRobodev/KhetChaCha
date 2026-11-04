import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../models/farmer_profile.dart';
import '../models/mandi_market.dart';
import '../screens/mandi/mandi_comparison_page.dart';
import '../screens/mandi/mandi_discovery_page.dart';
import '../services/language_service.dart';
import '../services/mandi_discovery_service.dart';

/// Reusable APMC Mandi & Wholesale Rates Snapshot Card.
/// Relocated from Home Screen into Prakruti Bajar (Natural Farming Marketplace).
///
/// Features:
/// 1. Hyper-local GPS/Profile-based nearest APMC mandi detection.
/// 2. Live distance and district information.
/// 3. Direct route to Mandi Discovery Page ("મંડીઓ શોધો").
/// 4. Direct route to Mandi Comparison Page ("ભાવો સરખાવો").
/// 5. Full multilingual support (Gujarati, Hindi, Punjabi, Marathi, English).
class ApmcMandiSnapshotCard extends StatelessWidget {
  final FarmerProfile profile;
  final VoidCallback? onViewAll;

  const ApmcMandiSnapshotCard({
    super.key,
    required this.profile,
    this.onViewAll,
  });

  String _formatCleanLocationComponent(String raw, String langCode) {
    if (raw.isEmpty) return '';
    var trimmed = raw.trim();

    if (trimmed.contains(') (')) {
      final firstPart = trimmed.split(') (').first;
      trimmed = '$firstPart)';
    }

    final match = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(trimmed);
    if (match != null) {
      final part1 = match.group(1)!.trim();
      final part2 = match.group(2)!.trim();

      if (langCode == 'gu') {
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part2)) return part2;
      } else if (langCode == 'hi' ||
          const [
            'mr',
            'mai',
            'kok',
            'ne',
            'doi',
            'sa',
            'brx',
          ].contains(langCode)) {
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part2)) return part2;
      } else if (langCode == 'pa') {
        if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(part2)) return part2;
      } else if (langCode == 'en') {
        if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(part1)) return part1;
        if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(part2)) return part2;
      }
      return part1.isNotEmpty ? part1 : trimmed;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final loc = AppLocalizations.of(context);

    final lat =
        profile.latitude ??
        (profile.effectiveState.toLowerCase().contains('punjab')
            ? 30.9010
            : 23.0225);
    final lon =
        profile.longitude ??
        (profile.effectiveState.toLowerCase().contains('punjab')
            ? 75.8573
            : 72.5714);

    final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: lat,
      longitude: lon,
      maxDistanceKm: 250.0,
    );

    final nearest = nearby.isNotEmpty ? nearby.first : null;

    final mandiTitle = langCode == 'gu'
        ? 'નજીકની મંડીઓ અને બજાર ભાવો'
        : (langCode == 'hi'
              ? 'नजदीकी मंडियां एवं बाजार भाव'
              : (langCode == 'pa'
                    ? 'ਨੇੜਲੀਆਂ ਮੰਡੀਆਂ ਅਤੇ ਬਾਜ਼ਾਰ ਭਾਅ'
                    : (langCode == 'mr'
                          ? 'जवळच्या बाजारपेठा व दर'
                          : 'Nearby Mandis & Wholesale Rates')));

    final findMandisLabel = langCode == 'gu'
        ? 'મંડીઓ શોધો'
        : (langCode == 'hi'
              ? 'मंडियां खोजें'
              : (langCode == 'pa'
                    ? 'ਮੰਡੀਆਂ ਲੱਭੋ'
                    : (langCode == 'mr' ? 'मंड्या शोधा' : 'Find Mandis')));

    final compareRatesLabel = langCode == 'gu'
        ? 'ભાવો સરખાવો'
        : (langCode == 'hi'
              ? 'भाव तुलना करें'
              : (langCode == 'pa'
                    ? 'ਭਾਅ ਤੁਲਨਾ ਕਰੋ'
                    : (langCode == 'mr' ? 'दर तुलना करा' : 'Compare Rates')));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE65100),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mandiTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  if (onViewAll != null) {
                    onViewAll!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandiDiscoveryPage(profile: profile),
                      ),
                    );
                  }
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
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    nearest.market.type.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nearest.market.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${nearest.distanceKm.toStringAsFixed(1)} ${langCode == 'gu' ? 'કિમી દૂર' : (langCode == 'hi' ? 'किमी दूर' : 'km away')} • ${_formatCleanLocationComponent(nearest.market.district, langCode)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF757575),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 6,
                    ),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandiDiscoveryPage(profile: profile),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.near_me_rounded,
                    size: 15,
                    color: Color(0xFF2E7D32),
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      findMandisLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 6,
                    ),
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandiComparisonPage(profile: profile),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, size: 15),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      compareRatesLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
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
}
