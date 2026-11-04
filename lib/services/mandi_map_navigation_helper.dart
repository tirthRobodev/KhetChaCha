import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to launch Google Maps directions and telephone calls for APMC mandis.
class MandiMapNavigationHelper {
  MandiMapNavigationHelper._();

  /// Opens Google Maps directions from the farmer's location to the destination APMC.
  /// Falls back to address search or browser if native map fails.
  static Future<void> openDirections({
    required BuildContext context,
    required String marketName,
    required String address,
    double? marketLat,
    double? marketLon,
    double? farmerLat,
    double? farmerLon,
  }) async {
    Uri url;

    final hasMarketCoords =
        marketLat != null &&
        marketLon != null &&
        marketLat != 0.0 &&
        marketLon != 0.0 &&
        !marketLat.isNaN &&
        !marketLon.isNaN;

    final hasFarmerCoords =
        farmerLat != null &&
        farmerLon != null &&
        farmerLat != 0.0 &&
        farmerLon != 0.0 &&
        !farmerLat.isNaN &&
        !farmerLon.isNaN;

    if (hasMarketCoords) {
      if (hasFarmerCoords) {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&origin=$farmerLat,$farmerLon'
          '&destination=$marketLat,$marketLon'
          '&travelmode=driving',
        );
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=$marketLat,$marketLon'
          '&travelmode=driving',
        );
      }
    } else {
      // Unverified coordinates: search by verified address / name
      final query = address.trim().isNotEmpty
          ? '$marketName, $address'
          : '$marketName, Gujarat';
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        // Fallback to in-app or browser
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open Google Maps. Market: $marketName ($address)',
            ),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  /// Opens native phone dialer for verified APMC contact numbers.
  static Future<void> makePhoneCall({
    required BuildContext context,
    required String rawPhone,
  }) async {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact number is not available or verified.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$cleaned');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch dialer for $cleaned'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer unavailable. Number: $cleaned'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }
}
