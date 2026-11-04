import 'package:flutter/material.dart';

/// Model representing an official Government Agricultural or Horticultural Scheme.
/// Contains verified details including department, subsidy amount, eligibility,
/// required documents, deadlines, and official portal URLs.
class GovtScheme {
  final String id;
  final String name;
  final String department;
  final String category; // 'Agriculture', 'Irrigation', 'Horticulture', 'Animal Husbandry', 'Dairy', 'Fisheries', 'Farm Machinery', 'Crop Insurance', 'Solar Energy', 'Seeds and Fertilizers', 'Farmer Welfare'
  final String governmentType; // 'Central' or 'State'
  final String
  state; // e.g. 'All India', 'Gujarat', 'Punjab', 'Maharashtra', etc.
  final List<String> applicableStates;
  final String district; // e.g. 'All', 'Anand', 'Ahmedabad', etc.
  final String benefitType; // 'Subsidy', 'Loan', 'Insurance', 'Direct Benefit Transfer', 'Equipment Assistance', 'Training', 'Financial Assistance'
  final List<String> applicableCrops;
  final String description;
  final String benefitsSubsidy;
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final String howToApply;
  final String startDate;
  final String deadline;
  final String officialWebsiteUrl;
  final String applyUrl;
  final String portalName;
  final String officialSource;
  final String
  status; // 'Open', 'Upcoming', 'Closed', 'Ongoing', 'Status Unknown'
  final String lastVerifiedDate;
  final String updatedAt;
  final bool isVerified;
  final bool registrationIdLookupSupported;
  final double? maxLandAcres;
  final List<String> eligibleFarmerCategories; // ['Small & Marginal', 'General', 'SC/ST', 'Women', 'All']
  final String? grNumber;
  final String? grDate;
  final String? officialPdfUrl;
  final String? statusUrl;
  final String? helpline;
  final String? nameGujarati;
  final String? nameHindi;
  final List<String> beneficiaryCategories;

  const GovtScheme({
    required this.id,
    required this.name,
    required this.department,
    required this.category,
    this.governmentType = 'Central',
    required this.state,
    this.applicableStates = const ['All India'],
    this.district = 'All',
    this.benefitType = 'Subsidy',
    required this.applicableCrops,
    required this.description,
    required this.benefitsSubsidy,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    this.howToApply = 'Apply online through the verified official state or central portal with required land records.',
    required this.startDate,
    required this.deadline,
    required this.officialWebsiteUrl,
    String? applyUrl,
    required this.portalName,
    String? officialSource,
    required this.status,
    this.lastVerifiedDate = 'April 2026',
    this.updatedAt = '2026-04-25T00:00:00Z',
    this.isVerified = true,
    this.registrationIdLookupSupported = false,
    this.maxLandAcres,
    this.eligibleFarmerCategories = const ['All'],
    this.grNumber,
    this.grDate,
    this.officialPdfUrl,
    this.statusUrl,
    this.helpline,
    this.nameGujarati,
    this.nameHindi,
    this.beneficiaryCategories = const [],
  }) : applyUrl = applyUrl ?? officialWebsiteUrl,
       officialSource = officialSource ?? department;

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isClosed => status.toLowerCase() == 'closed';
  bool get isOngoing => status.toLowerCase() == 'ongoing';
  bool get isStatusUnknown =>
      status.toLowerCase() == 'status unknown' ||
      status.toLowerCase() == 'unknown';

  /// Status badge background color
  Color get statusBadgeBgColor {
    if (isOpen) return const Color(0xFFE8F5E9); // Green tint
    if (isUpcoming) return const Color(0xFFFFF3E0); // Orange tint
    if (isOngoing) return const Color(0xFFE1F5FE); // Blue tint
    return const Color(0xFFEEEEEE); // Neutral gray for Closed / Status Unknown
  }

  /// Status badge text color
  Color get statusBadgeTextColor {
    if (isOpen) return const Color(0xFF2E7D32); // Green
    if (isUpcoming) return const Color(0xFFE65100); // Orange
    if (isOngoing) return const Color(0xFF0288D1); // Blue
    return const Color(0xFF757575); // Neutral dark gray
  }

  /// Display text for Government level
  String get governmentLabel =>
      governmentType.toLowerCase() == 'central' ||
          state.toLowerCase() == 'all india'
      ? 'Central Scheme'
      : '$state Government';

