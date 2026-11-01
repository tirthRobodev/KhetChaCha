import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../localization/farm_products_data.dart';
import '../models/farm_product.dart';
import '../models/farmer_profile.dart';
import '../services/farm_profile_service.dart';
import '../services/farming_recommendation_service.dart';
import '../services/language_service.dart';
import '../widgets/khetchacha_logo.dart';
import 'farmer_dashboard_page.dart';

/// Screen 2 in Reference UI: [FarmProductionSelectionPage]
/// Allows farmers to select crops, vegetables, fruits, and flowers
/// with live search, category filtering, multi-select, and bottom summary.
class FarmProductionSelectionPage extends StatefulWidget {
  final FarmerProfile profile;
  final bool isEditMode;

  const FarmProductionSelectionPage({
    super.key,
    required this.profile,
    this.isEditMode = false,
  });

  @override
  State<FarmProductionSelectionPage> createState() => _FarmProductionSelectionPageState();
}

class _FarmProductionSelectionPageState extends State<FarmProductionSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all'; // 'all', 'crops', 'vegetables', 'fruits', 'flowers'
  String _searchQuery = '';
  final Set<String> _selectedProductIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing profile crops if any
    final existing = widget.profile.effectiveProducts;
    for (final cropName in existing) {
      // Find matching product id
      final match = FarmProductsData.allProducts.firstWhere(
        (p) =>
            p.id.toLowerCase() == cropName.toLowerCase() ||
            p.englishName.toLowerCase() == cropName.toLowerCase(),
        orElse: () => FarmProductsData.allProducts.first,
      );
      _selectedProductIds.add(match.id);
    }

    // Default to at least the top recommended crops for the farmer's state
    if (_selectedProductIds.isEmpty) {
      final recs = FarmingRecommendationService.instance
          .getRecommendedCropsForState(widget.profile.effectiveState);
      if (recs.isNotEmpty) {
        _selectedProductIds.addAll(recs.take(2).map((p) => p.id));
      } else {
        _selectedProductIds.add('paddy');
        _selectedProductIds.add('tomato');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FarmProduct> get _filteredProducts {
    return FarmProductsData.search(
      _searchQuery,
      category: _selectedCategory,
    );
  }

  void _toggleProduct(String id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  Future<void> _onContinueToDashboard() async {
    // If farmer has not selected any plant yet, automatically pick the state's top recommended crops so they can fast go to dashboard!
    if (_selectedProductIds.isEmpty) {
      final stateRecs = FarmingRecommendationService.instance
          .getRecommendedCropsForState(widget.profile.effectiveState);
      if (stateRecs.isNotEmpty) {
        _selectedProductIds.addAll(stateRecs.take(2).map((p) => p.id));
      } else {
        _selectedProductIds.addAll(['paddy', 'tomato']);
      }
    }

    setState(() {
      _isSaving = true;
    });

    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final selectedProductNames = _selectedProductIds.map((id) {
      final p = FarmProductsData.findById(id);
      return p != null ? p.englishName : id;
    }).toList();

    final selectedCategories = _selectedProductIds.map((id) {
      final p = FarmProductsData.findById(id);
      return p?.category ?? 'crops';
    }).toSet().toList();

    final updatedProfile = widget.profile.copyWith(
      crops: selectedProductNames,
      selectedProducts: selectedProductNames,
      selectedCategories: selectedCategories,
      selectedLanguage: langCode,
      farmSetupCompleted: true,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Save immediately to local cache & initiate Firebase background sync
    await FarmProfileService.instance.saveFarmProfile(updatedProfile);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (widget.isEditMode) {
      Navigator.of(context).pop(updatedProfile);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => FarmerDashboardPage(profile: updatedProfile),
        ),
        (route) => false,
      );
    }
  }

  void _openMoreProductsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _MoreProductsBottomSheet(
          selectedIds: _selectedProductIds,
          onToggle: (id) {
            setState(() {
              if (_selectedProductIds.contains(id)) {
                _selectedProductIds.remove(id);
              } else {
                _selectedProductIds.add(id);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final displayProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: widget.isEditMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: KhetChachaLogo.appBar(height: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Step Progress Indicator (if onboarding)
                    if (!widget.isEditMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            _buildStepCircle(
                              number: '1',
                              label: loc.stepLogin,
                              isActive: false,
                              isDone: true,
                            ),
                            Expanded(child: Container(height: 2, color: const Color(0xFF2E7D32))),
                            _buildStepCircle(
                              number: '2',
                              label: loc.stepSelectProduction,
                              isActive: true,
                              isDone: false,
                            ),
                            Expanded(child: Container(height: 2, color: const Color(0xFFE0E0E0))),
                            _buildStepCircle(
                              number: '3',
                              label: loc.stepDashboard,
                              isActive: false,
                              isDone: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Title & Subtitle Banner
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.park_rounded,
                            color: Color(0xFF2E7D32),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.selectFarmProductionTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.selectFarmProductionSubtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF616161),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: loc.searchCropsHint,
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Category Filter Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            id: 'all',
                            label: loc.categoryAllPopular,
                            icon: Icons.grid_view_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            id: 'crops',
                            label: loc.categoryCrops,
                            emoji: '🌾',
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            id: 'vegetables',
                            label: loc.categoryVegetables,
                            emoji: '🥕',
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            id: 'fruits',
                            label: loc.categoryFruits,
                            emoji: '🍎',
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            id: 'flowers',
                            label: loc.categoryFlowers,
                            emoji: '🌸',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. Responsive Product Grid (3 Columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayProducts.length + 1, // +1 for More Products card
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.86,
                      ),
                      itemBuilder: (context, index) {
                        // The last card is "+ More Products"
                        if (index == displayProducts.length) {
                          return _buildMoreProductsCard(loc);
                        }

                        final product = displayProducts[index];
                        final isSelected = _selectedProductIds.contains(product.id);

                        return _buildProductCard(
                          product: product,
                          isSelected: isSelected,
                          langCode: langCode,
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 6. Sticky Bottom Selected Panel & Continue Button
            _buildBottomPanel(loc, langCode),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    IconData? icon,
    String? emoji,
  }) {
    final isSelected = _selectedCategory == id;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF2E7D32)),
              const SizedBox(width: 6),
            ] else if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF424242),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required FarmProduct product,
    required bool isSelected,
    required String langCode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleProduct(product.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Checkbox at top right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),

              // Product Image / Visual + Title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    // Visual Graphic / Icon
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFFF9F7F1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            product.iconEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Crop Name
                    Text(
                      product.getLocalizedName(langCode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF212121),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreProductsCard(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openMoreProductsSheet,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF81C784),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF2E7D32),
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.moreProducts,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations loc, String langCode) {
    final selectedCount = _selectedProductIds.length;
    final selectedProducts = _selectedProductIds
        .map((id) => FarmProductsData.findById(id))
        .whereType<FarmProduct>()
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Selected (N) & Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.selectedCount(selectedCount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              if (selectedCount > 0)
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  child: Text(
                    loc.clearAll,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Chips of selected products
          if (selectedProducts.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedProducts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = selectedProducts[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.iconEmoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          p.getLocalizedName(langCode),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _toggleProduct(p.id),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Helper note
          if (selectedCount == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    loc.selectAtLeastOneHint,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                  ),
                ],
              ),
            ),

          // Continue Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              onPressed: _isSaving ? null : _onContinueToDashboard,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.continueToDashboard,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle({
    required String number,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    Color bg = const Color(0xFFEEEEEE);
    Color fg = const Color(0xFF9E9E9E);

    if (isActive) {
      bg = const Color(0xFF1B5E20);
      fg = Colors.white;
    } else if (isDone) {
      bg = const Color(0xFF2E7D32);
      fg = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    number,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1B5E20) : const Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}

/// Searchable Product Database Bottom Sheet for "+ More Products"
class _MoreProductsBottomSheet extends StatefulWidget {
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _MoreProductsBottomSheet({
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_MoreProductsBottomSheet> createState() => _MoreProductsBottomSheetState();
}

class _MoreProductsBottomSheetState extends State<_MoreProductsBottomSheet> {
  final TextEditingController _sheetSearchController = TextEditingController();
  String _sheetQuery = '';
  final String _sheetCategory = 'all';

  @override
  void dispose() {
    _sheetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final results = FarmProductsData.search(
      _sheetQuery,
      category: _sheetCategory == 'all' ? null : _sheetCategory,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Full Crop Database / તમામ પાક ડેટાબેઝ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Search field
              TextField(
                controller: _sheetSearchController,
                onChanged: (v) => setState(() => _sheetQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search 50+ crops, vegetables, fruits...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
                  filled: true,
                  fillColor: const Color(0xFFF9F7F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Product list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = results[i];
                    final isChecked = widget.selectedIds.contains(p.id);

                    return CheckboxListTile(
                      activeColor: const Color(0xFF2E7D32),
                      value: isChecked,
                      onChanged: (_) {
                        widget.onToggle(p.id);
                        setState(() {});
                      },
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(p.iconEmoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      title: Text(
                        p.getLocalizedName(langCode),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${p.englishName} • ${p.category.toUpperCase()}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done Selecting',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
