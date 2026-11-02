import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khetchacha/models/farmer_notification.dart';
import 'package:khetchacha/models/marketplace_product.dart';
import 'package:khetchacha/services/ai_crop_diagnosis_service.dart';
import 'package:khetchacha/services/expert_query_service.dart';
import 'package:khetchacha/services/govt_scheme_service.dart';
import 'package:khetchacha/services/marketplace_service.dart';
import 'package:khetchacha/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group(
    'GovtSchemeService - Government-First Agriculture Assistance (PS000046)',
    () {
      test('Loads official verified schemes with real data', () {
        final schemes = GovtSchemeService.instance.getAllSchemes();
        expect(schemes.isNotEmpty, isTrue);

        // Verify essential schemes exist
        final pmKisan = schemes.firstWhere((s) => s.id == 'pm-kisan-01');
        expect(pmKisan.name, contains('PM-Kisan'));
        expect(pmKisan.state, equals('All India'));
        expect(pmKisan.officialWebsiteUrl, contains('pmkisan.gov.in'));
        expect(pmKisan.registrationIdLookupSupported, isTrue);

        final ikhedutTractor = schemes.firstWhere(
          (s) => s.id == 'ikhedut-tractor-04',
        );
        expect(ikhedutTractor.state, equals('Gujarat'));
        expect(ikhedutTractor.category, equals('Equipment & Machinery'));
        expect(
          ikhedutTractor.officialWebsiteUrl,
          contains('ikhedut.gujarat.gov.in'),
        );
      });

      test('Filters schemes by state, category, and status', () {
        // Gujarat schemes (returns Gujarat + All India)
        final gujaratSchemes = GovtSchemeService.instance.getSchemesForFarmer(
          state: 'Gujarat',
        );
        expect(gujaratSchemes.any((s) => s.id == 'ikhedut-tractor-04'), isTrue);
        expect(gujaratSchemes.any((s) => s.id == 'pm-kisan-01'), isTrue);

        // Equipment & Machinery category
        final machinery = GovtSchemeService.instance.getSchemesForFarmer(
          state: 'Gujarat',
          categoryFilter: 'Equipment & Machinery',
        );
        expect(
          machinery.every((s) => s.category == 'Equipment & Machinery'),
          isTrue,
        );

        // Status filter
        final openSchemes = GovtSchemeService.instance.getSchemesForFarmer(
          state: 'Gujarat',
          statusFilter: 'Open',
        );
        expect(openSchemes.every((s) => s.status == 'Open'), isTrue);
      });

      test('Performs Aadhaar / Farmer ID status lookup accurately', () async {
        // Lookup PM-KISAN by valid 12-digit Aadhaar
        final validLookup = await GovtSchemeService.instance
            .checkBeneficiaryStatus(
              schemeId: 'pm-kisan-01',
              registrationOrAadhaarNumber: '123456789012',
            );
        expect(validLookup['found'], isTrue);
        expect(validLookup['beneficiaryStatus'], isNotEmpty);
        expect(validLookup['latestInstallment'], isNotNull);

        // Lookup with empty or invalid short ID
        final emptyLookup = await GovtSchemeService.instance
            .checkBeneficiaryStatus(
              schemeId: 'pm-kisan-01',
              registrationOrAadhaarNumber: '12',
            );
        expect(emptyLookup['found'], isFalse);
      });
    },
  );

  group(
    'ExpertQueryService - 3-Level Problem Taxonomy & Lifecycle (PS000046)',
    () {
      test('Provides complete 3-level taxonomy without missing nodes', () {
        final crops = ExpertQueryService.availableCrops;
        expect(crops.contains('Cotton'), isTrue);
        expect(crops.contains('Paddy (Rice)'), isTrue);
        expect(crops.contains('Wheat'), isTrue);

        final categories = ExpertQueryService.problemCategories;
        expect(categories.length, greaterThanOrEqualTo(5));

        final problems =
            ExpertQueryService.specificProblemsMap[categories.first];
        expect(problems, isNotNull);
        expect(problems!.isNotEmpty, isTrue);
      });

      test('Submits multi-modal query and generates unique Query ID', () async {
        final query = await ExpertQueryService.instance.submitQuery(
          farmerId: 'farmer_anand_01',
          farmerName: 'Ramesh Patel',
          farmerPhone: '9876543210',
          state: 'Gujarat',
          district: 'Anand',
          village: 'Hadgood',
          crop: 'Cotton',
          problemCategory: 'Pest & Insect Infestation',
          specificProblem: 'Pink Bollworm / Boll Damage',
          description: 'Flower buds are drooping with visible exit holes.',
          mediaPaths: ['assets/images/farmers/gujarat_farmer.jpg'],
          mediaTypes: ['image'],
        );

        expect(query.id, startsWith('KQ-2026-'));
        expect(query.status, equals('Submitted'));
        expect(query.crop, equals('Cotton'));
        expect(query.district, equals('Anand'));
      });

      test(
        'Updates lifecycle status to answered when expert replies',
        () async {
          final query = await ExpertQueryService.instance.submitQuery(
            farmerId: 'farmer_02',
            farmerName: 'Suresh',
            farmerPhone: '9876543211',
            state: 'Gujarat',
            district: 'Anand',
            village: 'Borsad',
            crop: 'Paddy (Rice)',
            problemCategory: 'Plant Disease (Fungal / Bacterial / Viral)',
            specificProblem: 'Blast (Spindle Spots)',
            description: 'Spindle-shaped lesions on leaves.',
            mediaPaths: [],
            mediaTypes: [],
          );

          await ExpertQueryService.instance.submitExpertResponse(
            queryId: query.id,
            expertId: 'exp_01',
            expertName: 'Dr. C. K. Patel',
            expertDesignation: 'Plant Pathologist, AAU Anand',
            responseText: 'Confirmed Rice Blast (Magnaporthe oryzae). Spray Tricyclazole 75% WP @ 0.6g/L.',
          );

          final answered = await ExpertQueryService.instance.getQueryById(
            query.id,
          );

          expect(answered, isNotNull);
          expect(answered!.status, equals('Answered'));
          expect(answered.expertResponseText, contains('Blast'));
        },
      );
    },
  );

  group(
    'AiCropDiagnosisService - AI Diagnostic Engine with Expert Escalation',
    () {
      test(
        'Diagnoses Cotton Pink Bollworm with Organic and Chemical treatments',
        () async {
          final result = await AiCropDiagnosisService.instance.analyzeCropImage(
            cropName: 'Cotton',
            imagePath: 'simulated_bollworm.jpg',
          );

          expect(result.cropName, equals('Cotton'));
          expect(result.diagnosisTitle.isNotEmpty, isTrue);
          expect(result.confidencePercentage, greaterThan(80.0));
          expect(result.organicRemedies.isNotEmpty, isTrue);
          expect(result.chemicalRemedies.isNotEmpty, isTrue);
          expect(result.uncertaintyWarning, isNotNull);
        },
      );

      test('Diagnoses Paddy Blast accurately', () async {
        final result = await AiCropDiagnosisService.instance.analyzeCropImage(
          cropName: 'Paddy',
          imagePath: 'simulated_blast.jpg',
        );

        expect(result.cropName, equals('Paddy (Rice)'));
        expect(result.symptoms.isNotEmpty, isTrue);
        expect(result.preventiveMeasures.isNotEmpty, isTrue);
      });
    },
  );

  group(
    'MarketplaceService - Natural Farming Product Marketplace (PS000046)',
    () {
      test(
        'Loads natural farming products with certification badges',
        () async {
          final products = await MarketplaceService.instance.getProducts();
          expect(products.isNotEmpty, isTrue);

          final jeevamrut = products.firstWhere((p) => p.id == 'prod-01');
          expect(jeevamrut.isCertifiedNatural, isTrue);
          expect(
            jeevamrut.certificationBadge,
            equals('Jaivik Bharat / PGS-India Green'),
          );
          expect(jeevamrut.price, greaterThan(0));
        },
      );

      test('Allows adding a new verified seller product listing', () async {
        final initialCount =
            (await MarketplaceService.instance.getProducts()).length;

        const newProduct = MarketplaceProduct(
          id: 'seller_listing_test_1',
          sellerId: 'farmer_01',
          sellerName: 'Bhavin Patel',
          sellerPhone: '9825012345',
          location: 'Borsad, Anand',
          title: 'Fresh Organic Desi Guava',
          category: 'Fruits & Vegetables',
          price: 40.0,
          unit: 'kg',
          stockQuantity: 200,
          isCertifiedNatural: true,
          certificationBadge: 'PGS-India Green',
          description: 'Naturally grown Guava without chemical fertilizers.',
        );

        await MarketplaceService.instance.addProduct(newProduct);
        final updatedList = await MarketplaceService.instance.getProducts();
        expect(updatedList.length, equals(initialCount + 1));
      });

      test('Generates order simulation for natural product purchase', () async {
        final products = await MarketplaceService.instance.getProducts();
        final product = products.first;

        final order = await MarketplaceService.instance.placeOrder(
          productId: product.id,
          productTitle: product.title,
          buyerName: 'Amit Shah',
          buyerPhone: '9876500000',
          deliveryAddress: 'Main Bazar, Anand, Gujarat',
          quantity: 2,
          unit: product.unit,
          unitPrice: product.price,
          paymentMethod: 'UPI QR Code',
        );

        expect(order.totalAmount, equals(product.price * 2));
        expect(order.paymentStatus, equals('Paid via UPI'));
        expect(order.orderStatus, equals('Confirmed'));
      });
    },
  );

  group('NotificationService - Multi-Category Agricultural Alerts', () {
    test(
      'Creates and manages notifications across all core categories',
      () async {
        await NotificationService.instance.init();

        final initialCount =
            (await NotificationService.instance.getNotifications()).length;

        await NotificationService.instance.addNotification(
          FarmerNotification(
            id: 'notif_test_1',
            title: 'New Scheme Open: iKhedut Tractor Subsidy',
            message: 'Applications are now open for Anand district farmers.',
            category: 'Government Schemes',
            timestamp: DateTime.now(),
            isRead: false,
            deepLinkTarget: 'govt_schemes',
          ),
        );

        final updated = await NotificationService.instance.getNotifications();
        expect(updated.length, equals(initialCount + 1));
        expect(
          NotificationService.instance.unreadCountNotifier.value,
          greaterThan(0),
        );

        // Mark notification as read
        await NotificationService.instance.markAsRead('notif_test_1');
        final notif = (await NotificationService.instance.getNotifications())
            .firstWhere((n) => n.id == 'notif_test_1');
        expect(notif.isRead, isTrue);

        // Filter by category
        final schemeNotifs = await NotificationService.instance
            .getNotifications(category: 'Government Schemes');
        expect(
          schemeNotifs.every((n) => n.category == 'Government Schemes'),
          isTrue,
        );
      },
    );
  });
}
