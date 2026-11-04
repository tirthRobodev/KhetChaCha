import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/india_districts_data.dart';
import '../localization/location_data.dart';
import '../models/location_models.dart';
import 'permission_service.dart';

/// Centralized Location Service for KhetChacha.
/// Automatically detects farmer coordinates via GPS, resolves State, District,
/// Taluka, and Village, calculates distances, and provides manual selection fallback.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  static const String _keyCachedLocation = 'khetchacha_cached_location_v1';

  // Test / Headless mock override
  FarmerLocationData? _mockLocation;
  FarmerLocationData? _lastKnownLocation;
  bool _mockMode = false;

  FarmerLocationData? get lastKnownLocation =>
      _mockLocation ?? _lastKnownLocation;

  void enableMockMode({FarmerLocationData? mockLocation}) {
    _mockMode = true;
    _mockLocation =
        mockLocation ??
        const FarmerLocationData(
          country: 'India',
          state: 'Gujarat',
          district: 'Ahmedabad',
          taluka: 'Daskroi',
          village: 'Bhavda',
          pincode: '382433',
          latitude: 23.0225,
          longitude: 72.5714,
          isGpsAccurate: true,
          formattedAddress: 'Bhavda, Daskroi, Ahmedabad, Gujarat, 382433',
        );
  }

  void disableMockMode() {
    _mockMode = false;
    _mockLocation = null;
  }

  /// Check whether GPS location service is enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    if (_mockMode) return true;
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Attempt to fetch real GPS location and reverse geocode.
  Future<FarmerLocationData?> getCurrentLocation() async {
    if (_mockMode && _mockLocation != null) {
      await saveCachedLocation(_mockLocation!);
      return _mockLocation;
    }

    try {
      // 1. Verify Permission
      final permStatus = await PermissionService.instance.checkStatus(
        KhetPermissionType.location,
      );
      if (permStatus != KhetPermissionState.granted) {
        final requested = await PermissionService.instance.request(
          KhetPermissionType.location,
        );
        if (requested != KhetPermissionState.granted) {
          return null;
        }
      }

      // 2. Check Service Enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 3. Acquire Position with 10-second timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Reverse Geocode Coordinates
      final resolved = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      final finalLoc = resolved.copyWith(isGpsAccurate: true);
      await saveCachedLocation(finalLoc);
      return finalLoc;
    } catch (e) {
      debugPrint('LocationService: Error getting GPS location: $e');
      return null;
    }
  }

  /// Reverse geocodes latitude and longitude into structured Indian administrative units.
  /// Uses OpenStreetMap Nominatim with safe offline fallback to nearest known district.
  Future<FarmerLocationData> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'KhetChachaFarmerApp/1.0 (contact@khetchacha.in)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final state = address['state'] as String? ?? '';
        final district =
            address['state_district'] as String? ??
            address['county'] as String? ??
            address['city'] as String? ??
            '';
        final taluka =
            address['subdistrict'] as String? ??
            address['tehsil'] as String? ??
            address['taluka'] as String? ??
            '';
        final village =
            address['village'] as String? ??
            address['town'] as String? ??
            address['hamlet'] as String? ??
            address['suburb'] as String? ??
            '';
        final pincode = address['postcode'] as String? ?? '';
        final displayName = data['display_name'] as String? ?? '';

        if (state.isNotEmpty || district.isNotEmpty) {
          return FarmerLocationData(
            country: address['country'] as String? ?? 'India',
            state: _sanitizeStateName(state),
            district: _sanitizeDistrictName(district),
            taluka: taluka,
            village: village,
            pincode: pincode,
            latitude: latitude,
            longitude: longitude,
            formattedAddress: displayName,
          );
        }
      }
    } catch (e) {
      debugPrint('LocationService: Reverse geocoding network notice: $e');
    }

    // Fallback: Geometric nearest district match from authentic repository
    final nearest = findNearestDistrict(latitude, longitude);
    return FarmerLocationData(
      country: 'India',
      state: nearest.stateKey,
      district: nearest.englishName,
      latitude: latitude,
      longitude: longitude,
      formattedAddress: '${nearest.englishName}, ${nearest.stateKey}, India',
    );
  }

  /// Finds the geometrically closest district in India from known coordinates.
  IndianDistrict findNearestDistrict(double latitude, double longitude) {
    IndianDistrict closest = IndiaDistrictsData.allDistricts.first;
    double minDistance = double.infinity;

    for (final d in IndiaDistrictsData.allDistricts) {
      final dist = calculateDistanceKm(
        latitude,
        longitude,
        d.latitude,
        d.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = d;
      }
    }

    return closest;
  }

  /// Calculates great-circle distance between two GPS coordinates using the Haversine formula.
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Saves location to SharedPreferences for instant offline access.
  Future<void> saveCachedLocation(FarmerLocationData location) async {
    _lastKnownLocation = location;
    if (_mockMode) {
      _mockLocation = location;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedLocation, location.toJsonString());
  }

  /// Loads cached location from SharedPreferences.
  Future<FarmerLocationData?> getCachedLocation() async {
    if (_mockMode && _mockLocation != null) return _mockLocation;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCachedLocation);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final loc = FarmerLocationData.fromJsonString(jsonStr);
        _lastKnownLocation = loc;
        return loc;
      } catch (_) {}
    }
    return null;
  }

  /// Helper to normalize and match Indian State names
  String _sanitizeStateName(String raw) {
    for (final s in LocationData.allStates) {
      if (raw.toLowerCase().contains(s.key.toLowerCase()) ||
          s.englishName.toLowerCase().contains(raw.toLowerCase())) {
        return s.englishName;
      }
    }
    return raw;
  }

  /// Helper to normalize and match Indian District names
  String _sanitizeDistrictName(String raw) {
    for (final d in IndiaDistrictsData.allDistricts) {
      if (raw.toLowerCase().contains(d.englishName.toLowerCase()) ||
          d.englishName.toLowerCase().contains(raw.toLowerCase())) {
        return d.englishName;
      }
    }
    return raw;
  }
}
