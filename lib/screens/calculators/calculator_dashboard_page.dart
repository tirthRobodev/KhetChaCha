import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../localization/calculator_localization.dart';
import '../../widgets/khetchacha_logo.dart';
import 'fertilizer_calculator_page.dart';
import 'farmer_calculator_page.dart';
import 'land_area_calculator_page.dart';
import 'seed_calculator_page.dart';
import 'crop_yield_calculator_page.dart';
import 'farm_cost_profit_calculator_page.dart';
import 'irrigation_calculator_page.dart';
import 'pesticide_dilution_calculator_page.dart';

enum CalculatorCategory {
  all,
  cropFertilizer,
  farmLand,
  costProfit,
  waterIrrigation,
}

class CalculatorMeta {
  final String id;
  final String nameKey;
  final String descKey;
  final IconData icon;
  final Color primaryColor;
  final List<CalculatorCategory> categories;
  final Widget Function(BuildContext) builder;

  const CalculatorMeta({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.icon,
    required this.primaryColor,
    required this.categories,
    required this.builder,
  });
}

class CalculatorDashboardPage extends StatefulWidget {
  const CalculatorDashboardPage({super.key});

  @override
  State<CalculatorDashboardPage> createState() => _CalculatorDashboardPageState();
}

class _CalculatorDashboardPageState extends State<CalculatorDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  CalculatorCategory _selectedCategory = CalculatorCategory.all;
  String _searchQuery = '';

  late final List<CalculatorMeta> _allCalculators;

  @override
  void initState() {
    super.initState();
    _allCalculators = [
      CalculatorMeta(
        id: 'fertilizer',
        nameKey: 'fertilizer_calc_name',
        descKey: 'fertilizer_calc_desc',
        icon: Icons.scale_rounded,
        primaryColor: const Color(0xFF2E7D32),
        categories: [CalculatorCategory.cropFertilizer],
        builder: (_) => const FertilizerCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'farmer',
        nameKey: 'farmer_calc_name',
        descKey: 'farmer_calc_desc',
        icon: Icons.agriculture_rounded,
        primaryColor: const Color(0xFFE65100),
        categories: [CalculatorCategory.farmLand, CalculatorCategory.costProfit],
        builder: (_) => const FarmerCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'land',
        nameKey: 'land_calc_name',
        descKey: 'land_calc_desc',
        icon: Icons.landscape_rounded,
        primaryColor: const Color(0xFF1B5E20),
        categories: [CalculatorCategory.farmLand],
        builder: (_) => const LandAreaCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'seed',
        nameKey: 'seed_calc_name',
        descKey: 'seed_calc_desc',
        icon: Icons.grain_rounded,
        primaryColor: const Color(0xFF558B2F),
        categories: [CalculatorCategory.cropFertilizer],
        builder: (_) => const SeedCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'yield',
        nameKey: 'yield_calc_name',
        descKey: 'yield_calc_desc',
        icon: Icons.eco_rounded,
        primaryColor: const Color(0xFF33691E),
        categories: [CalculatorCategory.cropFertilizer],
        builder: (_) => const CropYieldCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'cost_profit',
        nameKey: 'cost_profit_calc_name',
        descKey: 'cost_profit_calc_desc',
        icon: Icons.currency_rupee_rounded,
        primaryColor: const Color(0xFFC62828),
        categories: [CalculatorCategory.costProfit],
        builder: (_) => const FarmCostProfitCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'irrigation',
        nameKey: 'irrigation_calc_name',
        descKey: 'irrigation_calc_desc',
        icon: Icons.water_drop_rounded,
        primaryColor: const Color(0xFF0277BD),
        categories: [CalculatorCategory.waterIrrigation],
        builder: (_) => const IrrigationCalculatorPage(),
      ),
      CalculatorMeta(
        id: 'pesticide',
        nameKey: 'pesticide_calc_name',
        descKey: 'pesticide_calc_desc',
        icon: Icons.pest_control_rounded,
        primaryColor: const Color(0xFF6A1B9A),
        categories: [CalculatorCategory.cropFertilizer],
        builder: (_) => const PesticideDilutionCalculatorPage(),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CalculatorMeta> _getFilteredCalculators(String langCode) {
    return _allCalculators.where((calc) {
      // Category filter
      if (_selectedCategory != CalculatorCategory.all &&
          !calc.categories.contains(_selectedCategory)) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isEmpty) return true;

      final query = _searchQuery.trim().toLowerCase();
      final title = CalculatorLocalization.t(calc.nameKey, langCode).toLowerCase();
      final desc = CalculatorLocalization.t(calc.descKey, langCode).toLowerCase();
      final titleEn = CalculatorLocalization.t(calc.nameKey, 'en').toLowerCase();

      return title.contains(query) || desc.contains(query) || titleEn.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.instance.currentLanguage;
    final langCode = activeLang.locale.languageCode;
    final filtered = _getFilteredCalculators(langCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            KhetChachaLogo.mark(size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CalculatorLocalization.t('dashboard_title', langCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    CalculatorLocalization.t('dashboard_subtitle', langCode),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 14, color: Color(0xFFFFD54F)),
                const SizedBox(width: 4),
                Text(
                  activeLang.nativeName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Green Banner with Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                    hintText: CalculatorLocalization.t('search_placeholder', langCode),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B5E20)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Category Chips Row
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(langCode, 'cat_all', CalculatorCategory.all),
                  _buildCategoryChip(langCode, 'cat_crop_fertilizer', CalculatorCategory.cropFertilizer),
                  _buildCategoryChip(langCode, 'cat_farm_land', CalculatorCategory.farmLand),
                  _buildCategoryChip(langCode, 'cat_cost_profit', CalculatorCategory.costProfit),
                  _buildCategoryChip(langCode, 'cat_water_irrigation', CalculatorCategory.waterIrrigation),
                ],
              ),
            ),

            // Calculators Grid / List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            CalculatorLocalization.t('no_results_found', langCode),
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final calc = filtered[index];
                        return _buildCalculatorCard(context, calc, langCode);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String langCode, String labelKey, CalculatorCategory cat) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(CalculatorLocalization.t(labelKey, langCode)),
        selected: isSelected,
        selectedColor: const Color(0xFF1B5E20),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = cat;
            });
          }
        },
      ),
    );
  }

  Widget _buildCalculatorCard(BuildContext context, CalculatorMeta calc, String langCode) {
    final title = CalculatorLocalization.t(calc.nameKey, langCode);
    final desc = CalculatorLocalization.t(calc.descKey, langCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: calc.builder),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: calc.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(calc.icon, color: calc.primaryColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: calc.builder),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  CalculatorLocalization.t('calculate_action', langCode),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
