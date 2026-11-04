import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../services/permission_service.dart';

/// Interactive Permission Card for KhetChacha first-launch setup & settings.
class PermissionCard extends StatelessWidget {
  final KhetPermissionType type;
  final KhetPermissionState state;
  final VoidCallback onRequest;
  final VoidCallback? onOpenSettings;

  const PermissionCard({
    super.key,
    required this.type,
    required this.state,
    required this.onRequest,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final meta = _getPermissionMeta(type, loc);
    final isGranted = state == KhetPermissionState.granted;
    final isDenied = state == KhetPermissionState.denied;
    final isPermanentlyDenied = state == KhetPermissionState.permanentlyDenied;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF81C784)
              : (isPermanentlyDenied
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFFE0E0E0)),
          width: isGranted || isPermanentlyDenied ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isGranted
                ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFFE8F5E9) : meta.bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGranted
                      ? const Color(0xFF2E7D32)
                      : meta.accentColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isGranted ? Icons.check_circle_rounded : meta.icon,
                color: isGranted ? const Color(0xFF2E7D32) : meta.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content: Title & Explanation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isGranted
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF212121),
                          ),
                        ),
                      ),
                      if (isGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                loc.permissionStatusGranted,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action Button
                  if (!isGranted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status indicator label
                        Text(
                          isPermanentlyDenied
                              ? loc.permissionStatusDenied
                              : (isDenied ? loc.permissionStatusDenied : ''),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                        // Request / Settings button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPermanentlyDenied
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            isPermanentlyDenied
                                ? Icons.settings_rounded
                                : Icons.touch_app_rounded,
                            size: 14,
                          ),
                          label: Text(
                            isPermanentlyDenied
                                ? loc.permissionStatusSettings
                                : loc.permissionStatusNotEnabled,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isPermanentlyDenied
                              ? onOpenSettings
                              : onRequest,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _PermissionMeta _getPermissionMeta(
    KhetPermissionType type,
    AppLocalizations loc,
  ) {
    switch (type) {
      case KhetPermissionType.location:
        return _PermissionMeta(
          title: loc.permissionLocationTitle,
          description: loc.permissionLocationDesc,
          icon: Icons.location_on_rounded,
          accentColor: const Color(0xFF0288D1),
          bgColor: const Color(0xFFE1F5FE),
        );
      case KhetPermissionType.camera:
        return _PermissionMeta(
          title: loc.permissionCameraTitle,
          description: loc.permissionCameraDesc,
          icon: Icons.camera_alt_rounded,
          accentColor: const Color(0xFF7B1FA2),
          bgColor: const Color(0xFFF3E5F5),
        );
      case KhetPermissionType.gallery:
        return _PermissionMeta(
          title: loc.permissionGalleryTitle,
          description: loc.permissionGalleryDesc,
          icon: Icons.photo_library_rounded,
          accentColor: const Color(0xFF00897B),
          bgColor: const Color(0xFFE0F2F1),
        );
      case KhetPermissionType.microphone:
        return _PermissionMeta(
          title: loc.permissionMicTitle,
          description: loc.permissionMicDesc,
          icon: Icons.mic_rounded,
          accentColor: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
        );
      case KhetPermissionType.notification:
        return _PermissionMeta(
          title: loc.permissionNotificationTitle,
          description: loc.permissionNotificationDesc,
          icon: Icons.notifications_active_rounded,
          accentColor: const Color(0xFFD32F2F),
          bgColor: const Color(0xFFFFEBEE),
        );
    }
  }
}

class _PermissionMeta {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _PermissionMeta({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });
}
