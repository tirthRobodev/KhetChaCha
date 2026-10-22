/// Model representing a farmer's registered profile in KhetChacha.
class FarmerProfile {
  final String fullName;
  final String mobileNumber;
  final String state;
  final String district;
  final String village;
  final String farmingType;
  final String landSize;
  final List<String> crops;

  const FarmerProfile({
    required this.fullName,
    required this.mobileNumber,
    required this.state,
    required this.district,
    required this.village,
    required this.farmingType,
    required this.landSize,
    required this.crops,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'state': state,
        'district': district,
        'village': village,
        'farmingType': farmingType,
        'landSize': landSize,
        'crops': crops,
      };

  factory FarmerProfile.fromJson(Map<String, dynamic> json) => FarmerProfile(
        fullName: json['fullName'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
        state: json['state'] as String? ?? '',
        district: json['district'] as String? ?? '',
        village: json['village'] as String? ?? '',
        farmingType: json['farmingType'] as String? ?? '',
        landSize: json['landSize'] as String? ?? '',
        crops: (json['crops'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
