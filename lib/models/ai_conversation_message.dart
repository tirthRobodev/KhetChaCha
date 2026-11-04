import 'dart:convert';

/// Represents a single conversation message exchanged with KhetChaCha AI,
/// shared between Voice Assistant and Text Chat modes.
class AiConversationMessage {
  final String id;
  final String sender; // 'user' or 'assistant'
  final String text;
  final String inputMode; // 'voice' or 'text'
  final String languageCode;
  final DateTime timestamp;
  final int? audioLengthSeconds;
  final Map<String, String>? structuredSections;

  const AiConversationMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.inputMode,
    required this.languageCode,
    required this.timestamp,
    this.audioLengthSeconds,
    this.structuredSections,
  });

  bool get isUser => sender == 'user';
  bool get isVoice => inputMode == 'voice';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'inputMode': inputMode,
      'languageCode': languageCode,
      'timestamp': timestamp.toIso8601String(),
      'audioLengthSeconds': audioLengthSeconds,
      'structuredSections': structuredSections,
    };
  }

  factory AiConversationMessage.fromMap(Map<String, dynamic> map) {
    return AiConversationMessage(
      id:
          map['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      sender: map['sender'] as String? ?? 'user',
      text: map['text'] as String? ?? '',
      inputMode: map['inputMode'] as String? ?? 'text',
      languageCode: map['languageCode'] as String? ?? 'en',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      audioLengthSeconds: map['audioLengthSeconds'] as int?,
      structuredSections: map['structuredSections'] != null
          ? Map<String, String>.from(map['structuredSections'] as Map)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AiConversationMessage.fromJson(String source) =>
      AiConversationMessage.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  AiConversationMessage copyWith({
    String? id,
    String? sender,
    String? text,
    String? inputMode,
    String? languageCode,
    DateTime? timestamp,
    int? audioLengthSeconds,
    Map<String, String>? structuredSections,
  }) {
    return AiConversationMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      inputMode: inputMode ?? this.inputMode,
      languageCode: languageCode ?? this.languageCode,
      timestamp: timestamp ?? this.timestamp,
      audioLengthSeconds: audioLengthSeconds ?? this.audioLengthSeconds,
      structuredSections: structuredSections ?? this.structuredSections,
    );
  }
}
