import 'package:flutter/material.dart';

/// Official KhetChacha AGRITECH Logo Component.
/// Renders the official brand identity in various layouts:
/// - [KhetChachaLogo.appBar]: Horizontal emblem mark + "Khet" + "चाचा" / "AGRITECH" for AppBars.
/// - [KhetChachaLogo.mark]: Circular emblem mark alone.
/// - [KhetChachaLogo.full]: Complete horizontal logo (emblem + text).
class KhetChachaLogo extends StatelessWidget {
  final double height;
  final bool showTagline;
  final bool isLightBackground;
  final VoidCallback? onTap;

  const KhetChachaLogo({
    super.key,
    this.height = 36.0,
    this.showTagline = false,
    this.isLightBackground = false,
    this.onTap,
  });

  /// Standard AppBar brand widget (Mark + Khetचाचा typography)
  static Widget appBar({double height = 32.0, bool isDark = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/khetchacha_mark.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9933),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Khet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  letterSpacing: 0.2,
                ),
              ),
              TextSpan(
                text: 'चाचा',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFF9933) : const Color(0xFFFF7A00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Circular emblem mark alone
  static Widget mark({double size = 36.0}) {
    return Image.asset(
      'assets/images/khetchacha_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFFF9933),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  /// Prominent full logo (used on Login, Welcome, and About sheets)
  static Widget full({double height = 54.0}) {
    return Image.asset(
      'assets/images/khetchacha_full_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark(size: height * 0.8),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Khet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    TextSpan(
                      text: 'Chacha',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9933),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'A G R I T E C H',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Image.asset(
      'assets/images/khetchacha_full_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => appBar(height: height),
    );

    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    return child;
  }
}
