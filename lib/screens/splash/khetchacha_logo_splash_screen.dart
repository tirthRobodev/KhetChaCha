import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-Screen Responsive KhetChacha Logo Splash Screen.
///
/// Implements all requirements from Section 4:
/// 1. Prominently centers the official KhetChacha logo image (`assets/images/khetchacha_logo.jpg`).
/// 2. Uses the entire mobile display with edge-to-edge system UI styling.
/// 3. Dark agricultural green background (`#0B3720`) matching the exact hex of the logo artwork.
/// 4. Maintains original logo aspect ratio (1024x832, ~1.23) without any stretching or distortion.
/// 5. Ensures complete logo, "ખેતચાચા / KHETCHACHA" typography, and "AGRITECH" tagline remain 100% visible.
/// 6. Fully responsive across small (320px), standard (360-390px), and large/tall (20:9, tablets) screens.
/// 7. Preserves system status bar and navigation bar styling without harsh white margins or blank borders.
/// 8. Uses [BoxFit.contain] for the full logo artwork.
class KhetChachaLogoSplashScreen extends StatefulWidget {
  /// Callback triggered when splash duration finishes or when tapped.
  final VoidCallback? onSplashComplete;

  /// Duration to display the splash screen before calling [onSplashComplete].
  /// Defaults to 2.5 seconds.
  final Duration displayDuration;

  const KhetChachaLogoSplashScreen({
    super.key,
    this.onSplashComplete,
    this.displayDuration = const Duration(milliseconds: 2500),
  });

  @override
  State<KhetChachaLogoSplashScreen> createState() =>
      _KhetChachaLogoSplashScreenState();
}

class _KhetChachaLogoSplashScreenState extends State<KhetChachaLogoSplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _transitionTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasCompleted = false;

  /// Exact corner background color of `assets/images/khetchacha_logo.jpg`
  static const Color darkAgriculturalGreen = Color(0xFF0B3720);

  @override
  void initState() {
    super.initState();

    // Edge-to-edge modern Android system UI configuration
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Smooth subtle entry fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    // Auto-advance after displayDuration
    _transitionTimer = Timer(widget.displayDuration, _triggerComplete);
  }

  void _triggerComplete() {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    _transitionTimer?.cancel();
    if (widget.onSplashComplete != null) {
      widget.onSplashComplete!();
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkAgriculturalGreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerComplete,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-Screen Agricultural Dark Green Base Layer (#0B3720)
              const ColoredBox(color: darkAgriculturalGreen),

              // 2. Prominent Center Logo Artwork
              // Preserves exact aspect ratio with BoxFit.contain, responsive across all screen sizes
              SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Maximize responsive scale while preserving breathing room
                        final maxW = constraints.maxWidth * 0.90;
                        final maxH = constraints.maxHeight * 0.85;

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxW,
                            maxHeight: maxH,
                          ),
                          child: AspectRatio(
                            // Original artwork resolution: 1024 x 832 (aspect ratio ~ 1.23)
                            aspectRatio: 1024 / 832,
                            child: Image.asset(
                              'assets/images/khetchacha_logo.jpg',
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Text(
                                      'KHETCHACHA\nAGRITECH',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
