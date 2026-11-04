import 'dart:convert';

import 'soil_profile.dart';

/// Represents a distinct farm plot or parcel of agricultural land owned by the farmer.
class FarmPlot {
  final String id;
  final String name;
  final double size;
  final String unit; // 'Acre', 'Bigha', 'Hectare', 'Guntha'
  final SoilProfile soilProfile;
  final String
  irrigationType; // 'Borewell', 'Canal', 'Drip', 'Sprinkler', 'Rainfed'
  final String waterAvailability; // 'High', 'Medium', 'Low'
  final String? currentCrop;
  final String? previousCrop;
  final String notes;

  const FarmPlot({
    required this.id,
    required this.name,
    required this.size,
    this.unit = 'Acre',
    this.soilProfile = const SoilProfile(),
    this.irrigationType = 'Borewell',
    this.waterAvailability = 'Medium',
    this.currentCrop,
    this.previousCrop,
    this.notes = '',
  });

  /// Size converted to standardized Acres for agricultural computations
  double get sizeInAcres {
    switch (unit.toLowerCase()) {
      case 'hectare':
        return size * 2.47105;
      case 'bigha':
        // Default standard bigha (approx 0.4 to 0.6 acre, averaging 0.4 acre)
        return size * 0.4;
      case 'guntha':
        return size / 40.0;
      case 'acre':
      default:
        return size;
    }
  }

  FarmPlot copyWith({
    String? id,
    String? name,
    double? size,
    String? unit,
    SoilProfile? soilProfile,
    String? irrigationType,
    String? waterAvailability,
    String? currentCrop,
    String? previousCrop,
    String? notes,
  }) {
    return FarmPlot(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      unit: unit ?? this.unit,
      soilProfile: soilProfile ?? this.soilProfile,
      irrigationType: irrigationType ?? this.irrigationType,
      waterAvailability: waterAvailability ?? this.waterAvailability,
      currentCrop: currentCrop ?? this.currentCrop,
      previousCrop: previousCrop ?? this.previousCrop,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'unit': unit,
    'soilProfile': soilProfile.toJson(),
    'irrigationType': irrigationType,
    'waterAvailability': waterAvailability,
    'currentCrop': currentCrop,
    'previousCrop': previousCrop,
    'notes': notes,
  };

  factory FarmPlot.fromJson(Map<String, dynamic> json) {
    return FarmPlot(
      id: json['id'] as String? ?? 'plot_1',
      name: json['name'] as String? ?? 'Main Farm Plot',
      size: (json['size'] as num?)?.toDouble() ?? 2.0,
      unit: json['unit'] as String? ?? 'Acre',
      soilProfile: json['soilProfile'] != null
          ? SoilProfile.fromJson(json['soilProfile'] as Map<String, dynamic>)
          : const SoilProfile(),
      irrigationType: json['irrigationType'] as String? ?? 'Borewell',
      waterAvailability: json['waterAvailability'] as String? ?? 'Medium',
      currentCrop: json['currentCrop'] as String?,
      previousCrop: json['previousCrop'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory FarmPlot.fromJsonString(String source) =>
      FarmPlot.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
