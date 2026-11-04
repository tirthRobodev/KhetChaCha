import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_conversation_message.dart';

/// Single persistent source of truth for all AI conversation history,
/// shared seamlessly across Voice Assistant and Text Chat.
class ConversationHistoryService extends ChangeNotifier {
  static const String _prefKey = 'khetchacha_shared_ai_chat_history';
  static final ConversationHistoryService instance =
      ConversationHistoryService._internal();

  ConversationHistoryService._internal();

  final List<AiConversationMessage> _messages = [];
  bool _isLoaded = false;

  List<AiConversationMessage> get messages => List.unmodifiable(_messages);
  bool get isLoaded => _isLoaded;

  /// Loads stored messages from local disk
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_prefKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = json.decode(rawJson) as List<dynamic>;
        _messages.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _messages.add(AiConversationMessage.fromMap(item));
          }
        }
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ConversationHistoryService] Init error: $e');
      _isLoaded = true;
    }
  }

  /// Appends a new message and persists it
  Future<void> addMessage(AiConversationMessage message) async {
    _messages.add(message);
    notifyListeners();
    await _saveToDisk();
  }

  /// Deletes a specific message
  Future<void> deleteMessage(String id) async {
    _messages.removeWhere((msg) => msg.id == id);
    notifyListeners();
    await _saveToDisk();
  }

  /// Clears all stored messages
  Future<void> clearHistory() async {
    _messages.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (e) {
      debugPrint('[ConversationHistoryService] Clear error: $e');
    }
  }

  /// Returns recent voice queries for the voice assistant suggestions
  List<AiConversationMessage> getRecentVoiceQueries({int limit = 10}) {
    return _messages
        .where((m) => m.isUser && m.isVoice)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep at most 200 messages to maintain rapid performance
      final toSave = _messages.length > 200
          ? _messages.sublist(_messages.length - 200)
          : _messages;
      final raw = json.encode(toSave.map((m) => m.toMap()).toList());
      await prefs.setString(_prefKey, raw);
    } catch (e) {
      debugPrint('[ConversationHistoryService] Save error: $e');
    }
  }
}
