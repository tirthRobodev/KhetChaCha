import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

/// Supported application permissions in KhetChacha
enum KhetPermissionType { location, camera, gallery, microphone, notification }

/// Normalized state for a permission
enum KhetPermissionState { granted, notRequested, denied, permanentlyDenied }

/// Centralized singleton service for Android runtime permissions and first-launch tracking.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const String _onboardingKey =
      'khetchacha_permission_onboarding_completed_v1';

  final Map<KhetPermissionType, KhetPermissionState> _mockStates = {};
  bool _useMockMode = false;

  /// Check whether we are currently executing in a Flutter headless test environment.
  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Enable mock mode for testing
  @visibleForTesting
  void enableMockMode({bool enabled = true}) {
    _useMockMode = enabled;
  }

  /// Override the state of a permission for unit & widget tests
  @visibleForTesting
  void setMockState(KhetPermissionType type, KhetPermissionState state) {
    _mockStates[type] = state;
    _useMockMode = true;
  }

  /// Reset all mock states
  @visibleForTesting
  void resetMockStates() {
    _mockStates.clear();
    _useMockMode = false;
  }

  /// Checks whether first-launch permission onboarding has been completed.
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets whether first-launch permission onboarding has been completed.
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, completed);
    } catch (e) {
      debugPrint('[PermissionService] Failed to set onboarding state: $e');
    }
  }

  /// Maps [KhetPermissionType] to the underlying [Permission] from permission_handler.
  Permission _mapToPermission(KhetPermissionType type) {
    switch (type) {
      case KhetPermissionType.location:
        return Permission.locationWhenInUse;
      case KhetPermissionType.camera:
        return Permission.camera;
      case KhetPermissionType.gallery:
        return Permission.photos;
      case KhetPermissionType.microphone:
        return Permission.microphone;
      case KhetPermissionType.notification:
        return Permission.notification;
    }
  }

  /// Check the current runtime status of a given permission.
  Future<KhetPermissionState> checkStatus(KhetPermissionType type) async {
    if (_useMockMode || _isTestEnv) {
      return _mockStates[type] ?? KhetPermissionState.notRequested;
    }

    try {
      final permission = _mapToPermission(type);
      final status = await permission.status;
      return _mapStatus(status);
    } catch (e) {
      debugPrint('[PermissionService] Error checking $type status: $e');
      return KhetPermissionState.notRequested;
    }
  }

  /// Request a given permission from the user via Android system dialog.
  Future<KhetPermissionState> request(KhetPermissionType type) async {
    if (_useMockMode || _isTestEnv) {
      final current = _mockStates[type] ?? KhetPermissionState.notRequested;
      if (current == KhetPermissionState.notRequested) {
        _mockStates[type] = KhetPermissionState.granted;
        return KhetPermissionState.granted;
      }
      return current;
    }

    try {
      final permission = _mapToPermission(type);
      final status = await permission.request();
      final mapped = _mapStatus(status);

      // On older Android (API <= 32), Permission.photos might return denied; fallback to Permission.storage
      if (type == KhetPermissionType.gallery &&
          mapped != KhetPermissionState.granted) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted || storageStatus.isLimited) {
          return KhetPermissionState.granted;
        }
      }

      return mapped;
    } catch (e) {
      debugPrint('[PermissionService] Error requesting $type: $e');
      return KhetPermissionState.denied;
    }
  }

  /// Request all 5 permissions sequentially.
  Future<Map<KhetPermissionType, KhetPermissionState>> requestAll() async {
    final results = <KhetPermissionType, KhetPermissionState>{};
    for (final type in KhetPermissionType.values) {
      results[type] = await request(type);
    }
    return results;
  }

  /// Check all 5 permissions without showing prompts.
  Future<Map<KhetPermissionType, KhetPermissionState>> checkAll() async {
    final results = <KhetPermissionType, KhetPermissionState>{};
    for (final type in KhetPermissionType.values) {
      results[type] = await checkStatus(type);
    }
    return results;
  }

  /// Opens the Android App Settings page so user can re-enable permanently denied permissions.
  Future<bool> openSettings() async {
    if (_useMockMode || _isTestEnv) {
      return true;
    }
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('[PermissionService] Error opening app settings: $e');
      return false;
    }
  }

  /// Feature-level permission guard.
  /// Checks permission before entering a feature (e.g. AI Camera, Voice Assistant).
  /// If missing or denied, displays an informative bottom sheet and allows the user to grant it
  /// or open Settings if permanently denied. Returns true if granted.
  Future<bool> ensurePermission(
    BuildContext context, {
    required KhetPermissionType type,
    required String featureName,
    required String reason,
  }) async {
    final currentState = await checkStatus(type);
    if (currentState == KhetPermissionState.granted) {
      return true;
    }

    if (!context.mounted) return false;

    // Show friendly bottom sheet explaining why the feature needs this permission
    final shouldProceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: const Color(0xFF1B5E20),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featureName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentState == KhetPermissionState.permanentlyDenied
                              ? loc.permissionSettingsNotice
                              : loc.permissionRequiredNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                reason,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(loc.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        currentState == KhetPermissionState.permanentlyDenied
                            ? loc.openSettingsButton
                            : loc.enableButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (shouldProceed != true) {
      return false;
    }

    if (currentState == KhetPermissionState.permanentlyDenied) {
      await openSettings();
      // Recheck
      final afterSettings = await checkStatus(type);
      return afterSettings == KhetPermissionState.granted;
    }

    final newState = await request(type);
    return newState == KhetPermissionState.granted;
  }

  IconData _getIconForType(KhetPermissionType type) {
    switch (type) {
      case KhetPermissionType.location:
        return Icons.location_on_rounded;
      case KhetPermissionType.camera:
        return Icons.camera_alt_rounded;
      case KhetPermissionType.gallery:
        return Icons.photo_library_rounded;
      case KhetPermissionType.microphone:
        return Icons.mic_rounded;
      case KhetPermissionType.notification:
        return Icons.notifications_active_rounded;
    }
  }

  KhetPermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return KhetPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return KhetPermissionState.permanentlyDenied;
    }
    if (status.isDenied) {
      return KhetPermissionState.denied;
    }
    return KhetPermissionState.notRequested;
  }
}
