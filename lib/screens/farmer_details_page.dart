import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../localization/location_data.dart';
import '../models/farmer_profile.dart';
import '../services/language_service.dart';
import '../widgets/phone_otp_dialog.dart';
import '../widgets/primary_button.dart';
import 'farmer_dashboard_page.dart';
import 'language_selection_page.dart';

/// Third Page: [FarmerDetailsPage]
/// Fully localized form collecting basic farmer information:
/// - Full Name (Compulsory)
/// - Mobile Number (Compulsory)
/// - Email ID (Compulsory)
/// - State (Compulsory - contains ALL 28 States & 8 UTs of India)
/// - District (Compulsory - dynamically updates per state)
/// - Village (Compulsory)
/// - Farming Type (Compulsory)
/// - Land Size (Compulsory)
class FarmerDetailsPage extends StatefulWidget {
  /// Complete list of ALL 28 States and 8 Union Territories of India
  static List<String> get allIndianStatesAndUTs =>
      LocationData.allStates.map((s) => s.englishName).toList();

  const FarmerDetailsPage({super.key});

  @override
  State<FarmerDetailsPage> createState() => _FarmerDetailsPageState();
}

class _FarmerDetailsPageState extends State<FarmerDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedFarmingType;
  String? _selectedLandSize;

  bool _isSubmitting = false;


  List<IndianDistrict> _getDistrictsForState(String? stateKey) {
    if (stateKey == null || stateKey.isEmpty) return [];
    return LocationData.getDistrictsForState(stateKey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final loc = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Compulsory State validation
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.valStateRequired),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Compulsory District validation
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty || _selectedDistrict == 'Select State First') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.valDistrictRequired),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Compulsory Farming Type validation
    if (_selectedFarmingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.valFarmingTypeRequired),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Compulsory Land Size validation
    if (_selectedLandSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.valLandSizeRequired),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Launch Mobile & Email OTP verification
    final verifiedUid = await PhoneOtpDialog.show(
      context,
      rawPhoneNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      farmerName: _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (verifiedUid == null) {
      // User cancelled OTP or verification didn't succeed
      return;
    }

    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final stateObj = LocationData.allStates.firstWhere(
      (s) => s.key == _selectedState,
      orElse: () => LocationData.allStates.first,
    );
    final stateDisplayName = stateObj.getLocalizedName(langCode);

    final profile = FarmerProfile(
      fullName: _nameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      state: stateDisplayName,
      district: _selectedDistrict!,
      village: _villageController.text.trim(),
      farmingType: _selectedFarmingType!,
      landSize: _selectedLandSize!,
      firebaseUid: verifiedUid,
      isPhoneVerified: true,
    );

    _showSuccessDialog(profile);
  }

  void _showSuccessDialog(FarmerProfile profile) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.successTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.successMessage,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF424242)),
                ),
                const SizedBox(height: 10),
                if (profile.isPhoneVerified) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          loc.otpVerifiedSuccess,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(),
                _buildSummaryRow(loc.fullNameLabel, profile.fullName),
                _buildSummaryRow(loc.mobileNumberLabel, profile.mobileNumber),
                _buildSummaryRow(loc.emailLabel, profile.email),
                _buildSummaryRow(loc.stateLabel, profile.state),
                _buildSummaryRow(loc.districtLabel, profile.district),
                _buildSummaryRow(loc.villageLabel, profile.village),
                _buildSummaryRow(loc.farmingTypeLabel, profile.farmingType),
                _buildSummaryRow(loc.landSizeLabel, profile.landSize),
                if (profile.firebaseUid != null)
                  _buildSummaryRow('Firebase UID', profile.firebaseUid!),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => FarmerDashboardPage(profile: profile),
                  ),
                  (route) => false,
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Go to Dashboard →',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF616161)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF212121)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final activeLang = LanguageService.instance.currentLanguage;

    final availableDistricts = _getDistrictsForState(_selectedState);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20)),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.farmerDetailsTitle,
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
          ),
        ),
        actions: [
          // Language Switcher Chip in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: const Icon(Icons.translate, size: 16, color: Color(0xFFE65100)),
              label: Text(
                activeLang.nativeName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              backgroundColor: const Color(0xFFE8F5E9),
              side: const BorderSide(color: Color(0xFFFF9933), width: 1),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LanguageSelectionPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Card
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: Color(0xFF2E7D32), size: 26),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.farmerDetailsTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.farmerDetailsSubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF616161),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Field 1: Full Name (Compulsory)
                _buildSectionLabel(loc.fullNameLabel, isRequired: true),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _nameController,
                  hintText: loc.fullNameHint,
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.valNameRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 2: Mobile Number (Compulsory)
                _buildSectionLabel(loc.mobileNumberLabel, isRequired: true),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _mobileController,
                  hintText: loc.mobileNumberHint,
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return loc.valMobileRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 3: Email ID (Compulsory)
                _buildSectionLabel(loc.emailLabel, isRequired: true),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _emailController,
                  hintText: loc.emailHint,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.valEmailRequired;
                    }
                    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return loc.valEmailInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 4: State Selector (Compulsory - ALL 28 States & 8 UTs)
                _buildSectionLabel(loc.stateLabel, isRequired: true),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF2E7D32), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                  ),
                  hint: Text(
                    loc.stateHint,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                  ),
                  items: LocationData.allStates.map((state) {
                    return DropdownMenuItem(
                      value: state.key,
                      child: Text(
                        state.getLocalizedName(activeLang.locale.languageCode),
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF212121)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedDistrict = null; // Reset district when state changes
                    });
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return loc.valStateRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 5: District Selector (Compulsory - updates dynamically per state in selected language)
                _buildSectionLabel(loc.districtLabel, isRequired: true),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF2E7D32), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                  ),
                  hint: Text(
                    _selectedState == null
                        ? (activeLang.locale.languageCode == 'gu'
                            ? 'પહેલા રાજ્ય પસંદ કરો'
                            : (activeLang.locale.languageCode == 'hi' ? 'पहले राज्य चुनें' : 'Select State First'))
                        : loc.districtHint,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                  ),
                  items: availableDistricts.map((d) {
                    final dName = d.getLocalizedName(activeLang.locale.languageCode);
                    return DropdownMenuItem(
                      value: dName,
                      child: Text(dName, style: const TextStyle(fontSize: 13.5, color: Color(0xFF212121))),
                    );
                  }).toList(),
                  onChanged: _selectedState != null
                      ? (val) {
                          setState(() {
                            _selectedDistrict = val;
                          });
                        }
                      : null,
                  validator: (val) {
                    if (val == null || val.isEmpty || val == 'Select State First') {
                      return loc.valDistrictRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 5: Village (Compulsory)
                _buildSectionLabel(loc.villageLabel, isRequired: true),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _villageController,
                  hintText: loc.villageHint,
                  icon: Icons.holiday_village_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.valVillageRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Field 6: Farming Type (Compulsory)
                _buildSectionLabel(loc.farmingTypeLabel, isRequired: true),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: loc.farmingTypes.map((type) {
                    final isSelected = _selectedFarmingType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE8F5E9),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF424242),
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFarmingType = selected ? type : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Field 7: Land Size (Compulsory)
                _buildSectionLabel(loc.landSizeLabel, isRequired: true),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: loc.landSizes.map((size) {
                    final isSelected = _selectedLandSize == size;
                    return ChoiceChip(
                      label: Text(size),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFF3E0),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFE65100) : const Color(0xFF424242),
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF9933) : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedLandSize = selected ? size : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Compulsory Submit Button
                PrimaryButton(
                  text: loc.submitButton,
                  isLoading: _isSubmitting,
                  onPressed: _onSubmit,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSectionLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<String>? autofillHints,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
        ),
      ),
    );
  }
}
