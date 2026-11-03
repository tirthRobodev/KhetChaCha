import 'package:flutter/material.dart';

import '../../models/annual_crop_plan.dart';
import '../../models/farmer_profile.dart';
import '../../services/annual_crop_planner_service.dart';
import '../../services/language_service.dart';

/// Two-Crop Annual Farm Rotation Planning Screen.
/// Models the two-crop agricultural year (Kharif Monsoon followed by Rabi Winter),
/// evaluating rotational compatibility, nitrogen fixation credit, turnaround feasibility,
/// and total annual net profit.
class AnnualFarmPlannerPage extends StatefulWidget {
  final FarmerProfile profile;

  const AnnualFarmPlannerPage({super.key, required this.profile});

  @override
  State<AnnualFarmPlannerPage> createState() => _AnnualFarmPlannerPageState();
}

class _AnnualFarmPlannerPageState extends State<AnnualFarmPlannerPage> {
  late List<AnnualCropPlan> _plans;
  late AnnualCropPlan _selectedPlan;
  late double _farmAcres;

  @override
  void initState() {
    super.initState();
    _plans = AnnualCropPlannerService.instance.generateAnnualPlans(
      widget.profile,
    );
    _selectedPlan = _plans.isNotEmpty ? _plans.first : _plans.first;

    double parsed = double.tryParse(widget.profile.effectiveFarmSize) ?? 2.0;
    if (parsed <= 0) parsed = 2.0;
    _farmAcres = parsed;
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
              ? 'વાર્ષિક દ્વિ-પાક આયોજન'
              : (langCode == 'hi'
                    ? 'वार्षिक दो-फसल योजना'
                    : 'Annual Two-Crop Farm Planner'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Farm Context Header
            _buildFarmHeaderCard(langCode),

            const SizedBox(height: 16),

            // 2. Selected Two-Crop Rotation Card
            _buildSelectedRotationCard(langCode),

            const SizedBox(height: 16),

            // 3. Rotational Compatibility & Turnaround Feasibility
            _buildCompatibilityCard(langCode),

            const SizedBox(height: 16),

            // 4. Combined Annual Financial Projection
            _buildAnnualFinancialCard(langCode),

            const SizedBox(height: 16),

            // 5. Agronomic Management Calendar
            _buildAgronomicCalendarCard(langCode),

            const SizedBox(height: 16),

            // 6. Alternate Recommended Rotations
            _buildAlternativeRotationsList(langCode),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmHeaderCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agricultural Year: ${_selectedPlan.agriculturalYear}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.profile.effectiveDistrict}, ${widget.profile.effectiveState} • ${_farmAcres.toStringAsFixed(1)} Acres',
                style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '2 Seasons / Year',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRotationCard(String langCode) {
    final c1 = _selectedPlan.firstCrop;
    final c2 = _selectedPlan.secondCrop;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECOMMENDED TWO-CROP ANNUAL CYCLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Kharif Crop
              Expanded(
                child: _buildCropCycleBox(
                  season: '1st: KHARIF (Monsoon)',
                  name: c1.englishName,
                  emoji: c1.iconEmoji,
                  sowing: c1.bestSowingPeriod,
                  harvest: c1.expectedHarvestPeriod,
                  profit:
                      '₹${(c1.netProfitPerAcre / 1000).toStringAsFixed(0)}k/ac',
                  color: const Color(0xFF1B5E20),
                ),
              ),

              // Arrow
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2E7D32),
                ),
              ),

              // Rabi Crop
              Expanded(
                child: _buildCropCycleBox(
                  season: '2nd: RABI (Winter)',
                  name: c2.englishName,
                  emoji: c2.iconEmoji,
                  sowing: c2.bestSowingPeriod,
                  harvest: c2.expectedHarvestPeriod,
                  profit:
                      '₹${(c2.netProfitPerAcre / 1000).toStringAsFixed(0)}k/ac',
                  color: const Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropCycleBox({
    required String season,
    required String name,
    required String emoji,
    required String sowing,
    required String harvest,
    required String profit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            season,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '🌱 Sow: $sowing',
            style: const TextStyle(fontSize: 10, color: Color(0xFF616161)),
          ),
          Text(
            '🌾 Harvest: $harvest',
            style: const TextStyle(fontSize: 10, color: Color(0xFF616161)),
          ),
          const SizedBox(height: 4),
          Text(
            'Profit: $profit',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard(String langCode) {
    final plan = _selectedPlan;
    final isCompatible = plan.isTurnaroundFeasible;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompatible ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompatible
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFEF9A9A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCompatible
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: isCompatible
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rotational Compatibility: ${plan.rotationCompatibilityScore}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCompatible
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${plan.turnaroundDays}d turnaround',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompatible
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.compatibilityReason,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: isCompatible
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualFinancialCard(String langCode) {
    final costPerAcre = _selectedPlan.totalAnnualCostPerAcre;
    final revPerAcre = _selectedPlan.totalAnnualGrossRevenuePerAcre;
    final netPerAcre = _selectedPlan.totalAnnualNetProfitPerAcre;

    final farmCost = _selectedPlan.totalAnnualCostForFarm(_farmAcres);
    final farmRev = _selectedPlan.totalAnnualGrossRevenueForFarm(_farmAcres);
    final farmNet = _selectedPlan.totalAnnualNetProfitForFarm(_farmAcres);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ANNUAL FARM FINANCIAL PROJECTION',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Total Farm (${_farmAcres.toStringAsFixed(1)} Ac)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${farmNet.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'annual net profit',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnnualMetric(
                'Annual Investment',
                '₹${farmCost.toStringAsFixed(0)}',
                '₹${costPerAcre.toStringAsFixed(0)}/ac',
              ),
              _buildAnnualMetric(
                'Gross Revenue',
                '₹${farmRev.toStringAsFixed(0)}',
                '₹${revPerAcre.toStringAsFixed(0)}/ac',
              ),
              _buildAnnualMetric(
                'Net Return / Ac',
                '₹${netPerAcre.toStringAsFixed(0)}/ac',
                'Margin ~${((netPerAcre / revPerAcre) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualMetric(String label, String farmVal, String subVal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          farmVal,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subVal,
          style: const TextStyle(color: Colors.white60, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildAgronomicCalendarCard(String langCode) {
    final p = _selectedPlan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
              SizedBox(width: 8),
              Text(
                'Yearly Agronomic Management Calendar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTimelineStep(
            '1',
            'Kharif Land Preparation',
            p.kharifLandPrepPeriod,
          ),
          _buildTimelineStep(
            '2',
            'Kharif Sowing to Harvest',
            '${p.kharifSowingDate}  ➝  ${p.kharifHarvestDate}',
          ),
          _buildTimelineStep(
            '3',
            'Rabi Seedbed Preparation',
            p.rabiLandPrepPeriod,
          ),
          _buildTimelineStep(
            '4',
            'Rabi Sowing to Harvest',
            '${p.rabiSowingDate}  ➝  ${p.rabiHarvestDate}',
          ),
          const Divider(height: 20),
          const Text(
            'Fertilizer & Nutrition Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...p.fertilizerSchedule.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• $f',
                style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Water & Irrigation Timeline',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...p.irrigationSchedule.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• $i',
                style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF1B5E20),
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeRotationsList(String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPLORE OTHER COMPATIBLE ANNUAL ROTATIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF757575),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _plans.length.clamp(0, 5),
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final plan = _plans[i];
            final isSelected = plan.id == _selectedPlan.id;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.black12,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${plan.firstCrop.iconEmoji} ➝ ${plan.secondCrop.iconEmoji}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.firstCrop.englishName} + ${plan.secondCrop.englishName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Score: ${plan.rotationCompatibilityScore}% • Profit: ₹${(plan.totalAnnualNetProfitPerAcre / 1000).toStringAsFixed(0)}k/ac',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black26,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
