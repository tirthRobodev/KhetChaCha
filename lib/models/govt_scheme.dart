/// Model representing an official Government Agricultural or Horticultural Scheme.
/// Contains verified details including department, subsidy amount, eligibility,
/// required documents, deadlines, and official portal URLs.
class GovtScheme {
  final String id;
  final String name;
  final String department;
  final String category; // 'Central', 'State', 'Agriculture', 'Horticulture', 'Natural Farming', 'Equipment & Machinery', 'Irrigation & Water', 'Farmer Welfare'
  final String
  state; // e.g. 'All India', 'Gujarat', 'Punjab', 'Maharashtra', etc.
  final String district; // e.g. 'All', 'Anand', 'Ahmedabad', etc.
  final List<String> applicableCrops;
  final String description;
  final String benefitsSubsidy;
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final String startDate;
  final String deadline;
  final String officialWebsiteUrl;
  final String portalName;
  final String status; // 'Open', 'Upcoming', 'Closed'
  final bool registrationIdLookupSupported;

  const GovtScheme({
    required this.id,
    required this.name,
    required this.department,
    required this.category,
    required this.state,
    this.district = 'All',
    required this.applicableCrops,
    required this.description,
    required this.benefitsSubsidy,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    required this.startDate,
    required this.deadline,
    required this.officialWebsiteUrl,
    required this.portalName,
    required this.status,
    this.registrationIdLookupSupported = false,
  });

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isUpcoming => status.toLowerCase() == 'upcoming';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'category': category,
    'state': state,
    'district': district,
    'applicableCrops': applicableCrops,
    'description': description,
    'benefitsSubsidy': benefitsSubsidy,
    'eligibilityCriteria': eligibilityCriteria,
    'requiredDocuments': requiredDocuments,
    'startDate': startDate,
    'deadline': deadline,
    'officialWebsiteUrl': officialWebsiteUrl,
    'portalName': portalName,
    'status': status,
    'registrationIdLookupSupported': registrationIdLookupSupported,
  };

  factory GovtScheme.fromJson(Map<String, dynamic> json) => GovtScheme(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    department: json['department'] as String? ?? '',
    category: json['category'] as String? ?? 'Agriculture',
    state: json['state'] as String? ?? 'All India',
    district: json['district'] as String? ?? 'All',
    applicableCrops: List<String>.from(json['applicableCrops'] as List? ?? []),
    description: json['description'] as String? ?? '',
    benefitsSubsidy: json['benefitsSubsidy'] as String? ?? '',
    eligibilityCriteria: List<String>.from(
      json['eligibilityCriteria'] as List? ?? [],
    ),
    requiredDocuments: List<String>.from(
      json['requiredDocuments'] as List? ?? [],
    ),
    startDate: json['startDate'] as String? ?? '',
    deadline: json['deadline'] as String? ?? '',
    officialWebsiteUrl: json['officialWebsiteUrl'] as String? ?? '',
    portalName: json['portalName'] as String? ?? '',
    status: json['status'] as String? ?? 'Open',
    registrationIdLookupSupported:
        json['registrationIdLookupSupported'] as bool? ?? false,
  );
}
