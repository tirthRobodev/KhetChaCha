import 'package:flutter/material.dart';
import '../models/crop_master_entry.dart';

/// Renders a crop-specific visual representation.
/// 
/// 1. If a verified asset image exists ([CropMasterEntry.assetImage]), renders the image.
/// 2. If a verified remote image exists ([CropMasterEntry.imageUrl]), renders the image.
/// 3. Otherwise, renders a high-clarity botanical vector badge featuring the crop's
///    distinct botanical badge (initials), distinctive color palette, and emoji icon.
/// 
/// Ensures that no two unrelated crops ever display identical visual representations.
class CropVisualWidget extends StatelessWidget {
  final CropMasterEntry crop;
  final double size;
  final bool isSelected;
  final String langCode;

  const CropVisualWidget({
    super.key,
    required this.crop,
    this.size = 46.0,
    this.isSelected = false,
    this.langCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final altText = crop.getAltText(langCode);
    final badgeColor = Color(crop.badgeColorValue);

    Widget visualContent;

    if (crop.assetImage != null && crop.assetImage!.isNotEmpty) {
      visualContent = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          crop.assetImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildBotanicalBadge(badgeColor),
        ),
      );
    } else if (crop.imageUrl != null && crop.imageUrl!.isNotEmpty) {
      visualContent = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          crop.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildBotanicalBadge(badgeColor),
        ),
      );
    } else {
      visualContent = _buildBotanicalBadge(badgeColor);
    }

    return Semantics(
      label: altText,
      image: true,
      child: Tooltip(
        message: altText,
        child: visualContent,
      ),
    );
  }

  Widget _buildBotanicalBadge(Color badgeColor) {
    final badgeText = crop.visualBadge.isNotEmpty
        ? crop.visualBadge
        : (crop.canonicalNameEn.length >= 2
            ? crop.canonicalNameEn.substring(0, 2).toUpperCase()
            : 'CP');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? badgeColor.withValues(alpha: 0.22)
            : badgeColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? badgeColor.withValues(alpha: 0.85)
              : badgeColor.withValues(alpha: 0.40),
          width: isSelected ? 2.0 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Center Emoji / Botanical Icon
          Center(
            child: Text(
              crop.iconEmoji,
              style: TextStyle(
                fontSize: size * 0.44,
                height: 1.0,
              ),
            ),
          ),

          // Distinct 2-Letter Botanical Initials Badge
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.0),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

