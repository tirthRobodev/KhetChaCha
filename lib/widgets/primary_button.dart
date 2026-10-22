import 'package:flutter/material.dart';

/// Premium KhetChacha primary action button with agricultural gradient,
/// rounded pill shape, and smooth disabled state handling.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: isEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFFFF9933), // Saffron
                  Color(0xFFE65100), // Warm Orange
                  Color(0xFF1B5E20), // Agriculture Forest Green
                ],
                stops: [0.0, 0.45, 1.0],
              )
            : null,
        color: isEnabled ? null : const Color(0xFFE0E0E0),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? Colors.white
                              : const Color(0xFF9E9E9E),
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          icon,
                          color: isEnabled
                              ? Colors.white
                              : const Color(0xFF9E9E9E),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
