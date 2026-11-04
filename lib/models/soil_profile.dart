import 'dart:convert';

/// Represents the 9 official major soil types recognized in Indian Agriculture.
enum SoilType {
  blackRegur,
  alluvial,
  red,
  sandy,
  clay,
  loamy,
  laterite,
  mountain,
  salineAlkaline,
}

extension SoilTypeExtension on SoilType {
  String get displayNameEn {
    switch (this) {
      case SoilType.blackRegur:
        return 'Black soil (Regur)';
      case SoilType.alluvial:
        return 'Alluvial soil';
      case SoilType.red:
        return 'Red soil';
      case SoilType.sandy:
        return 'Sandy soil';
      case SoilType.clay:
        return 'Clay soil';
      case SoilType.loamy:
        return 'Loamy soil';
      case SoilType.laterite:
        return 'Laterite soil';
      case SoilType.mountain:
        return 'Mountain soil';
      case SoilType.salineAlkaline:
        return 'Saline and alkaline soil';
    }
  }

  String get displayNameGu {
    switch (this) {
      case SoilType.blackRegur:
        return 'કાળી જમીન (રેગુર)';
      case SoilType.alluvial:
        return 'કાંપવાળી જમીન';
      case SoilType.red:
        return 'રાતી જમીન';
      case SoilType.sandy:
        return 'રેતાળ જમીન';
      case SoilType.clay:
        return 'ચીકણી જમીન';
      case SoilType.loamy:
        return 'ગોરાડુ / લોમી જમીન';
      case SoilType.laterite:
        return 'પડખાઉ (લેટેરાઈટ) જમીન';
      case SoilType.mountain:
        return 'પર્વતીય જમીન';
      case SoilType.salineAlkaline:
        return 'ક્ષારીય / ભાસ્મિક જમીન';
    }
  }

  String get displayNameHi {
    switch (this) {
      case SoilType.blackRegur:
        return 'काली मिट्टी (रेगुर)';
      case SoilType.alluvial:
        return 'जलोढ़ मिट्टी';
      case SoilType.red:
        return 'लाल मिट्टी';
      case SoilType.sandy:
        return 'बलुई / रेतीली मिट्टी';
      case SoilType.clay:
        return 'चिकनी मिट्टी';
      case SoilType.loamy:
        return 'दोमट मिट्टी';
      case SoilType.laterite:
        return 'लैटेराइट मिट्टी';
      case SoilType.mountain:
        return 'पर्वतीय मिट्टी';
      case SoilType.salineAlkaline:
        return 'लवणीय एवं क्षारीय मिट्टी';
    }
  }

  String get displayNamePa {
    switch (this) {
      case SoilType.blackRegur:
        return 'ਕਾਲੀ ਮਿੱਟੀ (ਰੇਗੁਰ)';
      case SoilType.alluvial:
        return 'ਜਲੋੜ ਮਿੱਟੀ';
      case SoilType.red:
        return 'ਲਾਲ ਮਿੱਟੀ';
      case SoilType.sandy:
        return 'ਰੇਤਲੀ ਮਿੱਟੀ';
      case SoilType.clay:
        return 'ਚਿਕਣੀ ਮਿੱਟੀ';
      case SoilType.loamy:
        return 'ਦੋਮਟ ਮਿੱਟੀ';
      case SoilType.laterite:
        return 'ਲੈਟਰਾਈਟ ਮਿੱਟੀ';
      case SoilType.mountain:
        return 'ਪਹਾੜੀ ਮਿੱਟੀ';
      case SoilType.salineAlkaline:
        return 'ਖਾਰੀ / ਕੱਲਰ ਮਿੱਟੀ';
    }
  }

  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return displayNameGu;
      case 'hi':
        return displayNameHi;
      case 'pa':
        return displayNamePa;
      default:
        return displayNameEn;
    }
  }

  static SoilType fromString(String? text) {
    if (text == null) return SoilType.loamy;
    final lower = text.toLowerCase();
    if (lower.contains('black') ||
        lower.contains('regur') ||
        lower.contains('કાળી') ||
        lower.contains('काली')) {
      return SoilType.blackRegur;
    }
    if (lower.contains('alluvial') ||
        lower.contains('કાંપ') ||
        lower.contains('जलोढ़') ||
        lower.contains('ਜਲੋੜ')) {
      return SoilType.alluvial;
    }
    if (lower.contains('red') ||
        lower.contains('રાતી') ||
        lower.contains('लाल') ||
        lower.contains('ਲਾਲ')) {
      return SoilType.red;
    }
    if (lower.contains('sandy') ||
        lower.contains('રેતાળ') ||
        lower.contains('बलुई') ||
        lower.contains('ਰੇਤਲੀ')) {
      return SoilType.sandy;
    }
    if (lower.contains('clay') ||
        lower.contains('ચીકણી') ||
        lower.contains('चिकनी') ||
        lower.contains('ਚਿਕਣੀ')) {
      return SoilType.clay;
    }
    if (lower.contains('laterite') ||
        lower.contains('પડખાઉ') ||
        lower.contains('लैटेराइट')) {
      return SoilType.laterite;
    }
    if (lower.contains('mountain') ||
        lower.contains('પર્વતીય') ||
        lower.contains('पर्वतीय')) {
      return SoilType.mountain;
    }
    if (lower.contains('saline') ||
        lower.contains('alkaline') ||
        lower.contains('ક્ષારીય') ||
        lower.contains('लवणीय')) {
      return SoilType.salineAlkaline;
    }
    return SoilType.loamy;
  }
}

