import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/language_service.dart';
import '../localization/calculator_localization.dart';
import 'khetchacha_logo.dart';

/// Reusable UI building blocks for KhetChacha agricultural calculators.
/// Designed for high legibility, touch friendliness, and agricultural green & saffron theme.

class CalculatorScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget>? actions;

  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.instance.currentLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            KhetChachaLogo.mark(size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 14,
                  color: Color(0xFFFFD54F),
                ),
                const SizedBox(width: 4),
                Text(
                  activeLang.nativeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class CalculatorInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? suffixText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool isDecimal;

  const CalculatorInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.suffixText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.isDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                isDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
              ),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 20)
                  : null,
              suffixIcon:
                  suffix ??
                  (suffixText != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Text(
                            suffixText!,
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : null),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 1.8,
                ),
              ),
              errorText: errorText,
              helperText: helperText,
              helperStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalculatorActionButtons extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final String? calculateText;
  final String? resetText;

  const CalculatorActionButtons({
    super.key,
    required this.onCalculate,
    required this.onReset,
    this.calculateText,
    this.resetText,
  });

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final calcLabel =
        calculateText ?? CalculatorLocalization.t('calculate_action', langCode);
    final resetLabel =
        resetText ?? CalculatorLocalization.t('reset_action', langCode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate_rounded, size: 22),
              label: Text(
                calcLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFEF9A9A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                resetLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final IconData? icon;

  const ResultMetricBox({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: primaryColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CalculationBreakdownCard extends StatelessWidget {
  final List<String> steps;
  final String? formula;

  const CalculationBreakdownCard({
    super.key,
    required this.steps,
    this.formula,
  });

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                CalculatorLocalization.t('calculation_breakdown', langCode),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          if (formula != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📐 $formula',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF424242),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
