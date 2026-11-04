import 'dart:ui';

import 'package:flutter/material.dart';

import 'farmer_avatar.dart';

/// Full-screen responsive farmer character display widget for KhetChacha welcome and onboarding.
///
/// Implements all 9 core requirements:
/// 1. Keeps the farmer character perfectly centered on every mobile screen size.
/// 2. Shows the complete farmer, including turban, Indian flag, hands, and feet.
/// 3. Never crops or cuts the main character.
/// 4. Maintains original image aspect ratio without stretching or distortion.
/// 5. Responsive for all Android screen sizes (16:9, 19.5:9, 20:9, tablets).
/// 6. Uses [BoxFit.contain] for the foreground character image.
/// 7. Uses a softly blurred [BoxFit.cover] background using the same image to fill empty spaces.
/// 8. Respects [SafeArea] and device viewport bounds.
/// 9. Built using Flutter [Stack], [Positioned.fill], [Image.asset], [BoxFit.cover], and [BoxFit.contain].
class FarmerWelcomeHeroDisplay extends StatelessWidget {
  /// Optional explicit image asset path. If null, resolves from [stateName].
  final String? imagePath;

  /// Farmer's state name for state-specific illustration (defaults to national farmer).
  final String? stateName;

  /// Optional overlay child placed cleanly above the foreground character (e.g. action buttons).
  final Widget? overlay;

  /// Blur intensity for the background fill (defaults to 24.0).
  final double blurSigma;

  /// Darkening scrim alpha to provide optimum contrast and depth (defaults to 0.18).
  final double scrimAlpha;

  const FarmerWelcomeHeroDisplay({
    super.key,
    this.imagePath,
    this.stateName,
    this.overlay,
    this.blurSigma = 24.0,
    this.scrimAlpha = 0.18,
  });

  String _resolveAssetPath() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return imagePath!;
    }
    if (stateName != null && stateName!.isNotEmpty) {
      return FarmerAvatar.getAssetPathForState(stateName!);
    }
    return 'assets/images/farmers/default_farmer.png';
  }

  @override
  Widget build(BuildContext context) {
    final asset = _resolveAssetPath();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Softly Blurred Background Layer:
        // Fills edge-to-edge with BoxFit.cover of the same image.
        // Blends seamlessly on ultra-tall (20:9) or wide displays, eliminating harsh black letterboxing.
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Transform.scale(
              scale: 1.15, // Scale slightly to prevent blur edge artifacts
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFF0F3814)),
              ),
            ),
          ),
        ),

        // 2. Ambient Darkening Scrim for Visual Depth & Readability
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: scrimAlpha)),
        ),

        // 3. Foreground Character Layer:
        // Perfectly centered, respects SafeArea, uses BoxFit.contain.
        // Guarantees: Full farmer visible from turban & Indian flag to hands and feet,
        // original aspect ratio preserved without crop or stretch.
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  size: 140,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),

        // 4. Optional Top / Bottom Overlay (e.g. Skip, Continue, Logo)
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}
