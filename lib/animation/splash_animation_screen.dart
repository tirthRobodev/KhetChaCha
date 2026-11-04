import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../screens/farmer_dashboard_page.dart';
import '../screens/language_selection_page.dart';
import '../services/farm_profile_service.dart';

/// [SplashAnimationScreen] provides a production-ready, 100% true full-screen
/// immersive display for the KhetChacha farmer animation and welcome visuals.
///
/// Immersive Architecture:
/// 1. TRUE FULL-SCREEN IMMERSIVE STICKY:
///    Uses [SystemUiMode.immersiveSticky] to completely hide the Android status
///    bar (top) and navigation bar (bottom). Content extends from the absolute
///    top edge to the absolute bottom edge behind display cutouts and system bars.
/// 2. 100% DISPLAY COVERAGE WITHOUT LETTERBOXING:
///    Both background image and video use [BoxFit.cover] to cover 100% of the
///    screen width and height across all Android screen ratios (16:9, 18:9,
///    19.5:9, 20:9, 21:9) on Samsung, Xiaomi/Redmi, Realme, Vivo, Oppo,
///    OnePlus, and Google Pixel devices.
/// 3. CORRECT ASPECT RATIO & ZERO DISTORTION:
///    Uses [FittedBox] with [BoxFit.cover] and [AspectRatio] to ensure the
///    original aspect ratio is strictly preserved without stretching, distortion,
///    or artificial scaling.
/// 4. ZERO SAFEAREA OR MARGINS:
///    No [SafeArea], margins, or padding are introduced, eliminating unwanted
///    top and bottom blank or empty spaces.
/// 5. RESTORATION ON NAVIGATION:
///    Restores standard [SystemUiMode.edgeToEdge] when transitioning to subsequent
///    screens (e.g., Language Selection, Dashboard).
class SplashAnimationScreen extends StatefulWidget {
  /// Callback invoked when the video reaches completion.
  /// If omitted, automatically checks authentication/profile and routes to the dashboard.
  final VoidCallback? onAnimationComplete;

  const SplashAnimationScreen({super.key, this.onAnimationComplete});

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;

  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  static const String _splashVideoPath =
      'assets/animation/khetchacha_splash.mp4';
  static const String _farmerWelcomeImagePath =
      'assets/images/farmer_welcome.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. True Full-Screen Mode: Completely hide status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(_splashVideoPath);
      await _videoController.initialize();
      await _videoController.setLooping(false); // Play exactly once
      await _videoController.setVolume(1.0); // Full audio quality

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      _videoController.addListener(_onVideoPlayerUpdate);
      await _videoController.play();

      // Reliable fallback timer: triggers if device codec fails to report position completion
      final videoDuration = _videoController.value.duration;
      final timeoutDuration = videoDuration > Duration.zero
          ? videoDuration + const Duration(milliseconds: 600)
          : const Duration(seconds: 11);

      _fallbackTimer = Timer(timeoutDuration, () {
        if (!_hasNavigated && mounted) {
          _navigateToNext();
        }
      });
    } catch (e) {
      debugPrint('Error loading splash video ($_splashVideoPath): $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
        // Graceful error fallback: navigate after a brief moment rather than freezing
        _fallbackTimer = Timer(const Duration(milliseconds: 1800), () {
          if (!_hasNavigated && mounted) {
            _navigateToNext();
          }
        });
      }
    }
  }

  void _onVideoPlayerUpdate() {
    if (!mounted || _hasNavigated) return;

    final value = _videoController.value;
    if (!value.isInitialized) return;

    // Trigger navigation when playback reaches or passes the end
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _navigateToNext();
    } else if (!value.isPlaying &&
        value.position > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 200)) {
      _navigateToNext();
    }
  }

  void _restoreSystemUI() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (_) {}
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _fallbackTimer?.cancel();

    if (_isVideoInitialized) {
      _videoController.removeListener(_onVideoPlayerUpdate);
      try {
        await _videoController.pause();
      } catch (_) {}
    }

    _restoreSystemUI();

    if (!mounted) return;

    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    } else {
      // Default fallback navigation: route directly to existing Main Dashboard or setup flow
      final profile = await FarmProfileService.instance.loadFarmProfile();
      if (!mounted) return;

      if (profile != null && profile.farmSetupCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FarmerDashboardPage(profile: profile),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                LanguageSelectionPage(initialProfile: profile),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized || _hasNavigated) return;

    if (state == AppLifecycleState.paused) {
      _videoController.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Re-assert immersive sticky if user minimized and reopened the app
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!_videoController.value.isPlaying &&
          _videoController.value.position < _videoController.value.duration) {
        _videoController.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    if (_isVideoInitialized) {
      _videoController.removeListener(_onVideoPlayerUpdate);
      _videoController.dispose();
    }
    _restoreSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Video / Illustration native aspect ratio (default 9:16 portrait)
    final double mediaAspect =
        (_isVideoInitialized && _videoController.value.aspectRatio > 0)
        ? _videoController.value.aspectRatio
        : (9.0 / 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3814),
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // -----------------------------------------------------------------
            // LAYER 1: Ambient Base Gradient Placeholder
            // Displays instantly on frame 0 to prevent any blank or white flash
            // -----------------------------------------------------------------
            Positioned.fill(child: _buildAmbientGradientPlaceholder()),

            // -----------------------------------------------------------------
            // LAYER 2: Full-Screen Background Image with BoxFit.cover
            // Occupies 100% of the display from absolute top to bottom
            // -----------------------------------------------------------------
            Positioned.fill(
              child: Image.asset(
                _farmerWelcomeImagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),

            // -----------------------------------------------------------------
            // LAYER 3: Full-Screen Video Player with BoxFit.cover
            // Scales with BoxFit.cover to fill 100% of the display seamlessly
            // across all Android screen dimensions, ratios, and orientations
            // with strictly zero stretching, zero distortion, and zero letterboxing.
            // -----------------------------------------------------------------
            if (_isVideoInitialized && !_hasVideoError)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController.value.size.width > 0
                        ? _videoController.value.size.width
                        : 9.0,
                    height: _videoController.value.size.height > 0
                        ? _videoController.value.size.height
                        : 16.0,
                    child: AspectRatio(
                      aspectRatio: mediaAspect,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ambient rural gradient shown seamlessly while local video initializes
  Widget _buildAmbientGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5BA4D9), // Sky Blue at top
            Color(0xFFFFD54F), // Sunrise Gold
            Color(0xFF388E3C), // Leaf Green
            Color(0xFF0F3814), // Deep Forest Soil at bottom
          ],
          stops: [0.0, 0.40, 0.70, 1.0],
        ),
      ),
    );
  }
}
