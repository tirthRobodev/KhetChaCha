import 'package:flutter/material.dart';
import '../models/app_language.dart';

/// [LanguageCard] designed for dual-column grid/split display:
/// - Fits cleanly in a 2-column layout (11 languages on left, 11 on right)
/// - Shows native language script prominently
/// - Shows English name subtitle
/// - Clear selection indicator (green outline + checkmark badge)
class LanguageCard extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onSelected;

  const LanguageCard({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 3.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF2E7D32).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 6 : 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Row(
              children: [
                // Small Language Code Pill
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9933).withValues(alpha: 0.20)
                        : const Color(0xFF1B5E20).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      language.code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFFE65100)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Language Native & English Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        language.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF388E3C)
                              : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark Indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFBDBDBD),
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
