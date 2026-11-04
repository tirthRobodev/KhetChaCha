import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../../localization/govt_scheme_localization.dart';
import '../../models/farmer_profile.dart';
import '../../models/govt_scheme.dart';
import '../../services/govt_scheme_service.dart';
import '../../services/language_service.dart';
import 'scheme_details_page.dart';

/// Clean, compact, responsive Government Schemes module.
/// Designed for the "All India Schemes" visual design specification.
/// Features dark green AppBar, compact search bar, three rounded filter buttons (Category | Benefit | Crop),
/// All India / State selector, total schemes count, 3-way sorting, status badges, and small rounded cards.
class GovtSchemesDirectoryPage extends StatefulWidget {
  final FarmerProfile profile;

  const GovtSchemesDirectoryPage({super.key, required this.profile});

  @override
  State<GovtSchemesDirectoryPage> createState() =>
      _GovtSchemesDirectoryPageState();
}

class _GovtSchemesDirectoryPageState extends State<GovtSchemesDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();

  // Active filters
  String _selectedCategory = 'All Categories';
  String _selectedBenefit = 'All Benefits';
  String _selectedCrop = 'All Crops';
  String _selectedStatus = 'All';
  late String _selectedState;
  String _selectedSortBy = 'Latest Verified'; // 'Latest Verified', 'Application Deadline', 'Alphabetical'

  // Categories (12 options)
  final List<String> _categories = [
    'All Categories',
    'Agriculture',
    'Irrigation',
    'Horticulture',
    'Animal Husbandry',
    'Dairy',
    'Fisheries',
    'Farm Machinery',
    'Crop Insurance',
    'Solar Energy',
    'Seeds and Fertilizers',
    'Farmer Welfare',
  ];

  // Benefit Types (8 options)
  final List<String> _benefitTypes = [
    'All Benefits',
    'Subsidy',
    'Loan',
    'Insurance',
    'Direct Benefit Transfer',
    'Equipment Assistance',
    'Training',
    'Financial Assistance',
  ];

  // Crop Filters (10 options)
  final List<String> _cropFilters = [
    'All Crops',
    'Wheat',
    'Rice',
    'Cotton',
    'Groundnut',
    'Maize',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Other Crops',
  ];

  // States
  final List<String> _states = [
    'All India',
    'Gujarat',
    'Punjab',
    'Maharashtra',
    'Uttar Pradesh',
    'Rajasthan',
    'Madhya Pradesh',
    'Haryana',
  ];

  // Quick Status Pills
  final List<String> _statusPills = [
    'All',
    'Open',
    'Upcoming',
    'Ongoing',
    'Closed',
  ];

  // Sort Options
  final List<String> _sortOptions = [
    'Latest Verified',
    'Application Deadline',
    'Alphabetical',
  ];

  @override
  void initState() {
    super.initState();
    _selectedState =
        widget.profile.effectiveState.isNotEmpty &&
            _states.contains(widget.profile.effectiveState)
        ? widget.profile.effectiveState
        : 'All India';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'All Categories';
      _selectedBenefit = 'All Benefits';
      _selectedCrop = 'All Crops';
      _selectedStatus = 'All';
      _selectedState = 'All India';
      _selectedSortBy = 'Latest Verified';
      _searchController.clear();
    });
  }

  void _openSelectionSheet({
    required String title,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
    required String Function(String item, String langCode) labelResolver,
  }) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title bar with Reset
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        onSelected(items.first);
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        GovtSchemeLocalization.getResetFiltersLabel(langCode),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Options list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == selectedItem;
                    return InkWell(
                      onTap: () {
                        onSelected(item);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: isSelected
                            ? const Color(0xFFE8F5E9)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                labelResolver(item, langCode),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openLookupDialog() {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final idController = TextEditingController();
    bool isSearching = false;
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFF1B5E20),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GovtSchemeLocalization.getLookupTitle(langCode),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    GovtSchemeLocalization.getLookupHint(langCode),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 12-digit Aadhaar / Farmer ID',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF1B5E20),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FBF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  if (result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: result!['found'] == true
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: result!['found'] == true
                              ? const Color(0xFF81C784)
                              : const Color(0xFFE57373),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                result!['found'] == true
                                    ? Icons.verified_user_rounded
                                    : Icons.error_outline,
                                color: result!['found'] == true
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  result!['beneficiaryStatus'] ??
                                      result!['message'] ??
                                      'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: result!['found'] == true
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (result!['schemeName'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Scheme: ${result!['schemeName']}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                          if (result!['latestInstallment'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Disbursement: ${result!['latestInstallment']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(GovtSchemeLocalization.getCloseLabel(langCode)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (idController.text.trim().isEmpty) return;
                  setDialogState(() {
                    isSearching = true;
                    result = null;
                  });

                  final res = await GovtSchemeService.instance
                      .checkBeneficiaryStatus(
                        schemeId: 'pm-kisan-01',
                        registrationOrAadhaarNumber: idController.text,
                      );

                  setDialogState(() {
                    isSearching = false;
                    result = res;
                  });
                },
                child: Text(
                  GovtSchemeLocalization.getCheckStatusLabel(langCode),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    // Execute filtered & sorted scheme search
    final schemes = GovtSchemeService.instance.searchSchemes(
      searchQuery: _searchController.text,
      categoryFilter: _selectedCategory,
      benefitFilter: _selectedBenefit,
      cropFilter: _selectedCrop,
      stateFilter: _selectedState,
      statusFilter: _selectedStatus,
      sortBy: _selectedSortBy,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          GovtSchemeLocalization.getTitle(langCode),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
            tooltip: GovtSchemeLocalization.getLookupTitle(langCode),
            onPressed: _openLookupDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar (Compact, White Background)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: GovtSchemeLocalization.getSearchHint(langCode),
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF9E9E9E),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF7FAF8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Three Rounded Filter Buttons: Category | Benefit | Crop
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                // Button 1: Category
                Expanded(
                  child: _buildFilterPill(
                    label:
                        _selectedCategory == 'All Categories' ||
                            _selectedCategory == 'All'
                        ? GovtSchemeLocalization.getFilterCategoryLabel(
                            langCode,
                          )
                        : GovtSchemeLocalization.getCategoryLabel(
                            _selectedCategory,
                            langCode,
                          ),
                    isActive:
                        _selectedCategory != 'All Categories' &&
                        _selectedCategory != 'All',
                    onTap: () => _openSelectionSheet(
                      title: GovtSchemeLocalization.getFilterCategoryTitle(
                        langCode,
                      ),
                      items: _categories,
                      selectedItem: _selectedCategory,
                      onSelected: (val) =>
                          setState(() => _selectedCategory = val),
                      labelResolver: (item, lc) =>
                          GovtSchemeLocalization.getCategoryLabel(item, lc),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: Benefit
                Expanded(
                  child: _buildFilterPill(
                    label:
                        _selectedBenefit == 'All Benefits' ||
                            _selectedBenefit == 'All'
                        ? GovtSchemeLocalization.getFilterBenefitLabel(langCode)
                        : GovtSchemeLocalization.getBenefitTypeLabel(
                            _selectedBenefit,
                            langCode,
                          ),
                    isActive:
                        _selectedBenefit != 'All Benefits' &&
                        _selectedBenefit != 'All',
                    onTap: () => _openSelectionSheet(
                      title: GovtSchemeLocalization.getFilterBenefitTitle(
                        langCode,
                      ),
                      items: _benefitTypes,
                      selectedItem: _selectedBenefit,
                      onSelected: (val) =>
                          setState(() => _selectedBenefit = val),
                      labelResolver: (item, lc) =>
                          GovtSchemeLocalization.getBenefitTypeLabel(item, lc),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 3: Crop
                Expanded(
                  child: _buildFilterPill(
                    label:
                        _selectedCrop == 'All Crops' || _selectedCrop == 'All'
                        ? GovtSchemeLocalization.getFilterCropLabel(langCode)
                        : GovtSchemeLocalization.getCropFilterLabel(
                            _selectedCrop,
                            langCode,
                          ),
                    isActive:
                        _selectedCrop != 'All Crops' && _selectedCrop != 'All',
                    onTap: () => _openSelectionSheet(
                      title: GovtSchemeLocalization.getFilterCropTitle(
                        langCode,
                      ),
                      items: _cropFilters,
                      selectedItem: _selectedCrop,
                      onSelected: (val) => setState(() => _selectedCrop = val),
                      labelResolver: (item, lc) =>
                          GovtSchemeLocalization.getCropFilterLabel(item, lc),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Compact Info Row: Total Schemes Count, State Selector & 3-Way Sorting
          Container(
            color: const Color(0xFFFBFDFB),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Total Schemes Count
                Expanded(
                  child: Text(
                    GovtSchemeLocalization.getSchemesCountLabel(
                      schemes.length,
                      langCode,
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // State Selector Pill
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openSelectionSheet(
                    title: 'Select State / All India',
                    items: _states,
                    selectedItem: _selectedState,
                    onSelected: (val) => setState(() => _selectedState = val),
                    labelResolver: (item, lc) =>
                        GovtSchemeLocalization.getStateDropdownLabel(item, lc),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF1B5E20),
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 86),
                          child: Text(
                            GovtSchemeLocalization.getStateDropdownLabel(
                              _selectedState,
                              langCode,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 3-Way Sorting Pill
                PopupMenuButton<String>(
                  initialValue: _selectedSortBy,
                  onSelected: (val) => setState(() => _selectedSortBy = val),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => _sortOptions
                      .map(
                        (opt) => PopupMenuItem(
                          value: opt,
                          child: Text(
                            GovtSchemeLocalization.getSortByLabel(
                              opt,
                              langCode,
                            ),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: opt == _selectedSortBy
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: opt == _selectedSortBy
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sort_rounded,
                          size: 13,
                          color: Color(0xFF616161),
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 76),
                          child: Text(
                            GovtSchemeLocalization.getSortByLabel(
                              _selectedSortBy,
                              langCode,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: Color(0xFF757575),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Quick Status Pills (All, Open, Upcoming, Ongoing, Closed)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusPills.map((st) {
                  final isSelected = _selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedStatus = st),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          GovtSchemeLocalization.getStatusLabel(st, langCode),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF616161),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 5. Small Rounded Scheme Cards List
          Expanded(
            child: schemes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.policy_outlined,
                            size: 52,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            GovtSchemeLocalization.getNoSchemesLabel(langCode),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              GovtSchemeLocalization.getResetFiltersLabel(
                                langCode,
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            onPressed: _resetAllFilters,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    itemCount: schemes.length,
                    itemBuilder: (context, index) {
                      final scheme = schemes[index];
                      return _buildSchemeCard(scheme, langCode);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Compact rounded filter button (Category | Benefit | Crop)
  Widget _buildFilterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFD1D5DB),
            width: isActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  /// Small rounded scheme card matching second reference screen
  Widget _buildSchemeCard(GovtScheme scheme, String langCode) {
    final localizedTitle = GovtSchemeLocalization.getSchemeName(
      scheme.id,
      scheme.name,
      langCode,
    );
    final localizedCategory = GovtSchemeLocalization.getCategoryLabel(
      scheme.category,
      langCode,
    );
    final localizedStatus = GovtSchemeLocalization.getStatusLabel(
      scheme.status,
      langCode,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x08000000),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SchemeDetailsPage(scheme: scheme, profile: widget.profile),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scheme Category Icon in Rounded Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  scheme.categoryIcon,
                  color: const Color(0xFF1B5E20),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),

              // Scheme Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Category Label Pill & Central/State Tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            localizedCategory,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            scheme.governmentLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Scheme Name in bold readable text
                    Text(
                      localizedTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Bottom Row: Status Badge & Application Deadline
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Status Badge (Open: green, Upcoming: orange, Closed: gray, Ongoing: blue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.statusBadgeBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            localizedStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: scheme.statusBadgeTextColor,
                            ),
                          ),
                        ),

                        // Application Deadline with Small Calendar Icon
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: (MediaQuery.of(context).size.width - 130)
                                .clamp(60.0, 400.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_outlined,
                                size: 12,
                                color: Color(0xFF757575),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  scheme.deadline,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF616161),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Arrow Chevron Indicator
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openExternalLink(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    try {
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[GovtSchemes] Could not launch $cleanUrl: $e');
    }
  }

  Future<void> callHelpline(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final rawPhone = phone.trim();
    final telUri = Uri.parse('tel:$rawPhone');
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toll-Free Helpline: $rawPhone'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toll-Free Helpline: $rawPhone'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    }
  }
}
