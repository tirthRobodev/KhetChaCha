import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';
import '../../services/language_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/khetchacha_logo.dart';
import '../../widgets/permission_card.dart';
import '../farmer_dashboard_page.dart';
import '../language_selection_page.dart';

/// Premium First-Launch Onboarding & Permission Management Screen for KhetChacha.
///
/// Features:
/// 1. Displays official KhetChacha logo and warm agricultural branding.
/// 2. Shows active farmer language with quick-switch option.
/// 3. Step-by-step & interactive overview of all 5 permissions:
///    - Location (Weather & Mandi)
///    - Camera (AI Crop Diagnosis)
///    - Gallery (Crop Photo Uploads)
///    - Microphone (Voice Search & AI Assistant)
///    - Notifications (Farming Alerts & Schemes)
/// 4. Live permission status indicators with progress tracking.
/// 5. Safe non-blocking navigation (Continue & Skip for now options).
/// 6. Saves first-launch completion in SharedPreferences.
class FirstLaunchOnboardingPage extends StatefulWidget {
  final FarmerProfile? profile;
  final bool autoRequestPermissions;

  const FirstLaunchOnboardingPage({
    super.key,
    this.profile,
    this.autoRequestPermissions = true,
  });

  @override
  State<FirstLaunchOnboardingPage> createState() =>
      _FirstLaunchOnboardingPageState();
}

class _FirstLaunchOnboardingPageState extends State<FirstLaunchOnboardingPage>
    with WidgetsBindingObserver {
  final Map<KhetPermissionType, KhetPermissionState> _states = {};
  bool _isLoading = true;
  bool _isRequestingAll = false;
  bool _hasTriggeredAutoRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllStatuses().then((_) {
      if (mounted && widget.autoRequestPermissions && !_hasTriggeredAutoRequest) {
        _hasTriggeredAutoRequest = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestAllSequentially();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If returning from Android Phone Settings, refresh permission states
    if (state == AppLifecycleState.resumed) {
      _loadAllStatuses();
    }
  }

  Future<void> _loadAllStatuses() async {
    final results = await PermissionService.instance.checkAll();
    if (mounted) {
      setState(() {
        _states.clear();
        _states.addAll(results);
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSingle(KhetPermissionType type) async {
    final newState = await PermissionService.instance.request(type);
    if (mounted) {
      setState(() {
        _states[type] = newState;
      });
    }
  }

  Future<void> _requestAllSequentially() async {
    if (_isRequestingAll) return;
    setState(() {
      _isRequestingAll = true;
    });

    const orderedTypes = [
      KhetPermissionType.location,
      KhetPermissionType.camera,
      KhetPermissionType.gallery,
      KhetPermissionType.microphone,
      KhetPermissionType.notification,
    ];

    for (final type in orderedTypes) {
      if (!mounted) break;
      // Skip if already granted
      if (_states[type] == KhetPermissionState.granted) continue;

      final newState = await PermissionService.instance.request(type);
      if (mounted) {
        setState(() {
          _states[type] = newState;
        });
      }
      // Brief transition delay so Android system dialog sequence feels natural
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) {
      setState(() {
        _isRequestingAll = false;
      });
    }
  }

  Future<void> _requestAll() async {
    await _requestAllSequentially();
  }

  Future<void> _onFinishOnboarding() async {
    // Save onboarding completion to prevent repeated displays
    await PermissionService.instance.setOnboardingCompleted(true);

    if (!mounted) return;

    if (widget.profile != null && widget.profile!.farmSetupCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FarmerDashboardPage(profile: widget.profile!),
        ),
      );
    } else {
      // Flow sequence: Step 1: Permissions -> Step 2: Language Selection -> Step 3: Login -> Step 4: Farmer Details -> Step 5: Crop Selection -> Step 6: Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              LanguageSelectionPage(initialProfile: widget.profile),
        ),
      );
    }
  }

  int get _grantedCount =>
      _states.values.where((s) => s == KhetPermissionState.granted).length;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLang = LanguageService.instance.currentLanguage;
    final granted = _grantedCount;
    const total = 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: KhetChachaLogo.appBar(height: 28),
        actions: [
          // Active Language Pill
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionPage(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentLang.nativeName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Premium Welcome Card with Agricultural Gradient
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20)
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Color(0xFFFFD54F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loc.welcomeTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.welcomeSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE8F5E9),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.permissionsIntroSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Permission Progress Status & Grant All Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  loc.permissionsGrantedCount(granted, total),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              if (granted < total)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 0,
                                    ),
                                  ),
                                  onPressed: _isRequestingAll
                                      ? null
                                      : _requestAll,
                                  icon: _isRequestingAll
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 15,
                                          color: Color(0xFF2E7D32),
                                        ),
                                  label: Text(
                                    loc.grantAllPermissions,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: granted / total,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE0E0E0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (granted == total) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    loc.permissionAllGrantedNotice,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Section Title
                    Text(
                      loc.permissionsIntroTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Five Interactive Permission Cards
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      )
                    else ...[
                      // 1. Location
                      PermissionCard(
                        type: KhetPermissionType.location,
                        state:
                            _states[KhetPermissionType.location] ??
                            KhetPermissionState.notRequested,
                        onRequest: () =>
                            _requestSingle(KhetPermissionType.location),
                        onOpenSettings: () =>
                            PermissionService.instance.openSettings(),
                      ),

                      // 2. Camera
                      PermissionCard(
                        type: KhetPermissionType.camera,
                        state:
                            _states[KhetPermissionType.camera] ??
                            KhetPermissionState.notRequested,
                        onRequest: () =>
                            _requestSingle(KhetPermissionType.camera),
                        onOpenSettings: () =>
                            PermissionService.instance.openSettings(),
                      ),

                      // 3. Gallery
                      PermissionCard(
                        type: KhetPermissionType.gallery,
                        state:
                            _states[KhetPermissionType.gallery] ??
                            KhetPermissionState.notRequested,
                        onRequest: () =>
                            _requestSingle(KhetPermissionType.gallery),
                        onOpenSettings: () =>
                            PermissionService.instance.openSettings(),
                      ),

                      // 4. Microphone
                      PermissionCard(
                        type: KhetPermissionType.microphone,
                        state:
                            _states[KhetPermissionType.microphone] ??
                            KhetPermissionState.notRequested,
                        onRequest: () =>
                            _requestSingle(KhetPermissionType.microphone),
                        onOpenSettings: () =>
                            PermissionService.instance.openSettings(),
                      ),

                      // 5. Notifications
                      PermissionCard(
                        type: KhetPermissionType.notification,
                        state:
                            _states[KhetPermissionType.notification] ??
                            KhetPermissionState.notRequested,
                        onRequest: () =>
                            _requestSingle(KhetPermissionType.notification),
                        onOpenSettings: () =>
                            PermissionService.instance.openSettings(),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 5. Privacy & Farmer Safety Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 16,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'KhetChacha respects your privacy. Permissions are strictly used for verified agricultural advisories and can be changed anytime in Phone Settings.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF33691E),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar: Continue to Dashboard & Skip for now
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _onFinishOnboarding,
                    child: Text(
                      loc.continueButtonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFF757575),
                      ),
                      onPressed: _onFinishOnboarding,
                      child: Text(
                        loc.skipForNow,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
