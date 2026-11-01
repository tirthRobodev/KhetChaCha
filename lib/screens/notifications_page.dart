import 'package:flutter/material.dart';
import '../models/farmer_notification.dart';
import '../models/farmer_profile.dart';
import '../services/notification_service.dart';
import 'ai/image_ai_diagnosis_page.dart';
import 'expert/ask_expert_page.dart';
import 'marketplace/natural_farming_marketplace_page.dart';
import 'quick_access/crop_advisory_page.dart';
import 'quick_access/detailed_weather_page.dart';
import 'schemes/govt_schemes_directory_page.dart';

/// Dedicated Notification Center Screen.
/// Supports categories: Government Schemes, Expert Replies, AI Diagnosis,
/// Weather Alerts, Crop Advisory, and Marketplace Orders.
/// Includes read/unread status, timestamps, deep links, and dismiss actions.
class NotificationsPage extends StatefulWidget {
  final FarmerProfile profile;

  const NotificationsPage({super.key, required this.profile});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'All';
  List<FarmerNotification> _notifications = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Government Schemes',
    'Expert Replies',
    'AI Diagnosis',
    'Weather Alerts',
    'Crop Advisory',
    'Marketplace Orders',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await NotificationService.instance.getNotifications(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (!mounted) return;
    setState(() {
      _notifications = items;
      _isLoading = false;
    });
  }

  void _handleDeepLink(FarmerNotification notif) async {
    await NotificationService.instance.markAsRead(notif.id);
    _loadNotifications();

    if (!mounted) return;

    switch (notif.deepLinkTarget) {
      case 'govt_schemes':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GovtSchemesDirectoryPage(profile: widget.profile)),
        );
        break;
      case 'expert_queries':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AskExpertPage(profile: widget.profile)),
        );
        break;
      case 'ai_diagnosis':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ImageAiDiagnosisPage(profile: widget.profile)),
        );
        break;
      case 'marketplace':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NaturalFarmingMarketplacePage(profile: widget.profile)),
        );
        break;
      case 'crop_advisory':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CropAdvisoryPage(profile: widget.profile)),
        );
        break;
      case 'weather':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailedWeatherPage(profile: widget.profile)),
        );
        break;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Government Schemes':
        return const Color(0xFF00897B);
      case 'Expert Replies':
        return const Color(0xFF1B5E20);
      case 'Weather Alerts':
        return const Color(0xFF0288D1);
      case 'AI Diagnosis':
        return const Color(0xFF7B1FA2);
      case 'Marketplace Orders':
        return const Color(0xFFF57C00);
      case 'Crop Advisory':
      default:
        return const Color(0xFF43A047);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Government Schemes':
        return Icons.account_balance_rounded;
      case 'Expert Replies':
        return Icons.support_agent_rounded;
      case 'Weather Alerts':
        return Icons.water_drop_rounded;
      case 'AI Diagnosis':
        return Icons.document_scanner_rounded;
      case 'Marketplace Orders':
        return Icons.shopping_bag_rounded;
      case 'Crop Advisory':
      default:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await NotificationService.instance.markAllAsRead();
              _loadNotifications();
            },
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
            label: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter horizontal chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF424242),
                        ),
                      ),
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: const Color(0xFFF1F5F2),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                        _loadNotifications();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications in this category',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          final color = _getCategoryColor(n.category);

                          return Dismissible(
                            key: Key(n.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              NotificationService.instance.removeNotification(n.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notification removed'), duration: Duration(seconds: 1)),
                              );
                            },
                            child: Card(
                              elevation: n.isRead ? 0 : 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: n.isRead ? const Color(0xFFE0E0E0) : color.withValues(alpha: 0.5),
                                  width: n.isRead ? 1 : 1.5,
                                ),
                              ),
                              color: n.isRead ? Colors.white : color.withValues(alpha: 0.04),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getCategoryIcon(n.category), color: color, size: 22),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 13.5,
                                          color: const Color(0xFF212121),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(n.timestamp),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF616161), height: 1.3),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            n.category,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (n.deepLinkTarget != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'View Details',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                              ),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _handleDeepLink(n),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

