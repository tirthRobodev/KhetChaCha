/// Model representing a Notification in the Notification Center.
/// Covers all required categories: Government Schemes, Expert Replies,
/// AI Diagnosis, Weather Alerts, Crop Advisory, and Marketplace Orders.
class FarmerNotification {
  final String id;
  final String title;
  final String message;
  final String category; // 'Government Schemes', 'Expert Replies', 'AI Diagnosis', 'Weather Alerts', 'Crop Advisory', 'Marketplace Orders'
  final DateTime timestamp;
  final bool isRead;
  final String? deepLinkTarget; // Route identifier or entity ID

  const FarmerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.deepLinkTarget,
  });

  FarmerNotification copyWith({bool? isRead}) {
    return FarmerNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      deepLinkTarget: deepLinkTarget,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'deepLinkTarget': deepLinkTarget,
  };

  factory FarmerNotification.fromJson(Map<String, dynamic> json) =>
      FarmerNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        deepLinkTarget: json['deepLinkTarget'] as String?,
      );
}
