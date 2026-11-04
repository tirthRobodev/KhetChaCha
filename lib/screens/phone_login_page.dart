import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_localizations.dart';
import '../localization/language_data.dart';
import '../models/farmer_profile.dart';
import '../services/farm_profile_service.dart';
import '../services/language_service.dart';
import '../widgets/khetchacha_logo.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/phone_otp_dialog.dart';
import 'farmer_dashboard_page.dart';
import 'farmer_details_page.dart';
import 'language_selection_page.dart';

/// Screen 2 in User Flow: [PhoneLoginPage]
/// Provides OTP Login via Firebase Phone Auth with Email OTP fallback.
/// Pre-fills known credentials and supports OS Autofill.
/// Routes returning farmers directly to [FarmerDashboardPage],
/// and new farmers to [FarmerDetailsPage] -> [FarmProductionSelectionPage].
class PhoneLoginPage extends StatefulWidget {
  final FarmerProfile? initialProfile;

  const PhoneLoginPage({super.key, this.initialProfile});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastLoginDetails();
  }

  Future<void> _loadLastLoginDetails() async {
    try {
      if (widget.initialProfile != null) {
        if (_phoneController.text.isEmpty &&
            widget.initialProfile!.mobileNumber.isNotEmpty) {
          _phoneController.text = sanitizeIndianPhoneNumber(
            widget.initialProfile!.mobileNumber,
          );
        }
        if (_emailController.text.isEmpty &&
            widget.initialProfile!.email.isNotEmpty) {
          _emailController.text = widget.initialProfile!.email;
        }
      }
      final cached = await FarmProfileService.instance.loadFarmProfile();
      if (cached != null && mounted) {
        setState(() {
          if (_phoneController.text.isEmpty && cached.mobileNumber.isNotEmpty) {
            _phoneController.text = sanitizeIndianPhoneNumber(
              cached.mobileNumber,
            );
          }
          if (_emailController.text.isEmpty && cached.email.isNotEmpty) {
            _emailController.text = cached.email;
          }
        });
      }
    } catch (e) {
      debugPrint('[PhoneLoginPage] Autofill notice: $e');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    TextInput.finishAutofillContext();

    setState(() {
      _isLoading = true;
    });

    final phone = sanitizeIndianPhoneNumber(_phoneController.text);
    final email = _emailController.text.trim();

    // Launch existing PhoneOtpDialog
    final verifiedUid = await PhoneOtpDialog.show(
      context,
      rawPhoneNumber: phone,
      email: email,
      farmerName: 'Farmer',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (verifiedUid == null) {
      // User cancelled OTP or failed
      return;
    }

    // Check if returning user with completed farm profile
    final existingProfile = await FarmProfileService.instance.loadFarmProfile(
      verifiedUid,
    );

    if (!mounted) return;

    if (existingProfile != null && existingProfile.farmSetupCompleted) {
      // Returning user flow: restore language and go straight to Personalized Dashboard!
      if (existingProfile.selectedLanguage.isNotEmpty) {
        final lang = LanguageData.allLanguages.firstWhere(
          (l) => l.code == existingProfile.selectedLanguage,
          orElse: () => LanguageData.defaultLanguage,
        );
        await LanguageService.instance.setLanguage(lang);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => FarmerDashboardPage(profile: existingProfile),
        ),
        (route) => false,
      );
    } else {
      // First-time user flow: proceed to Farmer Details
      final baseProfile =
          existingProfile ??
          widget.initialProfile ??
          const FarmerProfile(
            fullName: '',
            mobileNumber: '',
            email: '',
            state: '',
            district: '',
            village: '',
            farmingType: '',
            landSize: '',
          );

      final currentLangCode = LanguageService.instance.currentLanguage.code;
      final nextProfile = baseProfile.copyWith(
        mobileNumber: phone.isNotEmpty ? phone : baseProfile.mobileNumber,
        email: email.isNotEmpty ? email : baseProfile.email,
        firebaseUid: verifiedUid,
        isPhoneVerified: true,
        selectedLanguage: currentLangCode.isNotEmpty
            ? currentLangCode
            : baseProfile.selectedLanguage,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FarmerDetailsPage(initialProfile: nextProfile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1B5E20),
                ),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: const Icon(
                Icons.language_rounded,
                size: 16,
                color: Color(0xFF1B5E20),
              ),
              label: Text(
                LanguageService.instance.currentLanguage.nativeName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              backgroundColor: const Color(0xFFE8F5E9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: Color(0xFFC8E6C9)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LanguageSelectionPage(
                      initialProfile: widget.initialProfile,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // 1. App Header & Tagline
                  Center(
                    child: Column(
                      children: [
                        KhetChachaLogo.mark(size: 76),
                        const SizedBox(height: 12),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Khet',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Chacha',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF9933),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'A G R I T E C H',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4.5,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.appTagline,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF616161),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 2. Step Progress Indicator (Step 1 of 3: Login)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        _buildStepCircle(
                          number: '1',
                          label: loc.stepLogin,
                          isActive: true,
                          isDone: false,
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        _buildStepCircle(
                          number: '2',
                          label: loc.stepSelectProduction,
                          isActive: false,
                          isDone: false,
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        _buildStepCircle(
                          number: '3',
                          label: loc.stepDashboard,
                          isActive: false,
                          isDone: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Login Card
                  Container(
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE8F5E9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farmer Login / किसान लॉगिन',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your mobile number to receive OTP verification code.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mobile Number Field
                        Text(
                          loc.mobileNumberLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                            AutofillHints.telephoneNumberNational,
                          ],
                          inputFormatters: const [
                            IndianPhoneNumberInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 4),
                                  Text(
                                    '+91',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            hintText: loc.mobileNumberHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFC8E6C9),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B5E20),
                                width: 1.8,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final clean = sanitizeIndianPhoneNumber(
                              value ?? '',
                            );
                            if (clean.length != 10) {
                              return loc.valMobileRequired;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Optional Email Field (for instant OTP fallback)
                        Row(
                          children: [
                            Text(
                              loc.emailLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Email OTP Backup',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF616161),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF2E7D32),
                            ),
                            hintText: 'e.g. farmer@gmail.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFC8E6C9),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B5E20),
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleGetOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get OTP / આગળ વધો',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'KhetChaCha • Protected by Firebase OTP & AES-256',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle({
    required String number,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    Color bg = const Color(0xFFEEEEEE);
    Color fg = const Color(0xFF9E9E9E);

    if (isActive) {
      bg = const Color(0xFF1B5E20);
      fg = Colors.white;
    } else if (isDone) {
      bg = const Color(0xFF2E7D32);
      fg = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF1B5E20) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    number,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1B5E20) : const Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}
