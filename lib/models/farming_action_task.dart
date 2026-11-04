/// Model representing a personalized agricultural action task for a farmer.
/// Designed for the weekly farming schedule ("આ અઠવાડિયે તમારા ખેતરમાં શું કરવું?").
class FarmingActionTask {
  final String id;
  final String dayName;
  final int dayIndex; // 1 = Monday, 7 = Sunday
  final String title;
  final String description;
  final String whyReason;
  final String timing;
  final String estimatedCost;
  final bool isCompleted;

  const FarmingActionTask({
    required this.id,
    required this.dayName,
    required this.dayIndex,
    required this.title,
    required this.description,
    required this.whyReason,
    required this.timing,
    this.estimatedCost = '',
    this.isCompleted = false,
  });

  FarmingActionTask copyWith({
    String? id,
    String? dayName,
    int? dayIndex,
    String? title,
    String? description,
    String? whyReason,
    String? timing,
    String? estimatedCost,
    bool? isCompleted,
  }) {
    return FarmingActionTask(
      id: id ?? this.id,
      dayName: dayName ?? this.dayName,
      dayIndex: dayIndex ?? this.dayIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      whyReason: whyReason ?? this.whyReason,
      timing: timing ?? this.timing,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayName': dayName,
    'dayIndex': dayIndex,
    'title': title,
    'description': description,
    'whyReason': whyReason,
    'timing': timing,
    'estimatedCost': estimatedCost,
    'isCompleted': isCompleted,
  };

  factory FarmingActionTask.fromJson(Map<String, dynamic> json) =>
      FarmingActionTask(
        id: json['id'] as String? ?? '',
        dayName: json['dayName'] as String? ?? '',
        dayIndex: json['dayIndex'] as int? ?? 1,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        whyReason: json['whyReason'] as String? ?? '',
        timing: json['timing'] as String? ?? '',
        estimatedCost: json['estimatedCost'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