/// Precision Farm Soil Profile tracking chemical fertility, physical attributes,
/// and verification status (estimated vs lab-verified).
class SoilProfile {
  final SoilType soilType;
  final double pH; // Ideal range: 6.5 - 7.5
  final double nitrogenKgPerHa; // Low: <280, Med: 280-560, High: >560
  final double phosphorusKgPerHa; // Low: <10, Med: 10-25, High: >25
  final double potassiumKgPerHa; // Low: <110, Med: 110-280, High: >280
  final double organicCarbonPercent; // Low: <0.5%, Med: 0.5-0.75%, High: >0.75%
  final String soilMoisture; // Low, Medium, High
  final String drainageCapacity; // Well-drained, Moderate, Poor / Waterlogged
  final bool isLabVerified;
  final String labReportNumber;
  final DateTime? testedDate;
  final String dataSource;

  const SoilProfile({
    this.soilType = SoilType.loamy,
    this.pH = 7.0,
    this.nitrogenKgPerHa = 320.0,
    this.phosphorusKgPerHa = 18.0,
    this.potassiumKgPerHa = 220.0,
    this.organicCarbonPercent = 0.62,
    this.soilMoisture = 'Medium',
    this.drainageCapacity = 'Well-drained',
    this.isLabVerified = false,
    this.labReportNumber = '',
    this.testedDate,
    this.dataSource = 'ICAR District Agro-climatic Benchmark (Estimated)',
  });

  /// Default regional benchmark generator when lab test is not yet uploaded
  factory SoilProfile.estimatedForRegion({
    required String state,
    required String district,
    SoilType? preferredType,
  }) {
    SoilType inferred = preferredType ?? SoilType.loamy;
    final st = state.toLowerCase();
    final dt = district.toLowerCase();

    if (dt.contains('amreli') ||
        dt.contains('rajkot') ||
        dt.contains('junagadh') ||
        st.contains('maharashtra') ||
        st.contains('madhya pradesh') ||
        dt.contains('vidarbha')) {
      inferred = preferredType ?? SoilType.blackRegur;
    } else if (st.contains('punjab') ||
        st.contains('haryana') ||
        st.contains('uttar pradesh') ||
        st.contains('bihar')) {
      inferred = preferredType ?? SoilType.alluvial;
    } else if (st.contains('rajasthan') ||
        dt.contains('kutch') ||
        dt.contains('banaskantha')) {
      inferred = preferredType ?? SoilType.sandy;
    }

    double pH = 7.2;
    double n = 290.0;
    double p = 16.0;
    double k = 240.0;
    double oc = 0.58;

    if (inferred == SoilType.blackRegur) {
      pH = 7.8;
      n = 260.0;
      p = 15.0;
      k = 320.0;
      oc = 0.65;
    } else if (inferred == SoilType.alluvial) {
      pH = 7.1;
      n = 340.0;
      p = 22.0;
      k = 260.0;
      oc = 0.70;
    } else if (inferred == SoilType.sandy) {
      pH = 8.1;
      n = 190.0;
      p = 12.0;
      k = 180.0;
      oc = 0.35;
    }

    return SoilProfile(
      soilType: inferred,
      pH: pH,
      nitrogenKgPerHa: n,
      phosphorusKgPerHa: p,
      potassiumKgPerHa: k,
      organicCarbonPercent: oc,
      soilMoisture: inferred == SoilType.blackRegur ? 'High' : 'Medium',
      drainageCapacity: inferred == SoilType.clay ? 'Moderate' : 'Well-drained',
      isLabVerified: false,
      labReportNumber: '',
      testedDate: null,
      dataSource: 'ICAR & KVK $district Agro-climatic Estimated Benchmark',
    );
  }

  /// Categorical fertility indicators
  String get nitrogenLevel {
    if (nitrogenKgPerHa < 280) return 'Low (<280 kg/ha)';
    if (nitrogenKgPerHa <= 560) return 'Medium (280-560 kg/ha)';
    return 'High (>560 kg/ha)';
  }

