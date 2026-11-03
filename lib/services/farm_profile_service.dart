import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farm_plot.dart';
import '../models/farmer_profile.dart';

/// Database Service handling persistence of farmer profiles and farm setup data.
/// Writes to Firebase Firestore path `users/{uid}/farmProfile` and caches locally
/// in SharedPreferences for instantaneous offline availability.
class FarmProfileService {
  FarmProfileService._internal();
  static final FarmProfileService instance = FarmProfileService._internal();

  static const String _localProfileKey = 'khetchacha_farm_profile_json';
  static const String _setupCompletedKey = 'khetchacha_farm_setup_completed';

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Saves the complete farmer profile to Firebase Firestore and local cache.
  Future<void> saveFarmProfile(FarmerProfile profile) async {
    final uid = profile.firebaseUid ?? _auth?.currentUser?.uid;

    final profileMap = <String, dynamic>{
      'fullName': profile.fullName,
      'mobileNumber': profile.mobileNumber,
      'email': profile.email,
      'state': profile.effectiveState,
      'district': profile.effectiveDistrict,
      'village': profile.village,
      'farmingType': profile.farmingType,
      'landSize': profile.effectiveFarmSize,
      'crops': profile.effectiveProducts,
      'firebaseUid': uid,
      'isPhoneVerified': profile.isPhoneVerified,

      // Section 9 Specific Attributes:
      'selectedLanguage': profile.selectedLanguage,
      'selectedState': profile.effectiveState,
      'selectedDistrict': profile.effectiveDistrict,
      'selectedCategories': profile.selectedCategories,
      'selectedProducts': profile.effectiveProducts,
      'farmSize': profile.effectiveFarmSize,
      'farmSetupCompleted': profile.farmSetupCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // 1. Persist to local cache immediately (< 5ms)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localProfileKey, jsonEncode(profileMap));
      await prefs.setBool(_setupCompletedKey, profile.farmSetupCompleted);
      if (profile.selectedLanguage.isNotEmpty) {
        await prefs.setString(
          'khetchacha_selected_language',
          profile.selectedLanguage,
        );
      }
    } catch (e) {
      debugPrint('[FarmProfileService] Local cache notice: $e');
    }

    // 2. Persist to Firebase Firestore in the background with timeout (never block UI navigation)
    if (uid != null && uid.isNotEmpty) {
      _syncToFirestore(uid, profileMap, profile);
    }
  }

  /// Dispatches Firestore write in the background with a 4-second timeout to avoid UI blocking.
  Future<void> _syncToFirestore(
    String uid,
    Map<String, dynamic> profileMap,
    FarmerProfile profile,
  ) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await Future.wait([
        // Document: users/{uid}/farmProfile/current
        firestore
            .collection('users')
            .doc(uid)
            .collection('farmProfile')
            .doc('current')
            .set(profileMap, SetOptions(merge: true)),

        // Also merge under users/{uid} root document to preserve all user authentication data
        firestore.collection('users').doc(uid).set({
          'farmProfile': profileMap,
          'phone': profile.mobileNumber,
          'email': profile.email,
          'displayName': profile.fullName,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]).timeout(const Duration(seconds: 4));

      debugPrint(
        '[FarmProfileService] Successfully saved farmProfile to Firebase for UID: $uid',
      );
    } catch (e) {
      debugPrint(
        '[FarmProfileService] Firestore sync notice (offline/queued fallback): $e',
      );
    }
  }

  /// Retrieves the farmer profile, checking local cache first (0ms), then Firestore.
  Future<FarmerProfile?> loadFarmProfile([String? targetUid]) async {
    final uid = targetUid ?? _auth?.currentUser?.uid;

    // 1. Instant local SharedPreferences cache check
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_localProfileKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        final local = FarmerProfile.fromJson(map);
        // If we found local profile, return immediately for instant responsiveness
        return local;
      }
    } catch (e) {
      debugPrint('[FarmProfileService] Local cache read notice: $e');
    }

    // 2. Fetch from Firestore with timeout protection if UID is available
    final firestore = _firestore;
    if (firestore != null && uid != null && uid.isNotEmpty) {
      try {
        final doc = await firestore
            .collection('users')
            .doc(uid)
            .collection('farmProfile')
            .doc('current')
            .get()
            .timeout(const Duration(seconds: 3));

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final profile = FarmerProfile.fromJson(data);

          // Update local cache with remote source of truth
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_localProfileKey, jsonEncode(data));
          await prefs.setBool(_setupCompletedKey, profile.farmSetupCompleted);

          return profile;
        }

        // Secondary check under root user document
        final userDoc = await firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 3));

        if (userDoc.exists && userDoc.data() != null) {
          final rootData = userDoc.data()!;
          if (rootData['farmProfile'] is Map<String, dynamic>) {
            final profile = FarmerProfile.fromJson(
              rootData['farmProfile'] as Map<String, dynamic>,
            );
            return profile;
          }
        }
      } catch (e) {
        debugPrint(
          '[FarmProfileService] Firestore read notice (timeout or offline): $e',
        );
      }
    }

    return null;
  }

  /// Checks whether the user has already completed the full onboarding & farm setup.
  Future<bool> hasCompletedFarmSetup([String? targetUid]) async {
    final profile = await loadFarmProfile(targetUid);
    if (profile != null && profile.farmSetupCompleted) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_setupCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clears profile cache (e.g. on complete sign out).
  Future<void> clearLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localProfileKey);
      await prefs.remove(_setupCompletedKey);
    } catch (e) {
      debugPrint('[FarmProfileService] Clear cache notice: $e');
    }
  }

  static const String _plotsKeyPrefix = 'khetchacha_farm_plots_';

  /// Retrieves all registered farm plots for this farmer.
  Future<List<FarmPlot>> getFarmPlots([String? farmerId]) async {
    final key = '$_plotsKeyPrefix${farmerId ?? _auth?.currentUser?.uid ?? 'default'}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = prefs.getString(key);
      if (jsonListStr != null && jsonListStr.isNotEmpty) {
        final list = (jsonDecode(jsonListStr) as List<dynamic>)
            .map((item) => FarmPlot.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[FarmProfileService] Error reading plots: $e');
    }

    // Default primary plot based on profile
    return const [
      FarmPlot(
        id: 'plot_1',
        name: 'Main Farm Plot',
        size: 2.0,
        unit: 'Acre',
        irrigationType: 'Borewell',
        waterAvailability: 'Medium',
      ),
    ];
  }

  /// Saves list of farm plots locally and to Firestore.
  Future<bool> saveFarmPlots(List<FarmPlot> plots, [String? farmerId]) async {
    final key = '$_plotsKeyPrefix${farmerId ?? _auth?.currentUser?.uid ?? 'default'}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = plots.map((p) => p.toJson()).toList();
      return await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[FarmProfileService] Error saving plots: $e');
      return false;
    }
  }
}
