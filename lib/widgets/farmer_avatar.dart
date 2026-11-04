import 'package:flutter/material.dart';

/// Reusable Farmer Avatar Widget that dynamically renders state-specific
/// traditional farmer illustrations based on the authenticated farmer's selected state.
class FarmerAvatar extends StatelessWidget {
  final String state;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const FarmerAvatar({
    super.key,
    required this.state,
    this.size = 110.0,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// Normalizes state names (including localized Indian scripts) to key asset identifiers.
  static String resolveStateKey(String stateName) {
    final s = stateName.trim().toLowerCase();

    // Gujarat
    if (s.contains('gujarat') || s.contains('ગુજરાત') || s.contains('गुजरात')) {
      return 'gujarat';
    }
    // Punjab
    if (s.contains('punjab') || s.contains('ਪੰਜਾਬ') || s.contains('पंजाब')) {
      return 'punjab';
    }
    // Kerala
    if (s.contains('kerala') || s.contains('കേരളം') || s.contains('केरल')) {
      return 'kerala';
    }
    // Rajasthan
    if (s.contains('rajasthan') ||
        s.contains('રાજસ્થાન') ||
        s.contains('राजस्थान')) {
      return 'rajasthan';
    }
    // Maharashtra
    if (s.contains('maharashtra') ||
        s.contains('મહારાષ્ટ્ર') ||
        s.contains('महाराष्ट्र')) {
      return 'maharashtra';
    }
    // Uttar Pradesh
    if (s.contains('uttar pradesh') ||
        s.contains('ઉત્તર પ્રદેશ') ||
        s.contains('उत्तर प्रदेश') ||
        s.contains('up')) {
      return 'uttar_pradesh';
    }

    return 'default';
  }

  /// Maps normalized state key to asset path
  static String getAssetPathForState(String stateName) {
    final key = resolveStateKey(stateName);
    switch (key) {
      case 'gujarat':
        return 'assets/images/farmers/gujarat.png';
      case 'punjab':
        return 'assets/images/farmers/punjab.png';
      case 'kerala':
        return 'assets/images/farmers/kerala.png';
      case 'rajasthan':
        return 'assets/images/farmers/rajasthan.png';
      case 'maharashtra':
        return 'assets/images/farmers/maharashtra.png';
      case 'uttar_pradesh':
        return 'assets/images/farmers/uttar_pradesh.png';
      default:
        return 'assets/images/farmers/default_farmer.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getAssetPathForState(state);
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback if asset file is missing or failed to decode
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9933), Color(0xFFE65100)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
            ),
          );
        },
      ),
    );
  }
}
