import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farmer_notification.dart';

/// Service managing the Notification Center.
/// Stores, filters, updates read status, and manages unread count badge.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _storageKey = 'khetchacha_notifications_v1';
  final List<FarmerNotification> _notifications = [];
  bool _isInitialized = false;

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List list = jsonDecode(data) as List;
        _notifications.clear();
        for (var item in list) {
          _notifications.add(
            FarmerNotification.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }

    if (_notifications.isEmpty) {
      _notifications.addAll([
        FarmerNotification(
          id: 'notif-01',
          title: 'New Scheme: Gujarat Tractor Subsidy',
          message: 'iKhedut Tractor application window is now open for Anand district with up to ₹60,000 subsidy.',
          category: 'Government Schemes',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          isRead: false,
          deepLinkTarget: 'govt_schemes',
        ),
        FarmerNotification(
          id: 'notif-02',
          title: 'Expert Reply: Dr. Ramesh Patel (AAU)',
          message: 'Solution for Cotton Pink Bollworm query (KQ-2026-8941) has been answered with bio-control steps.',
          category: 'Expert Replies',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: false,
          deepLinkTarget: 'expert_queries',
        ),
        FarmerNotification(
          id: 'notif-03',
          title: 'Weather Warning: Rain Predicted',
          message: 'Light to moderate rainfall predicted today (84%). Avoid pesticide spraying and check field drainage.',
          category: 'Weather Alerts',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: false,
          deepLinkTarget: 'weather',
        ),
        FarmerNotification(
          id: 'notif-04',
          title: 'AI Crop Diagnosis Completed',
          message: 'Your scanned Cotton leaf showed 94.6% probability of Pink Bollworm. Review preventive treatment.',
          category: 'AI Diagnosis',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          deepLinkTarget: 'ai_diagnosis',
        ),
        FarmerNotification(
          id: 'notif-05',
          title: 'Marketplace Order Confirmed',
          message: 'Order #ORD-8921 for 20L Desi Gir Cow Jeevamrut has been placed successfully.',
          category: 'Marketplace Orders',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
          deepLinkTarget: 'marketplace',
        ),
        FarmerNotification(
          id: 'notif-06',
          title: 'Crop Advisory: Nutrient Split Dose',
          message: 'Time for 2nd split dose of Urea/Bio-fertilizer in tillering stage of Paddy crops in Anand.',
          category: 'Crop Advisory',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          isRead: true,
          deepLinkTarget: 'crop_advisory',
        ),
      ]);
    }

    _updateUnreadCount();
    _isInitialized = true;
  }

  void _updateUnreadCount() {
    final count = _notifications.where((n) => !n.isRead).length;
    unreadCountNotifier.value = count;
  }

  Future<List<FarmerNotification>> getNotifications({String? category}) async {
    await init();
    if (category == null || category == 'All') {
      return List.unmodifiable(_notifications);
    }
    return _notifications
        .where((n) => n.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await init();
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
      await _save();
    }
  }

  Future<void> markAllAsRead() async {
    await init();
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _updateUnreadCount();
    await _save();
  }

  Future<void> removeNotification(String id) async {
    await init();
    _notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();
    await _save();
  }

  Future<void> addNotification(FarmerNotification notification) async {
    await init();
    _notifications.insert(0, notification);
    _updateUnreadCount();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('[NotificationService] Save error: $e');
    }
  }
}
