import 'package:flutter/material.dart';

import '../../localization/india_districts_data.dart';
import '../../localization/location_data.dart';
import '../../models/farmer_profile.dart';
import '../../models/location_models.dart';
import '../../services/farm_profile_service.dart';
import '../../services/location_service.dart';
import '../../widgets/khetchacha_logo.dart';
import '../../widgets/primary_button.dart';
import '../farm_production_selection_page.dart';

/// Screen allowing farmers to auto-detect their exact farm location via GPS
/// with a complete manual fallback (State, District, Taluka, Village, PIN).
class SmartLocationDetectionPage extends StatefulWidget {
  final FarmerProfile? profile;
  final bool isEditMode;

  const SmartLocationDetectionPage({
    super.key,
    this.profile,
    this.isEditMode = false,
  });

  @override
  State<SmartLocationDetectionPage> createState() =>
      _SmartLocationDetectionPageState();
}

class _SmartLocationDetectionPageState
    extends State<SmartLocationDetectionPage> {
  bool _isDetectingGps = false;
  FarmerLocationData? _detectedLocation;
  String? _errorMessage;

  // Manual fallback form controllers
  final _talukaController = TextEditingController();
  final _villageController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _initFromProfile();
  }

  void _initFromProfile() {
    final p = widget.profile;
    if (p != null) {
      if (p.effectiveState.isNotEmpty) {
        _selectedState = p.effectiveState;
      }
      if (p.effectiveDistrict.isNotEmpty) {
        _selectedDistrict = p.effectiveDistrict;
      }
      if (p.village.isNotEmpty) {
        _villageController.text = p.village;
      }
    }
  }

  @override
  void dispose() {
    _talukaController.dispose();
    _villageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  List<IndianDistrict> get _filteredDistricts {
    if (_selectedState == null || _selectedState!.isEmpty) {
      return const [];
    }
    return IndiaDistrictsData.allDistricts
        .where(
          (d) =>
              d.stateKey.toLowerCase() == _selectedState!.toLowerCase() ||
              d.stateKey.toLowerCase().contains(_selectedState!.toLowerCase()),
        )
        .toList();
  }

  Future<void> _detectGps() async {
    setState(() {
      _isDetectingGps = true;
      _errorMessage = null;
    });

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;

      if (loc != null) {
        setState(() {
          _detectedLocation = loc;
          _selectedState = loc.state;
          _selectedDistrict = loc.district;
          if (loc.taluka.isNotEmpty) _talukaController.text = loc.taluka;
          if (loc.village.isNotEmpty) _villageController.text = loc.village;
          if (loc.pincode.isNotEmpty) _pincodeController.text = loc.pincode;
          _isDetectingGps = false;
        });
      } else {
        setState(() {
          _errorMessage = 'GPS location could not be determined. Please verify location permissions or select your location manually below.';
          _isDetectingGps = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error detecting location: $e';
        _isDetectingGps = false;
      });
    }
  }

  Future<void> _saveAndProceed() async {
    final state = _selectedState ?? '';
    final district = _selectedDistrict ?? '';
    final taluka = _talukaController.text.trim();
    final village = _villageController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (state.isEmpty || district.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least your State and District.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final double lat = _detectedLocation?.latitude ?? 23.0225;
    final double lon = _detectedLocation?.longitude ?? 72.5714;

    final locData = FarmerLocationData(
      country: 'India',
      state: state,
      district: district,
      taluka: taluka,
      village: village,
      pincode: pincode,
      latitude: lat,
      longitude: lon,
      isGpsAccurate: _detectedLocation?.isGpsAccurate ?? false,
      formattedAddress: '$village, $taluka, $district, $state',
    );

    await LocationService.instance.saveCachedLocation(locData);

    // Update existing or build new profile
    final currentProfile =
        widget.profile ??
        const FarmerProfile(
          fullName: 'Farmer',
          mobileNumber: '',
          email: '',
          state: '',
          district: '',
          village: '',
          farmingType: 'Organic',
          landSize: '2 Acres',
        );

    final updatedProfile = currentProfile.copyWith(
      state: state,
      district: district,
      selectedState: state,
      selectedDistrict: district,
      village: village.isNotEmpty ? village : currentProfile.village,
    );

    await FarmProfileService.instance.saveFarmProfile(updatedProfile);

    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.of(context).pop(updatedProfile);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FarmProductionSelectionPage(profile: updatedProfile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            KhetChachaLogo.mark(size: 28),
            const SizedBox(width: 8),
            const Text(
              'Farm Location Setup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (!widget.isEditMode)
            TextButton(
              onPressed: () {
                // Skip for now
                final defaultProf =
                    widget.profile ??
                    const FarmerProfile(
                      fullName: 'Farmer',
                      mobileNumber: '',
                      email: '',
                      state: 'Gujarat',
                      district: 'Ahmedabad',
                      village: 'Local Village',
                      farmingType: 'Mixed',
                      landSize: '2 Acres',
                    );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        FarmProductionSelectionPage(profile: defaultProf),
                  ),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFFFFD54F),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Farming Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'KhetChacha personalizes local weather, nearby mandis & crop recommendations based on your farm.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // GPS Auto Detect Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _detectedLocation != null
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE0E0E0),
                    width: _detectedLocation != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Instant GPS Detection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        if (_detectedLocation != null)
                          const Chip(
                            label: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Automatically identify your State, District, Taluka, and Village using satellite coordinates.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isDetectingGps ? null : _detectGps,
                        icon: _isDetectingGps
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_location_rounded),
                        label: Text(
                          _isDetectingGps
                              ? 'Locating Farm...'
                              : 'Auto-Detect via GPS',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Manual Entry Section Header
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR VERIFY / ENTER MANUALLY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // State Dropdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State / Union Territory *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedState,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      hint: const Text('Select State'),
                      items: LocationData.allStates.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.englishName,
                          child: Text(s.englishName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedState = val;
                          _selectedDistrict = null;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    // District Dropdown
                    const Text(
                      'District *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      hint: Text(
                        _selectedState == null
                            ? 'Select State first'
                            : 'Select District',
                      ),
                      items: _filteredDistricts.map((d) {
                        return DropdownMenuItem<String>(
                          value: d.englishName,
                          child: Text(d.englishName),
                        );
                      }).toList(),
                      onChanged: _selectedState == null
                          ? null
                          : (val) {
                              setState(() {
                                _selectedDistrict = val;
                              });
                            },
                    ),

                    const SizedBox(height: 14),

                    // Taluka / Tehsil
                    const Text(
                      'Taluka / Tehsil',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _talukaController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Daskroi, Malerkotla',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Village
                    const Text(
                      'Village / Town',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _villageController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Bhavda, Kanganwal',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // PIN Code
                    const Text(
                      'Postal PIN Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 382433, 141001',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm and Continue button
              PrimaryButton(
                text: widget.isEditMode
                    ? 'Save Location'
                    : 'Confirm Location & Continue →',
                onPressed: _saveAndProceed,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
