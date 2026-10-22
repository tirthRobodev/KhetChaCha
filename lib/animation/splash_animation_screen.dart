import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// [SplashAnimationScreen] is the first screen of the KhetChacha application.
/// It plays the local video animation (assets/animation/first_page.mp4) full-screen
/// in an automatic, muted, seamless portrait loop, overlaid with:
/// - App Name "Khetचाचा" (Khet in deep green, चाचा in saffron orange)
/// - English Tagline: "Your Farming Friend, Every Season."
/// - Gujarati Tagline: "દરેક ખેડૂતનો સાચો સાથી"
/// - Premium "Ready for Next Step →" button connected to the navigation callback
class SplashAnimationScreen extends StatefulWidget {
  /// Callback hook for when the user taps "Ready for Next Step →"
  /// or when connecting to the upcoming language-selection screen.
  final VoidCallback? onAnimationComplete;

  const SplashAnimationScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _uiAnimationController;

  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();

    // Make system navigation and status bar transparent and blend with video
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1B5E20),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Subtle UI breathing / pulse animation for the action button
    _uiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Initialize local video from assets
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
      debugPrint('Error loading video assets/animation/first_page.mp4: $e');
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
    _uiAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-screen Portrait Video Player (Cover Fit)
              if (_isVideoInitialized && !_hasVideoError)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width > 0
                          ? _videoController.value.size.width
                          : size.width,
                      height: _videoController.value.size.height > 0
                          ? _videoController.value.size.height
                          : size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              else
                _buildVideoPlaceholder(),

              // 2. Soft Gradient Vignettes to ensure text readability without hiding scene
              _buildTopAndBottomVignettes(),

              // 3. Foreground UI Overlays (Top Branding & Bottom Taglines + Button)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // Top Brand Header: "Khetचाचा"
                      _buildTopBrandHeader(),

                      const Spacer(),

                      // Lower Area: English & Gujarati Taglines + Action Button
                      _buildBottomOverlay(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Brand Header: "Khet" in deep green, "चाचा" in saffron orange
  Widget _buildTopBrandHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEEFFFFFF), // 93% opacity white
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xD8FF9933),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x33FF9933),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Agriculture Leaf Icon Badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Color(0xFFFFD54F),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Stylized Text: "Khet" in deep green, "चाचा" in saffron orange
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Khet',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF1B5E20), // Deep Agriculture Green
                        shadows: [
                          Shadow(
                            color: Color(0x22000000),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'चाचा',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFFFF7A00), // Saffron Orange
                        shadows: [
                          Shadow(
                            color: Color(0x22000000),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9933), // Saffron
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF138808), // Green
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'FARMER FRIENDLY APP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Section: Taglines (English & Gujarati) + "Ready for Next Step →" Button
  Widget _buildBottomOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // English Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xEA1B5E20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x804CAF50),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Your Farming Friend, Every Season.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Gujarati Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xEAFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xD8FF9933),
              width: 1.2,
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E342E),
              letterSpacing: 0.4,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Premium "Ready for Next Step →" Action Button
        AnimatedBuilder(
          animation: _uiAnimationController,
          builder: (context, child) {
            final pulse = (math.sin(_uiAnimationController.value * 2 * math.pi) + 1) / 2;
            return GestureDetector(
              onTap: () {
                widget.onAnimationComplete?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9933), Color(0xFFE65100), Color(0xFF1B5E20)],
                    stops: [0.0, 0.50, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(230, 81, 0, 0.40 + 0.20 * pulse),
                      blurRadius: 16 + 6 * pulse,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ready for Next Step',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
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

  /// Subtle top and bottom vignettes to ensure contrast without obscuring the video
  Widget _buildTopAndBottomVignettes() {
    return const IgnorePointer(
      child: Column(
        children: [
          // Top vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59000000),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 140,
            ),
          ),
          Spacer(),
          // Bottom vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x73000000),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 180,
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder while video is initializing
  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF64B5F6),
            Color(0xFFFFCC80),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
          stops: [0.0, 0.45, 0.75, 1.0],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF9933),
        ),
      ),
    );
  }
}
