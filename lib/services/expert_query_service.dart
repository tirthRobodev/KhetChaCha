import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expert_query.dart';

/// Service managing Ask Agriculture Expert queries, 3-level taxonomy,
/// audio/video/image attachments, query lifecycle tracking, and expert replies.
class ExpertQueryService {
  ExpertQueryService._();
  static final ExpertQueryService instance = ExpertQueryService._();

  static const String _storageKey = 'khetchacha_expert_queries_v1';
  final List<ExpertQuery> _queries = [];
  bool _isInitialized = false;

  // 3-Level Problem Taxonomy Definitions
  static const List<String> availableCrops = [
    'Cotton',
    'Paddy (Rice)',
    'Wheat',
    'Tomato',
    'Groundnut',
    'Mustard',
    'Soybean',
    'Sugarcane',
    'Potato',
    'Onion',
    'Mango',
    'Banana',
    'Chilli',
    'Cumin (Jeera)',
    'Bajra (Pearl Millet)',
    'Maize',
  ];

  static const List<String> problemCategories = [
    'Pest & Insect Infestation',
    'Plant Disease (Fungal / Bacterial / Viral)',
    'Nutrient Deficiency & Leaf Yellowing',
    'Weed Infestation & Control',
    'Irrigation, Moisture & Wilting',
    'Flower & Fruit Dropping',
    'Soil Salinity & Root Growth Issue',
  ];

  static const Map<String, List<String>> specificProblemsMap = {
    'Pest & Insect Infestation': [
      'Pink Bollworm / Boll Damage',
      'Whitefly & Sooty Mold',
      'Stem Borer / Dead Heart',
      'Fruit Borer / Caterpillar',
      'Brown Plant Hopper (BPH)',
      'Aphids, Jassids & Thrips (Sucking Pests)',
      'Termites / White Grubs in Soil',
      'Fall Armyworm',
      'Other Unidentified Pest',
    ],
    'Plant Disease (Fungal / Bacterial / Viral)': [
      'Leaf Curl Virus (Yellowing & Curling)',
      'Early / Late Blight (Brown Ring Spots)',
      'Yellow Rust / Stripe Rust',
      'Blast Disease (Neck / Node Blast)',
      'Tikka Disease / Leaf Spot',
      'Powdery Mildew / Downy Mildew',
      'Fusarium Wilt / Root Rot / Damping Off',
      'Bacterial Canker / Spot',
      'Other Unidentified Disease',
    ],
    'Nutrient Deficiency & Leaf Yellowing': [
      'Nitrogen Deficiency (Pale Lower Leaves)',
      'Phosphorus Deficiency (Purple/Red Tinge)',
      'Potassium Deficiency (Burnt Leaf Edges)',
      'Zinc Deficiency (Khaira Disease / Interveinal)',
      'Iron Deficiency (Bleached Young Leaves)',
      'Boron Deficiency (Cracked Stems / Poor Fruit Set)',
      'General Stunted Growth',
    ],
    'Weed Infestation & Control': [
      'Broad-leaved Weeds in standing crop',
      'Grassy Weeds / Phalaris minor',
      'Cyperus rotundus (Motha / Nut Grass)',
      'Post-emergence Herbicide Injury',
    ],
    'Irrigation, Moisture & Wilting': [
      'Waterlogging / Poor Drainage Chlorosis',
      'Drought / Moisture Stress at Critical Stage',
      'Sudden Wilting after Heavy Irrigation',
      'Drip Emitter Clogging / Uneven Flow',
    ],
    'Flower & Fruit Dropping': [
      'Heavy Flower Drop during High Heat',
      'Premature Fruit Drop before Maturity',
      'Poor Pollination & Fruit Malformation',
    ],
    'Soil Salinity & Root Growth Issue': [
      'White Salt Crust on Soil Surface',
      'Hard Pan / Poor Root Penetration',
      'Nematode Galls / Knots on Roots',
    ],
  };

