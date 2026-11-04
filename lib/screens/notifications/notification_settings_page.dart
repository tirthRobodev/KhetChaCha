import 'package:flutter/material.dart';

import '../../models/farmer_profile.dart';
import '../../models/notification_preferences.dart';
import '../../services/language_service.dart';
import '../../services/notification_preferences_service.dart';

/// Notification Settings Screen allowing farmers to configure alert channels,
/// quiet hours, and notification preferences.
class NotificationSettingsPage extends StatefulWidget {
  final FarmerProfile profile;

  const NotificationSettingsPage({super.key, required this.profile});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await NotificationPreferencesService.instance.getPreferences(
      widget.profile.mobileNumber,
    );
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    await NotificationPreferencesService.instance.savePreferences(
      widget.profile.mobileNumber,
      _preferences,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings updated successfully!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    Navigator.of(context).pop(_preferences);
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'સૂચના સેટિંગ્સ'
              : (langCode == 'hi' ? 'सूचना सेटिंग्स' : 'Notification Settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Delivery Channels (Push & SMS)
                  _buildSectionHeader(
                    'Delivery Channels',
                    Icons.cell_tower_rounded,
                  ),
                  _buildToggleTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive instant alerts on your phone screen',
                    value: _preferences.enablePushNotifications,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enablePushNotifications: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'DLT-Compliant SMS Alerts',
                    subtitle:
                        'Receive urgent scheme & weather SMS on ${widget.profile.mobileNumber}',
                    value: _preferences.enableSmsNotifications,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableSmsNotifications: val,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Alert Categories
                  _buildSectionHeader(
                    'Alert Categories',
                    Icons.category_rounded,
                  ),
                  _buildToggleTile(
                    title: 'Government News & Announcements',
                    subtitle:
                        'Central & State official agricultural press releases',
                    value: _preferences.enableGovernmentNews,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableGovernmentNews: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'Farmer Subsidies & Schemes',
                    subtitle: 'Tractor, drip irrigation, and solar pump subsidy windows',
                    value: _preferences.enableSubsidyAlerts,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableSubsidyAlerts: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'PM-KISAN Installment Updates',
                    subtitle:
                        'Direct ₹2,000 transfer dates and eKYC requirements',
                    value: _preferences.enablePmKisanUpdates,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enablePmKisanUpdates: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'Weather & Heavy Rain Warnings',
                    subtitle:
                        'IMD agricultural rainfall, storm, and frost alerts',
                    value: _preferences.enableWeatherAlerts,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableWeatherAlerts: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'Mandi Price & MSP Alerts',
                    subtitle: 'Local APMC selling rates and procurement dates',
                    value: _preferences.enableMandiPriceUpdates,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableMandiPriceUpdates: val,
                      ),
                    ),
                  ),
                  _buildToggleTile(
                    title: 'Crop Disease & Pest Advisories',
                    subtitle:
                        'KVK and ICAR pest outbreak prevention guidelines',
                    value: _preferences.enableCropAdvisories,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        enableCropAdvisories: val,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Quiet Hours
                  _buildSectionHeader('Quiet Hours', Icons.bedtime_rounded),
                  _buildToggleTile(
                    title: 'Enable Night Quiet Hours',
                    subtitle: 'Silence non-urgent notifications between 9:00 PM and 6:00 AM',
                    value: _preferences.quietHoursEnabled,
                    onChanged: (val) => setState(
                      () => _preferences = _preferences.copyWith(
                        quietHoursEnabled: val,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Notification Preferences',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: SwitchListTile.adaptive(
          value: value,
          activeTrackColor: const Color(0xFF2E7D32),
          onChanged: onChanged,
          title: Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
          ),
        ),
      ),
    );
  }
}
