import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../screens/language_selection_page.dart';

/// [SplashAnimationScreen] is the initial splash screen for KhetChacha.
///
/// Responsive Full-Screen Video Architecture:
/// 1. VIDEO PLAYED ONCE: Plays local asset [assets/animation/khetchacha_splash.mp4]
///    muted, automatically, exactly once without looping.
/// 2. AUTOMATIC NAVIGATION: On playback completion, automatically transitions
///    to the existing [LanguageSelectionPage] without requiring user button presses.
/// 3. RESPONSIVE NO-CROP LAYOUT: Uses [AspectRatio] with native video dimensions
///    so that 100% of the farmer, Indian flag, tractor, oxen, and sun are NEVER cut off
///    on any Android phone, including tall 20:9 screens like Moto G96.
/// 4. NO ARTIFICIAL BARS: An ambient softly-blurred background video layer fills
///    edge-to-edge to eliminate black or colored letterboxes seamlessly.
/// 5. PREMIUM BRANDING: Compact, single "Khetचाचा" title at the top with a subtle
///    entrance animation ("Khet" in deep green, "चाचा" in saffron orange).
/// 6. CLEAN UI: All legacy bottom taglines and buttons have been completely removed
///    without leaving blank containers or unused reserved spaces.
class SplashAnimationScreen extends StatefulWidget {
  /// Optional callback hook invoked when the video completes playback.
  /// If null, transitions directly to [LanguageSelectionPage] using pushReplacement.
  final VoidCallback? onAnimationComplete;

  const SplashAnimationScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  late AnimationController _brandAnimationController;
  late Animation<double> _brandFadeAnimation;
  late Animation<Offset> _brandSlideAnimation;

  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  static const String _splashVideoPath = 'assets/animation/khetchacha_splash.mp4';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Edge-to-edge transparent system overlay for modern Android devices
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Subtle entrance animation for the top brand header
    _brandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _brandFadeAnimation = CurvedAnimation(
      parent: _brandAnimationController,
      curve: const Interval(0.1, 0.85, curve: Curves.easeOut),
    );

    _brandSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _brandAnimationController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _brandAnimationController.forward();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(_splashVideoPath);
      await _videoController.initialize();
      await _videoController.setLooping(false); // Play exactly once
      await _videoController.setVolume(0.0); // Muted

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      _videoController.addListener(_onVideoPlayerUpdate);
      await _videoController.play();

      // Fallback timer: ensures navigation occurs even if a device codec fails to report completion
      final videoDuration = _videoController.value.duration;
      final timeoutDuration = videoDuration > Duration.zero
          ? videoDuration + const Duration(milliseconds: 600)
          : const Duration(seconds: 4);

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
        // Graceful fallback on initialization error: wait briefly then navigate safely
        _fallbackTimer = Timer(const Duration(milliseconds: 2500), () {
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
        value.position >= value.duration - const Duration(milliseconds: 150)) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _fallbackTimer?.cancel();

    if (_isVideoInitialized) {
      _videoController.removeListener(_onVideoPlayerUpdate);
      _videoController.pause();
    }

    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LanguageSelectionPage(),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized || _hasNavigated) return;

    if (state == AppLifecycleState.paused) {
      _videoController.pause();
    } else if (state == AppLifecycleState.resumed) {
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
    _brandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3814), // Deep agricultural dark green
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          // Video aspect ratio (9:16 portrait)
          final videoAspect = (_isVideoInitialized && _videoController.value.aspectRatio > 0)
              ? _videoController.value.aspectRatio
              : (9 / 16);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ambient Background Layer:
              // Fills the entire screen edge-to-edge with a softly blurred extension
              // of the video. Removes artificial top/bottom bars on all screen ratios
              // (including tall 20:9 Moto G96) while matching the morning sky and field colors.
              if (_isVideoInitialized && !_hasVideoError)
                Transform.scale(
                  scale: 1.15,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width > 0
                            ? _videoController.value.size.width
                            : screenW,
                        height: _videoController.value.size.height > 0
                            ? _videoController.value.size.height
                            : screenH,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                )
              else
                _buildAmbientGradientPlaceholder(),

              // Ambient scrim for visual depth
              Container(
                color: Colors.black.withValues(alpha: 0.08),
              ),

              // 2. Core Uncropped Foreground Video:
              // Preserves exact video aspect ratio without stretching or cropping.
              // Guaranteed: Farmer, Indian flag, moving tractor, oxen, and sunrise remain 100% visible!
              Center(
                child: AspectRatio(
                  aspectRatio: videoAspect,
                  child: (_isVideoInitialized && !_hasVideoError)
                      ? VideoPlayer(_videoController)
                      : _buildLoadingSpinner(),
                ),
              ),

              // 3. Subtle Top Vignette for brand contrast without obscuring subjects
              _buildTopVignette(),

              // 4. Premium Top Brand Header ("Khetचाचा")
              // Compact, clean Flutter text overlay near the top.
              // Strictly NO bottom taglines, buttons, or unused blank containers.
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildCleanTopBrand(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Compact, premium Flutter brand overlay: "Khet" in deep green, "चाचा" in saffron orange.
  Widget _buildCleanTopBrand() {
    return FadeTransition(
      opacity: _brandFadeAnimation,
      child: SlideTransition(
        position: _brandSlideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFFF9933).withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Khet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF1B5E20), // Deep Agriculture Green
                  ),
                ),
                TextSpan(
                  text: 'चाचा',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: Color(0xFFFF7A00), // Saffron Orange
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subtle top gradient vignette for brand contrast
  Widget _buildTopVignette() {
    return const IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x55000000),
                Colors.transparent,
              ],
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 90,
          ),
        ),
      ),
    );
  }

  /// Loading spinner while local video initializes
  Widget _buildLoadingSpinner() {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          color: Color(0xFFFF9933),
        ),
      ),
    );
  }

  /// Ambient rural gradient shown before video initializes
  Widget _buildAmbientGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5BA4D9), // Sky Blue
            Color(0xFFFFD54F), // Sunrise Gold
            Color(0xFF388E3C), // Leaf Green
            Color(0xFF1B5E20), // Deep Forest Green
          ],
          stops: [0.0, 0.40, 0.70, 1.0],
        ),
      ),
    );
  }
}