  /// Scheme category icon
  IconData get categoryIcon {
    final cat = category.toLowerCase();
    if (cat.contains('irrigation') || cat.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (cat.contains('solar')) {
      return Icons.solar_power_rounded;
    }
    if (cat.contains('machinery') || cat.contains('equipment')) {
      return Icons.agriculture_rounded;
    }
    if (cat.contains('insurance')) {
      return Icons.shield_rounded;
    }
    if (cat.contains('horticulture')) {
      return Icons.yard_rounded;
    }
    if (cat.contains('dairy')) {
      return Icons.egg_rounded;
    }
    if (cat.contains('animal') || cat.contains('livestock')) {
      return Icons.pets_rounded;
    }
    if (cat.contains('fisheries') || cat.contains('fish')) {
      return Icons.phishing_rounded;
    }
    if (cat.contains('seed') || cat.contains('fertilizer')) {
      return Icons.grass_rounded;
    }
    if (cat.contains('welfare')) {
      return Icons.account_balance_rounded;
    }
    return Icons.eco_rounded;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'category': category,
    'governmentType': governmentType,
    'state': state,
    'applicableStates': applicableStates,
    'district': district,
    'benefitType': benefitType,
    'applicableCrops': applicableCrops,
    'description': description,
    'benefitsSubsidy': benefitsSubsidy,
    'eligibilityCriteria': eligibilityCriteria,
    'requiredDocuments': requiredDocuments,
    'howToApply': howToApply,
    'startDate': startDate,
    'deadline': deadline,
    'officialWebsiteUrl': officialWebsiteUrl,
    'applyUrl': applyUrl,
    'portalName': portalName,
    'officialSource': officialSource,
    'status': status,
    'lastVerifiedDate': lastVerifiedDate,
    'updatedAt': updatedAt,
    'isVerified': isVerified,
    'registrationIdLookupSupported': registrationIdLookupSupported,
    'maxLandAcres': maxLandAcres,
    'eligibleFarmerCategories': eligibleFarmerCategories,
    'grNumber': grNumber,
    'grDate': grDate,
    'officialPdfUrl': officialPdfUrl,
    'statusUrl': statusUrl,
    'helpline': helpline,
    'nameGujarati': nameGujarati,
    'nameHindi': nameHindi,
    'beneficiaryCategories': beneficiaryCategories,
  };

  factory GovtScheme.fromJson(Map<String, dynamic> json) {
    final stateStr = json['state'] as String? ?? 'All India';
    final govType =
        json['governmentType'] as String? ??
        (stateStr.toLowerCase() == 'all india' ? 'Central' : 'State');
    final officialUrl = json['officialWebsiteUrl'] as String? ?? '';
    final dept = json['department'] as String? ?? '';

    return GovtScheme(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: dept,
      category: json['category'] as String? ?? 'Agriculture',
      governmentType: govType,
      state: stateStr,
      applicableStates: List<String>.from(
        json['applicableStates'] as List? ?? [stateStr],
      ),
      district: json['district'] as String? ?? 'All',
      benefitType: json['benefitType'] as String? ?? 'Subsidy',
      applicableCrops: List<String>.from(
        json['applicableCrops'] as List? ?? [],
      ),
      description: json['description'] as String? ?? '',
      benefitsSubsidy: json['benefitsSubsidy'] as String? ?? '',
      eligibilityCriteria: List<String>.from(
        json['eligibilityCriteria'] as List? ?? [],
      ),
      requiredDocuments: List<String>.from(
        json['requiredDocuments'] as List? ?? [],
      ),
      howToApply: json['howToApply'] as String? ?? 'Apply online through the verified official state or central portal with required land records.',
      startDate: json['startDate'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      officialWebsiteUrl: officialUrl,
      applyUrl: json['applyUrl'] as String? ?? officialUrl,
      portalName: json['portalName'] as String? ?? '',
      officialSource: json['officialSource'] as String? ?? dept,
      status: json['status'] as String? ?? 'Open',
      lastVerifiedDate: json['lastVerifiedDate'] as String? ?? 'April 2026',
      updatedAt: json['updatedAt'] as String? ?? '2026-04-25T00:00:00Z',
      isVerified: json['isVerified'] as bool? ?? true,
      registrationIdLookupSupported:
          json['registrationIdLookupSupported'] as bool? ?? false,
      maxLandAcres: (json['maxLandAcres'] as num?)?.toDouble(),
      eligibleFarmerCategories: List<String>.from(
        json['eligibleFarmerCategories'] as List? ?? ['All'],
      ),
      grNumber: json['grNumber'] as String?,
      grDate: json['grDate'] as String?,
      officialPdfUrl: json['officialPdfUrl'] as String?,
      statusUrl: json['statusUrl'] as String?,
      helpline: json['helpline'] as String?,
      nameGujarati: json['nameGujarati'] as String?,
      nameHindi: json['nameHindi'] as String?,
      beneficiaryCategories: List<String>.from(
        json['beneficiaryCategories'] as List? ?? [],
      ),
    );
  }
}
