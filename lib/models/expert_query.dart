/// Model representing a Farmer's Query submitted to an Agriculture Expert.
/// Complies with the 3-level taxonomy required by PS000046 (Kisan Solution, Anand):
/// Level 1: Crop
/// Level 2: Problem Category
/// Level 3: Specific Problem
class ExpertQuery {
  final String id; // Unique Query ID e.g. "KQ-2026-8941"
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String state;
  final String district;
  final String village;

  // 3-Level Problem Taxonomy
  final String crop; // Level 1
  final String problemCategory; // Level 2
  final String specificProblem; // Level 3

  final String description;
  final List<String> mediaPaths; // Local or cloud URLs
  final List<String> mediaTypes; // 'image', 'audio', 'video'

  // Query Lifecycle: Submitted -> Assigned -> Under Review -> Answered -> Closed
  final String status;
  final DateTime submittedAt;
  final DateTime? updatedAt;

  // Expert Assignment & Response
  final String? assignedExpertId;
  final String? assignedExpertName;
  final String? expertDesignation; // e.g. "Senior Agronomist, Anand Agricultural University"
  final String? expertResponseText;
  final String? expertResponseAudioUrl;
  final List<String>? expertResponseAttachments;
  final DateTime? answeredAt;

  const ExpertQuery({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.state,
    required this.district,
    required this.village,
    required this.crop,
    required this.problemCategory,
    required this.specificProblem,
    required this.description,
    required this.mediaPaths,
    required this.mediaTypes,
    required this.status,
    required this.submittedAt,
    this.updatedAt,
    this.assignedExpertId,
    this.assignedExpertName,
    this.expertDesignation,
    this.expertResponseText,
    this.expertResponseAudioUrl,
    this.expertResponseAttachments,
    this.answeredAt,
  });

  bool get isAnswered => status.toLowerCase() == 'answered' || status.toLowerCase() == 'closed';

  ExpertQuery copyWith({
    String? status,
    String? assignedExpertId,
    String? assignedExpertName,
    String? expertDesignation,
    String? expertResponseText,
    String? expertResponseAudioUrl,
    List<String>? expertResponseAttachments,
    DateTime? answeredAt,
  }) {
    return ExpertQuery(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      state: state,
      district: district,
      village: village,
      crop: crop,
      problemCategory: problemCategory,
      specificProblem: specificProblem,
      description: description,
      mediaPaths: mediaPaths,
      mediaTypes: mediaTypes,
      status: status ?? this.status,
      submittedAt: submittedAt,
      updatedAt: DateTime.now(),
      assignedExpertId: assignedExpertId ?? this.assignedExpertId,
      assignedExpertName: assignedExpertName ?? this.assignedExpertName,
      expertDesignation: expertDesignation ?? this.expertDesignation,
      expertResponseText: expertResponseText ?? this.expertResponseText,
      expertResponseAudioUrl: expertResponseAudioUrl ?? this.expertResponseAudioUrl,
      expertResponseAttachments: expertResponseAttachments ?? this.expertResponseAttachments,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'state': state,
        'district': district,
        'village': village,
        'crop': crop,
        'problemCategory': problemCategory,
        'specificProblem': specificProblem,
        'description': description,
        'mediaPaths': mediaPaths,
        'mediaTypes': mediaTypes,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'assignedExpertId': assignedExpertId,
        'assignedExpertName': assignedExpertName,
        'expertDesignation': expertDesignation,
        'expertResponseText': expertResponseText,
        'expertResponseAudioUrl': expertResponseAudioUrl,
        'expertResponseAttachments': expertResponseAttachments,
        'answeredAt': answeredAt?.toIso8601String(),
      };

  factory ExpertQuery.fromJson(Map<String, dynamic> json) => ExpertQuery(
        id: json['id'] as String,
        farmerId: json['farmerId'] as String? ?? '',
        farmerName: json['farmerName'] as String? ?? 'Farmer',
        farmerPhone: json['farmerPhone'] as String? ?? '',
        state: json['state'] as String? ?? 'Gujarat',
        district: json['district'] as String? ?? 'Anand',
        village: json['village'] as String? ?? '',
        crop: json['crop'] as String? ?? 'Cotton',
        problemCategory: json['problemCategory'] as String? ?? 'Pest Infestation',
        specificProblem: json['specificProblem'] as String? ?? 'General Query',
        description: json['description'] as String? ?? '',
        mediaPaths: List<String>.from(json['mediaPaths'] as List? ?? []),
        mediaTypes: List<String>.from(json['mediaTypes'] as List? ?? []),
        status: json['status'] as String? ?? 'Submitted',
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        assignedExpertId: json['assignedExpertId'] as String?,
        assignedExpertName: json['assignedExpertName'] as String?,
        expertDesignation: json['expertDesignation'] as String?,
        expertResponseText: json['expertResponseText'] as String?,
        expertResponseAudioUrl: json['expertResponseAudioUrl'] as String?,
        expertResponseAttachments: json['expertResponseAttachments'] != null
            ? List<String>.from(json['expertResponseAttachments'] as List)
            : null,
        answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt'] as String) : null,
      );
}

