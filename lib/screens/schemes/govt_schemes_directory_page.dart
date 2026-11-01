import 'package:flutter/material.dart';
import '../../models/farmer_profile.dart';
import '../../models/govt_scheme.dart';
import '../../services/govt_scheme_service.dart';

/// Full-Featured Government Schemes & Subsidies Directory.
/// Supports state/district/crop/category filtering, status badges,
/// verified scheme detail sheets, and Farmer Registration ID lookup.
class GovtSchemesDirectoryPage extends StatefulWidget {
  final FarmerProfile profile;

  const GovtSchemesDirectoryPage({super.key, required this.profile});

  @override
  State<GovtSchemesDirectoryPage> createState() => _GovtSchemesDirectoryPageState();
}

class _GovtSchemesDirectoryPageState extends State<GovtSchemesDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  late String _selectedState;

  final List<String> _categories = [
    'All',
    'Farmer Welfare',
    'Equipment & Machinery',
    'Natural Farming',
    'Irrigation & Water',
    'Agriculture',
    'Horticulture',
  ];

  final List<String> _statuses = ['All', 'Open', 'Upcoming'];

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

  @override
  void initState() {
    super.initState();
    _selectedState = widget.profile.effectiveState.isNotEmpty && _states.contains(widget.profile.effectiveState)
        ? widget.profile.effectiveState
        : 'All India';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLookupDialog(GovtScheme scheme) {
    final idController = TextEditingController();
    bool isSearching = false;
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.badge_rounded, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Application Status Lookup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    scheme.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lookup via ${scheme.portalName}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      hintText: 'Enter 12-digit Aadhaar / Farmer ID',
                      prefixIcon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF1B5E20)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                      ),
                    ),
                  if (result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: result!['found'] == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: result!['found'] == true ? const Color(0xFF81C784) : const Color(0xFFE57373),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                result!['found'] == true ? Icons.verified_user_rounded : Icons.error_outline,
                                color: result!['found'] == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                result!['beneficiaryStatus'] ?? 'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: result!['found'] == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          if (result!['latestInstallment'] != null)
                            Text(
                              'Disbursement: ${result!['latestInstallment']}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF333333)),
                            ),
                          const SizedBox(height: 4),
                          if (result!['eKycStatus'] != null)
                            Text(
                              'e-KYC: ${result!['eKycStatus']}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF333333)),
                            ),
                          const SizedBox(height: 4),
                          if (result!['remarks'] != null)
                            Text(
                              'Note: ${result!['remarks']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
                            ),
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
                child: const Text('Close'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (idController.text.trim().isEmpty) return;
                  setDialogState(() {
                    isSearching = true;
                    result = null;
                  });

                  final res = await GovtSchemeService.instance.checkBeneficiaryStatus(
                    schemeId: scheme.id,
                    registrationOrAadhaarNumber: idController.text,
                  );

                  setDialogState(() {
                    isSearching = false;
                    result = res;
                  });
                },
                child: const Text('Check Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSchemeDetails(GovtScheme scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category & Status Pills
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scheme.category,
                          style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.isOpen ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                          ),
                        ),
                        child: Text(
                          scheme.status.toUpperCase(),
                          style: TextStyle(
                            color: scheme.isOpen ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Jurisdiction: ${scheme.state}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scheme Title
                  Text(
                    scheme.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scheme.department,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF616161), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // Benefits & Subsidy Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.currency_rupee_rounded, color: Color(0xFF2E7D32), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Financial Benefits & Subsidy',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scheme.benefitsSubsidy,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('About the Scheme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(scheme.description, style: const TextStyle(fontSize: 13, color: Color(0xFF424242), height: 1.4)),
                  const SizedBox(height: 18),

                  // Eligibility
                  const Text('Eligibility Criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...scheme.eligibilityCriteria.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 12.5, color: Color(0xFF424242)))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Required Documents
                  const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...scheme.requiredDocuments.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFF0288D1), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(doc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF424242)))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Dates & Official Portal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_note_rounded, color: Color(0xFFF57F17), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Deadline: ${scheme.deadline}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFE65100)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Official Portal: ${scheme.portalName} (${scheme.officialWebsiteUrl})',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      if (scheme.registrationIdLookupSupported)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.fingerprint_rounded, size: 18),
                            label: const Text('Check Status', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _openLookupDialog(scheme);
                            },
                          ),
                        ),
                      if (scheme.registrationIdLookupSupported) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Apply on Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening official portal: ${scheme.officialWebsiteUrl}'),
                                backgroundColor: const Color(0xFF1B5E20),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schemes = GovtSchemeService.instance.getSchemesForFarmer(
      state: _selectedState == 'All India' ? '' : _selectedState,
      district: widget.profile.effectiveDistrict,
      categoryFilter: _selectedCategory,
      statusFilter: _selectedStatus,
      searchQuery: _searchController.text,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Government Schemes & Subsidies',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Live Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search schemes, subsidies, tractors, drip...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B5E20)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FBF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),

                // State & Status selector row
                Row(
                  children: [
                    // State Dropdown
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedState,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1B5E20)),
                            items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedState = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1B5E20)),
                            items: _statuses.map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatus = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal Category Filter Pills
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
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
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF424242),
                        ),
                      ),
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: const Color(0xFFF1F5F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Scheme List
          Expanded(
            child: schemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.policy_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No schemes matching criteria',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: schemes.length,
                    itemBuilder: (context, i) {
                      final s = schemes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE8F5E9)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showSchemeDetails(s),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.category,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: s.isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: s.isOpen ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      s.state,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF757575), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.department,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FBF9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          s.benefitsSubsidy,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_outlined, size: 14, color: Color(0xFF757575)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Deadline: ${s.deadline}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Details & Apply',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1B5E20),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF1B5E20)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

