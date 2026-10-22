import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../localization/language_data.dart';
import '../models/app_language.dart';
import '../services/language_service.dart';
import '../widgets/language_card.dart';
import '../widgets/primary_button.dart';
import 'farmer_details_page.dart';

/// Second Page: [LanguageSelectionPage]
/// Implements dual-column layout (11 languages on left, 11 languages on right)
/// with compulsory selection before the user can click "Continue →".
class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  // Compulsory selection: starts as null so user MUST select one before proceeding
  AppLanguage? _selectedLanguage;

  final TextEditingController _searchController = TextEditingController();
  List<AppLanguage> _displayedLanguages = LanguageData.allLanguages;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _displayedLanguages = LanguageData.search(query);
    });
  }

  void _onLanguageSelected(AppLanguage lang) {
    setState(() {
      _selectedLanguage = lang;
    });
  }

  Future<void> _onContinue() async {
    if (_selectedLanguage == null) return;

    // 1. Update active app locale and persist to SharedPreferences
    await LanguageService.instance.setLanguage(_selectedLanguage!);

    // 2. Navigate to Farmer Details Page in the selected language
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FarmerDetailsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic localization preview based on selected language (or fallback to English)
    final previewLoc = _selectedLanguage != null
        ? AppLocalizations(_selectedLanguage!.locale)
        : AppLocalizations(const Locale('en'));

    // Split languages into two columns (11 on first side, 11 on second side)
    final half = (_displayedLanguages.length / 2).ceil();
    final leftList = _displayedLanguages.take(half).toList();
    final rightList = _displayedLanguages.skip(half).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1), // Warm cream background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20)),
          tooltip: 'Back to Welcome',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Khet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  TextSpan(
                    text: 'चाचा',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Title, Subtitle, and Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedLanguage != null
                              ? previewLoc.chooseLanguage
                              : 'Choose Your Language / તમારી ભાષા પસંદ કરો',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (_selectedLanguage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E7D32)),
                          ),
                          child: Text(
                            _selectedLanguage!.nativeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLanguage != null
                        ? previewLoc.chooseLanguageSubtitle
                        : 'Select 1 language to continue to farmer registration form.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search language / ભાષા શોધો...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instruction Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: _selectedLanguage == null
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedLanguage == null
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFF81C784),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedLanguage == null
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_rounded,
                    color: _selectedLanguage == null
                        ? const Color(0xFFE65100)
                        : const Color(0xFF2E7D32),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedLanguage == null
                          ? 'Please select one language below (compulsory to proceed)'
                          : 'Selected: ${_selectedLanguage!.nativeName} (${_selectedLanguage!.englishName})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _selectedLanguage == null
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // DUAL-COLUMN LANGUAGE LIST (Left side: 11 languages, Right side: 11 languages)
            Expanded(
              child: _displayedLanguages.isEmpty
                  ? Center(
                      child: Text(
                        'No language found for "${_searchController.text}"',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Side (Left Column)
                          Expanded(
                            child: Column(
                              children: leftList.map((lang) {
                                final isSelected = lang == _selectedLanguage;
                                return LanguageCard(
                                  language: lang,
                                  isSelected: isSelected,
                                  onSelected: () => _onLanguageSelected(lang),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Second Side (Right Column)
                          Expanded(
                            child: Column(
                              children: rightList.map((lang) {
                                final isSelected = lang == _selectedLanguage;
                                return LanguageCard(
                                  language: lang,
                                  isSelected: isSelected,
                                  onSelected: () => _onLanguageSelected(lang),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Sticky Bottom Continue Action Bar (Disabled until compulsory selection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: _selectedLanguage != null
                        ? previewLoc.continueButton
                        : 'Select Language to Continue →',
                    icon: _selectedLanguage != null
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline_rounded,
                    onPressed: _selectedLanguage != null ? _onContinue : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
