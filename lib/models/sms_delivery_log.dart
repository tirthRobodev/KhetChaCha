import 'dart:convert';

/// Status of an SMS delivery attempt
enum SmsDeliveryStatus {
  delivered,
  queued,
  optedOutBlocked,
  rateLimitExceeded,
  dltTemplateMismatch,
  failed,
}

/// DLT-Compliant SMS Delivery Audit Record
class SmsDeliveryLog {
  final String id;
  final String recipientMobile;
  final String senderId; // Approved 6-character TRAI DLT header, e.g. 'KHTCHA'
  final String dltTemplateId; // 19-digit registered DLT template ID
  final String messageContent;
  final SmsDeliveryStatus status;
  final DateTime timestamp;
  final String? providerMessageId;
  final String? failureReason;

  const SmsDeliveryLog({
    required this.id,
    required this.recipientMobile,
    this.senderId = 'KHTCHA',
    required this.dltTemplateId,
    required this.messageContent,
    required this.status,
    required this.timestamp,
    this.providerMessageId,
    this.failureReason,
  });

  bool get isDelivered => status == SmsDeliveryStatus.delivered;
  bool get isTraiCompliant => senderId == 'KHTCHA' && dltTemplateId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipientMobile': recipientMobile,
    'senderId': senderId,
    'dltTemplateId': dltTemplateId,
    'messageContent': messageContent,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'providerMessageId': providerMessageId,
    'failureReason': failureReason,
  };

  factory SmsDeliveryLog.fromJson(Map<String, dynamic> json) {
    return SmsDeliveryLog(
      id: json['id'] as String? ?? '',
      recipientMobile: json['recipientMobile'] as String? ?? '',
      senderId: json['senderId'] as String? ?? 'KHTCHA',
      dltTemplateId: json['dltTemplateId'] as String? ?? '',
      messageContent: json['messageContent'] as String? ?? '',
      status: SmsDeliveryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SmsDeliveryStatus.delivered,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      providerMessageId: json['providerMessageId'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SmsDeliveryLog.fromJsonString(String str) =>
      SmsDeliveryLog.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
