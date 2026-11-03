/// Model representing a farmer's registered profile in KhetChacha.
/// Stores personal details, location, and personalized farm production configuration.
class FarmerProfile {
  final String fullName;
  final String mobileNumber;
  final String email;
  final String state;
  final String district;
  final String village;
  final String farmingType;
  final String landSize;
  final List<String> crops;
  final String? firebaseUid;
  final bool isPhoneVerified;

  // Personalized Farm Setup attributes (Required by Firebase schema)
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;
  final List<String> selectedCategories;
  final List<String> selectedProducts;
  final String farmSize;
  final bool farmSetupCompleted;
  final String updatedAt;

  // Smart Location & Land Profile Attributes (Phase 3)
  final String taluka;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String landUnit;
  final String soilType;
  final String irrigationType;
  final String waterAvailability;
  final String farmingSeason;
  final List<String> interestedCrops;

  const FarmerProfile({
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.state,
    required this.district,
    required this.village,
    required this.farmingType,
    required this.landSize,
    this.crops = const [],
    this.firebaseUid,
    this.isPhoneVerified = false,
    this.selectedLanguage = 'en',
    this.selectedState = '',
    this.selectedDistrict = '',
    this.selectedCategories = const [],
    this.selectedProducts = const [],
    this.farmSize = '',
    this.farmSetupCompleted = false,
    this.updatedAt = '',
    this.taluka = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.landUnit = 'Acre',
    this.soilType = 'Loamy soil',
    this.irrigationType = 'Borewell',
    this.waterAvailability = 'Medium',
    this.farmingSeason = 'Rabi',
    this.interestedCrops = const [],
  });

  /// Convenient helper to get effective state (checks selectedState first, then state)
  String get effectiveState => selectedState.isNotEmpty ? selectedState : state;

  /// Convenient helper to get effective district
  String get effectiveDistrict =>
      selectedDistrict.isNotEmpty ? selectedDistrict : district;

  /// Convenient helper to get effective village
  String get effectiveVillage => village.isNotEmpty ? village : 'Local Village';

  /// Convenient helper to get effective farm size
  String get effectiveFarmSize => farmSize.isNotEmpty ? farmSize : landSize;

  /// Convenient helper to get effective crop/product list
  List<String> get effectiveProducts =>
      selectedProducts.isNotEmpty ? selectedProducts : crops;

  FarmerProfile copyWith({
    String? fullName,
    String? mobileNumber,
    String? email,
    String? state,
    String? district,
    String? village,
    String? farmingType,
    String? landSize,
    List<String>? crops,
    String? firebaseUid,
    bool? isPhoneVerified,
    String? selectedLanguage,
    String? selectedState,
    String? selectedDistrict,
    List<String>? selectedCategories,
    List<String>? selectedProducts,
    String? farmSize,
    bool? farmSetupCompleted,
    String? updatedAt,
    String? taluka,
    String? pincode,
    double? latitude,
    double? longitude,
    String? landUnit,
    String? soilType,
    String? irrigationType,
    String? waterAvailability,
    String? farmingSeason,
    List<String>? interestedCrops,
  }) {
    return FarmerProfile(
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      state: state ?? this.state,
      district: district ?? this.district,
      village: village ?? this.village,
      farmingType: farmingType ?? this.farmingType,
      landSize: landSize ?? this.landSize,
      crops: crops ?? this.crops,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      farmSize: farmSize ?? this.farmSize,
      farmSetupCompleted: farmSetupCompleted ?? this.farmSetupCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      taluka: taluka ?? this.taluka,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landUnit: landUnit ?? this.landUnit,
      soilType: soilType ?? this.soilType,
      irrigationType: irrigationType ?? this.irrigationType,
      waterAvailability: waterAvailability ?? this.waterAvailability,
      farmingSeason: farmingSeason ?? this.farmingSeason,
      interestedCrops: interestedCrops ?? this.interestedCrops,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'mobileNumber': mobileNumber,
    'email': email,
    'state': state,
    'district': district,
    'village': village,
    'farmingType': farmingType,
    'landSize': landSize,
    'crops': crops,
    'firebaseUid': firebaseUid,
    'isPhoneVerified': isPhoneVerified,
    'selectedLanguage': selectedLanguage,
    'selectedState': selectedState.isNotEmpty ? selectedState : state,
    'selectedDistrict': selectedDistrict.isNotEmpty
        ? selectedDistrict
        : district,
    'selectedCategories': selectedCategories,
    'selectedProducts': selectedProducts.isNotEmpty ? selectedProducts : crops,
    'farmSize': farmSize.isNotEmpty ? farmSize : landSize,
    'farmSetupCompleted': farmSetupCompleted,
    'updatedAt': updatedAt.isNotEmpty
        ? updatedAt
        : DateTime.now().toIso8601String(),
    'taluka': taluka,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'landUnit': landUnit,
    'soilType': soilType,
    'irrigationType': irrigationType,
    'waterAvailability': waterAvailability,
    'farmingSeason': farmingSeason,
    'interestedCrops': interestedCrops,
  };

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    final stateVal =
        json['selectedState'] as String? ?? json['state'] as String? ?? '';
    final districtVal =
        json['selectedDistrict'] as String? ??
        json['district'] as String? ??
        '';
    final farmSizeVal =
        json['farmSize'] as String? ?? json['landSize'] as String? ?? '';

    List<String> rawProducts = [];
    if (json['selectedProducts'] != null) {
      rawProducts = (json['selectedProducts'] as List<dynamic>).cast<String>();
    } else if (json['crops'] != null) {
      rawProducts = (json['crops'] as List<dynamic>).cast<String>();
    }

    List<String> rawCategories = [];
    if (json['selectedCategories'] != null) {
      rawCategories = (json['selectedCategories'] as List<dynamic>)
          .cast<String>();
    }

    List<String> rawInterested = [];
    if (json['interestedCrops'] != null) {
      rawInterested = (json['interestedCrops'] as List<dynamic>).cast<String>();
    }

    return FarmerProfile(
      fullName: json['fullName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      state: stateVal,
      district: districtVal,
      village: json['village'] as String? ?? '',
      farmingType: json['farmingType'] as String? ?? '',
      landSize: farmSizeVal,
      crops: rawProducts,
      firebaseUid: json['firebaseUid'] as String?,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      selectedLanguage: json['selectedLanguage'] as String? ?? 'en',
      selectedState: stateVal,
      selectedDistrict: districtVal,
      selectedCategories: rawCategories,
      selectedProducts: rawProducts,
      farmSize: farmSizeVal,
      farmSetupCompleted: json['farmSetupCompleted'] as bool? ?? false,
      updatedAt: json['updatedAt'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      landUnit: json['landUnit'] as String? ?? 'Acre',
      soilType: json['soilType'] as String? ?? 'Loamy soil',
      irrigationType: json['irrigationType'] as String? ?? 'Borewell',
      waterAvailability: json['waterAvailability'] as String? ?? 'Medium',
      farmingSeason: json['farmingSeason'] as String? ?? 'Rabi',
      interestedCrops: rawInterested,
    );
  }
}
