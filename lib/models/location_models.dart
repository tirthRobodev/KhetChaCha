import 'dart:convert';

/// Model representing a farmer's verified geographic location.
class FarmerLocationData {
  final String country;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isGpsAccurate;
  final String formattedAddress;

  const FarmerLocationData({
    this.country = 'India',
    required this.state,
    required this.district,
    this.taluka = '',
    this.village = '',
    this.pincode = '',
    required this.latitude,
    required this.longitude,
    this.isGpsAccurate = false,
    this.formattedAddress = '',
  });

  /// Short summary e.g. "Ahmedabad, Gujarat" or "Ludhiana, Punjab"
  String get shortSummary {
    if (district.isNotEmpty && state.isNotEmpty) {
      return '$district, $state';
    }
    return state.isNotEmpty ? state : 'India';
  }

  /// Full hierarchy display: "Village, Taluka, District, State"
  String get fullHierarchy {
    final parts = <String>[];
    if (village.isNotEmpty) parts.add(village);
    if (taluka.isNotEmpty) parts.add(taluka);
    if (district.isNotEmpty) parts.add(district);
    if (state.isNotEmpty) parts.add(state);
    return parts.isEmpty ? 'India' : parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'country': country,
    'state': state,
    'district': district,
    'taluka': taluka,
    'village': village,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'isGpsAccurate': isGpsAccurate,
    'formattedAddress': formattedAddress,
  };

  factory FarmerLocationData.fromJson(Map<String, dynamic> json) {
    return FarmerLocationData(
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      village: json['village'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isGpsAccurate: json['isGpsAccurate'] as bool? ?? false,
      formattedAddress: json['formattedAddress'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory FarmerLocationData.fromJsonString(String source) =>
      FarmerLocationData.fromJson(jsonDecode(source) as Map<String, dynamic>);

  FarmerLocationData copyWith({
    String? country,
    String? state,
    String? district,
    String? taluka,
    String? village,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isGpsAccurate,
    String? formattedAddress,
  }) {
    return FarmerLocationData(
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isGpsAccurate: isGpsAccurate ?? this.isGpsAccurate,
      formattedAddress: formattedAddress ?? this.formattedAddress,
    );
  }
}