  String get phosphorusLevel {
    if (phosphorusKgPerHa < 10) return 'Low (<10 kg/ha)';
    if (phosphorusKgPerHa <= 25) return 'Medium (10-25 kg/ha)';
    return 'High (>25 kg/ha)';
  }

  String get potassiumLevel {
    if (potassiumKgPerHa < 110) return 'Low (<110 kg/ha)';
    if (potassiumKgPerHa <= 280) return 'Medium (110-280 kg/ha)';
    return 'High (>280 kg/ha)';
  }

  String get organicCarbonLevel {
    if (organicCarbonPercent < 0.50) return 'Low (<0.50%)';
    if (organicCarbonPercent <= 0.75) return 'Medium (0.50-0.75%)';
    return 'High (>0.75%)';
  }

  /// Overall Soil Health Score (0 - 100)
  int get soilHealthScore {
    int score = 50;
    // pH check (6.5 to 7.8 is ideal for Indian crops)
    if (pH >= 6.5 && pH <= 7.8) {
      score += 15;
    } else if (pH >= 6.0 && pH <= 8.5) {
      score += 8;
    }

    // NPK balance
    if (nitrogenKgPerHa >= 250) score += 10;
    if (phosphorusKgPerHa >= 14) score += 10;
    if (potassiumKgPerHa >= 150) score += 10;

    // Organic carbon
    if (organicCarbonPercent >= 0.60) {
      score += 15;
    } else if (organicCarbonPercent >= 0.45) {
      score += 8;
    }

    return score.clamp(20, 95);
  }

  SoilProfile copyWith({
    SoilType? soilType,
    double? pH,
    double? nitrogenKgPerHa,
    double? phosphorusKgPerHa,
    double? potassiumKgPerHa,
    double? organicCarbonPercent,
    String? soilMoisture,
    String? drainageCapacity,
    bool? isLabVerified,
    String? labReportNumber,
    DateTime? testedDate,
    String? dataSource,
  }) {
    return SoilProfile(
      soilType: soilType ?? this.soilType,
      pH: pH ?? this.pH,
      nitrogenKgPerHa: nitrogenKgPerHa ?? this.nitrogenKgPerHa,
      phosphorusKgPerHa: phosphorusKgPerHa ?? this.phosphorusKgPerHa,
      potassiumKgPerHa: potassiumKgPerHa ?? this.potassiumKgPerHa,
      organicCarbonPercent: organicCarbonPercent ?? this.organicCarbonPercent,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      drainageCapacity: drainageCapacity ?? this.drainageCapacity,
      isLabVerified: isLabVerified ?? this.isLabVerified,
      labReportNumber: labReportNumber ?? this.labReportNumber,
      testedDate: testedDate ?? this.testedDate,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  Map<String, dynamic> toJson() => {
    'soilType': soilType.name,
    'pH': pH,
    'nitrogenKgPerHa': nitrogenKgPerHa,
    'phosphorusKgPerHa': phosphorusKgPerHa,
    'potassiumKgPerHa': potassiumKgPerHa,
    'organicCarbonPercent': organicCarbonPercent,
    'soilMoisture': soilMoisture,
    'drainageCapacity': drainageCapacity,
    'isLabVerified': isLabVerified,
    'labReportNumber': labReportNumber,
    'testedDate': testedDate?.toIso8601String(),
    'dataSource': dataSource,
  };

  factory SoilProfile.fromJson(Map<String, dynamic> json) {
    return SoilProfile(
      soilType: SoilType.values.firstWhere(
        (e) => e.name == json['soilType'],
        orElse: () => SoilTypeExtension.fromString(json['soilType'] as String?),
      ),
      pH: (json['pH'] as num?)?.toDouble() ?? 7.0,
      nitrogenKgPerHa: (json['nitrogenKgPerHa'] as num?)?.toDouble() ?? 300.0,
      phosphorusKgPerHa:
          (json['phosphorusKgPerHa'] as num?)?.toDouble() ?? 18.0,
      potassiumKgPerHa: (json['potassiumKgPerHa'] as num?)?.toDouble() ?? 220.0,
      organicCarbonPercent:
          (json['organicCarbonPercent'] as num?)?.toDouble() ?? 0.60,
      soilMoisture: json['soilMoisture'] as String? ?? 'Medium',
      drainageCapacity: json['drainageCapacity'] as String? ?? 'Well-drained',
      isLabVerified: json['isLabVerified'] as bool? ?? false,
      labReportNumber: json['labReportNumber'] as String? ?? '',
      testedDate: json['testedDate'] != null
          ? DateTime.tryParse(json['testedDate'] as String)
          : null,
      dataSource: json['dataSource'] as String? ?? 'Estimated',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SoilProfile.fromJsonString(String str) =>
      SoilProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