  /// Initialize and load saved queries from storage
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List decoded = jsonDecode(data) as List;
        _queries.clear();
        for (var item in decoded) {
          _queries.add(
            ExpertQuery.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('[ExpertQueryService] Init error: $e');
    }

    // Seed default sample query for demonstration if empty
    if (_queries.isEmpty) {
      _queries.add(
        ExpertQuery(
          id: 'KQ-2026-8941',
          farmerId: 'demo_farmer_01',
          farmerName: 'Kisan Bhai',
          farmerPhone: '9876543210',
          state: 'Gujarat',
          district: 'Anand',
          village: 'Hadgood',
          crop: 'Cotton',
          problemCategory: 'Pest & Insect Infestation',
          specificProblem: 'Pink Bollworm / Boll Damage',
          description: 'Noticed small entry holes on cotton bolls and rosette flowers. Please suggest organic or bio-control measures immediately.',
          mediaPaths: ['assets/images/farmers/gujarat_farmer.jpg'],
          mediaTypes: ['image'],
          status: 'Answered',
          submittedAt: DateTime.now().subtract(const Duration(hours: 18)),
          assignedExpertId: 'exp_aau_01',
          assignedExpertName: 'Dr. Ramesh Patel',
          expertDesignation: 'Principal Agronomist & Entomologist, Anand Agricultural University (AAU)',
          expertResponseText: 'Dear Farmer, based on the symptoms, install 8-10 Pheromone Traps (Pectino-Lure) per acre immediately. Release Trichogramma bactrae egg parasitoids @ 60,000/acre at 7-day intervals. For direct spray, apply Neem Seed Kernel Extract (NSKE 5%) or Emamectin Benzoate 5% SG @ 5 grams in 15 liters of water. Avoid broad-spectrum chemical sprays during peak flowering.',
          answeredAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      );
    }
    _isInitialized = true;
  }

  /// Get all queries submitted by a farmer
  Future<List<ExpertQuery>> getFarmerQueries(String farmerId) async {
    await init();
    return _queries.toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  /// Get query details by ID
  Future<ExpertQuery?> getQueryById(String id) async {
    await init();
    try {
      return _queries.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Submit a new multi-modal query
  Future<ExpertQuery> submitQuery({
    required String farmerId,
    required String farmerName,
    required String farmerPhone,
    required String state,
    required String district,
    required String village,
    required String crop,
    required String problemCategory,
    required String specificProblem,
    required String description,
    required List<String> mediaPaths,
    required List<String> mediaTypes,
  }) async {
    await init();

    final queryId =
        'KQ-${DateTime.now().year}-${1000 + Random().nextInt(9000)}';

    final newQuery = ExpertQuery(
      id: queryId,
      farmerId: farmerId,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      state: state.isNotEmpty ? state : 'Gujarat',
      district: district.isNotEmpty ? district : 'Anand',
      village: village,
      crop: crop,
      problemCategory: problemCategory,
      specificProblem: specificProblem,
      description: description,
      mediaPaths: mediaPaths,
      mediaTypes: mediaTypes,
      status: 'Submitted',
      submittedAt: DateTime.now(),
    );

    _queries.insert(0, newQuery);
    await _saveToStorage();

    // Simulate automatic assignment to regional KVK/University expert within Anand/district
    _scheduleAutomatedExpertAssignment(newQuery.id);

    return newQuery;
  }

  void _scheduleAutomatedExpertAssignment(String queryId) {
    Future.delayed(const Duration(seconds: 4), () async {
      final index = _queries.indexWhere((q) => q.id == queryId);
      if (index != -1) {
        _queries[index] = _queries[index].copyWith(
          status: 'Under Review',
          assignedExpertId: 'exp_aau_02',
          assignedExpertName: 'Dr. M. S. Solanki',
          expertDesignation: 'Senior Plant Pathologist, KVK Anand / AAU',
        );
        await _saveToStorage();
      }
    });

    Future.delayed(const Duration(seconds: 12), () async {
      final index = _queries.indexWhere((q) => q.id == queryId);
      if (index != -1 && !_queries[index].isAnswered) {
        final crop = _queries[index].crop;
        final problem = _queries[index].specificProblem;

        _queries[index] = _queries[index].copyWith(
          status: 'Answered',
          assignedExpertId: 'exp_aau_02',
          assignedExpertName: 'Dr. M. S. Solanki',
          expertDesignation: 'Senior Plant Pathologist, KVK Anand / AAU',
          expertResponseText:
              'Official Agricultural Advisory for $crop ($problem): Ensure balanced soil nutrients and avoid excess nitrogen. Recommended treatment: Spray copper oxychloride 50 WP @ 2.5g/L or Trichoderma viride bio-fungicide @ 5g/L. Maintain field drainage and monitor weekly.',
          answeredAt: DateTime.now(),
        );
        await _saveToStorage();
      }
    });
  }

  /// Expert manual response (Role-based expert dashboard)
  Future<void> submitExpertResponse({
    required String queryId,
    required String expertId,
    required String expertName,
    required String expertDesignation,
    required String responseText,
    String? responseAudioUrl,
    List<String>? responseAttachments,
  }) async {
    await init();
    final index = _queries.indexWhere((q) => q.id == queryId);
    if (index != -1) {
      _queries[index] = _queries[index].copyWith(
        status: 'Answered',
        assignedExpertId: expertId,
        assignedExpertName: expertName,
        expertDesignation: expertDesignation,
        expertResponseText: responseText,
        expertResponseAudioUrl: responseAudioUrl,
        expertResponseAttachments: responseAttachments,
        answeredAt: DateTime.now(),
      );
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_queries.map((q) => q.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('[ExpertQueryService] Save error: $e');
    }
  }
}
