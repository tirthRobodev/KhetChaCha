import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// [SplashAnimationScreen] is the first screen of the KhetChacha application.
/// It plays the local video animation (assets/animation/first_page.mp4) in portrait mode,
/// with the following responsive design principles:
///
/// 1. NO VIDEO CROPPING: Uses [BoxFit.contain] on the foreground video to guarantee
///    that 100% of the farming scene (farmer, Indian flag, moving tractor, oxen, sunrise)
///    remains fully visible on all phone screen ratios, including the tall Moto G96 (20:9).
///
/// 2. NO BLACK BARS: Uses an ambient softly blurred background video layer behind the
///    core video to seamlessly fill tall screen margins with the video's natural morning colors.
///
/// 3. NO DUPLICATE LOGOS: The duplicate bulky white top logo box has been removed so it
///    does not clash with the logo/text already baked into the video.
///    A clean Flutter text overlay "Khetचाचा" is available via [showTopBrandHeader].
///
/// 4. COMPACT LOWER SECTION: English and Gujarati taglines and the "Ready for Next Step →"
///    button are arranged compactly in the lower safe area, preventing any overlap with the
///    farmer, tractor, or system navigation bars.
class SplashAnimationScreen extends StatefulWidget {
  /// Callback hook invoked when the user taps "Ready for Next Step →".
  final VoidCallback? onAnimationComplete;

  /// Whether to display the Flutter top brand text overlay ("Khetचाचा").
  /// Defaults to false because the current video already has the logo baked in,
  /// preventing duplicate branding. Set to true if using a clean background video.
  final bool showTopBrandHeader;

  /// Whether to display the English and Gujarati taglines.
  /// Defaults to true.
  final bool showTaglines;

  const SplashAnimationScreen({
    super.key,
    this.onAnimationComplete,
    this.showTopBrandHeader = false,
    this.showTaglines = true,
  });

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _pulseController;

  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();

    // Configure system navigation and status bar for edge-to-edge rural aesthetics
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF1B5E20),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Subtle pulse animation for the action button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/animation/first_page.mp4',
      );

      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0.0); // Muted
      await _videoController.play(); // Auto-play

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading assets/animation/first_page.mp4: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3813), // Deep agricultural dark green base
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          // Native video aspect ratio (typically 720/1280 = 9:16 = 0.5625)
          final videoAspect = (_isVideoInitialized && _videoController.value.aspectRatio > 0)
              ? _videoController.value.aspectRatio
              : (9 / 16);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ambient Background Layer:
              // Fills the entire screen with a softly blurred extension of the video.
              // Eliminates black bars on tall screens (like Moto G96) while matching
              // the exact colors of the sunrise sky and agricultural soil.
              if (_isVideoInitialized && !_hasVideoError)
                Transform.scale(
                  scale: 1.15,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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

              // Ambient scrim for visual depth and text readability
              Container(
                color: Colors.black.withValues(alpha: 0.16),
              ),

              // 2. Core Uncropped Foreground Video:
              // Rendered with BoxFit.contain in its native aspect ratio.
              // Preserves 100% of the scene: the farmer, waving Indian flag,
              // moving tractor, oxen plough, and sunrise are NEVER cropped!
              Center(
                child: AspectRatio(
                  aspectRatio: videoAspect,
                  child: (_isVideoInitialized && !_hasVideoError)
                      ? VideoPlayer(_videoController)
                      : _buildLoadingSpinner(),
                ),
              ),

              // 3. Subtle Vignettes for High-Contrast Text Legibility
              _buildEdgeVignettes(),

              // 4. Foreground UI Overlays (Top Branding & Bottom Taglines + Button)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Top Brand Header (Clean Flutter text overlay, no duplicate bulky panel)
                      if (widget.showTopBrandHeader)
                        _buildCleanTopBrand()
                      else
                        const SizedBox(height: 12),

                      const Spacer(),

                      // Lower Area: Taglines and "Ready for Next Step →" Button
                      _buildBottomControls(),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Clean, compact Flutter brand text overlay: "Khet" in deep green, "चाचा" in saffron orange.
  /// Free of oversized bulky panels, designed with soft ambient glow for high legibility.
  Widget _buildCleanTopBrand() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEAFFFFFF), // Semi-transparent clean white
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xD8FF9933),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                shadows: [
                  Shadow(
                    color: Color(0x18000000),
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            TextSpan(
              text: 'चाचा',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                color: Color(0xFFFF7A00), // Saffron Orange
                shadows: [
                  Shadow(
                    color: Color(0x18000000),
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact lower section containing the English tagline, Gujarati tagline,
  /// and the "Ready for Next Step →" button without overlapping the video scene.
  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTaglines) ...[
          // English Tagline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xEA1B5E20), // Forest Green
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x804CAF50),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x35000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: Color(0xFFFFD54F),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Your Farming Friend, Every Season.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Gujarati Tagline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xEEFFFFFF), // Crisp Light Background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xD8FF9933),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'દરેક ખેડૂતનો સાચો સાથી',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E342E),
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],

        // Premium "Ready for Next Step →" Action Button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = (math.sin(_pulseController.value * 2 * math.pi) + 1) / 2;
            return GestureDetector(
              onTap: () {
                widget.onAnimationComplete?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9933), Color(0xFFE65100), Color(0xFF1B5E20)],
                    stops: [0.0, 0.50, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(230, 81, 0, 0.40 + 0.18 * pulse),
                      blurRadius: 14 + 6 * pulse,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ready for Next Step',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Subtle edge gradient vignettes to ensure readability of UI elements
  /// without concealing the middle ground farming characters
  Widget _buildEdgeVignettes() {
    return const IgnorePointer(
      child: Column(
        children: [
          // Top Vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D000000),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 100,
            ),
          ),
          Spacer(),
          // Bottom Vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 130,
            ),
          ),
        ],
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

  /// Ambient rural gradient shown before video loads
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
