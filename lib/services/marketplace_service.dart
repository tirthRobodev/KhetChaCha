import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/marketplace_product.dart';

/// Service managing the Natural Farming Marketplace.
/// Enables farmers to register as sellers, add certified natural products,
/// manage stock, and allows buyers to browse, search, and order via UPI QR.
class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  static const String _productsKey = 'khetchacha_marketplace_products_v1';
  static const String _ordersKey = 'khetchacha_marketplace_orders_v1';

  final List<MarketplaceProduct> _products = [];
  final List<MarketplaceOrder> _orders = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsData = prefs.getString(_productsKey);
      if (productsData != null && productsData.isNotEmpty) {
        final List list = jsonDecode(productsData) as List;
        _products.clear();
        for (var item in list) {
          _products.add(
            MarketplaceProduct.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('[MarketplaceService] Init error: $e');
    }

    if (_products.isEmpty) {
      _products.addAll([
        const MarketplaceProduct(
          id: 'prod-01',
          title: 'Desi Gir Cow Liquid Jeevamrut (Fermented)',
          category: 'Bio-Fertilizers & Jeevamrut',
          sellerId: 'sel_anand_01',
          sellerName: 'Patel Prakrutik Farm',
          sellerPhone: '+91 98251 12345',
          location: 'Anand, Gujarat',
          price: 15.0,
          unit: 'Litre',
          stockQuantity: 450.0,
          isCertifiedNatural: true,
          certificationBadge: 'Jaivik Bharat / PGS-India Green',
          description: 'Freshly brewed culture of Gir Cow dung, urine, besan, and fertile soil microbes. Enriches soil microbial population and speeds plant vegetative growth.',
          rating: 4.9,
        ),
        const MarketplaceProduct(
          id: 'prod-02',
          title: 'Organic Bhalia Desi Wheat (Gluten Rich)',
          category: 'Crops & Grains',
          sellerId: 'sel_anand_02',
          sellerName: 'Bhal Natural Farmers FPO',
          sellerPhone: '+91 94280 67890',
          location: 'Tarapur, Anand, Gujarat',
          price: 3600.0,
          unit: 'Quintal',
          stockQuantity: 80.0,
          isCertifiedNatural: true,
          certificationBadge: 'State Natural Farming Mission',
          description: 'GI-tagged non-irrigated Bhalia wheat cultivated without synthetic DAP or Urea. Golden grains with high protein and natural sweetness.',
          rating: 4.8,
        ),
        const MarketplaceProduct(
          id: 'prod-03',
          title: 'Naturally Ripened Kesar Mangoes',
          category: 'Fruits',
          sellerId: 'sel_anand_03',
          sellerName: 'Gir Organic Orchards',
          sellerPhone: '+91 98980 11223',
          location: 'Junagadh / Anand Depot, Gujarat',
          price: 140.0,
          unit: 'kg',
          stockQuantity: 250.0,
          isCertifiedNatural: true,
          certificationBadge: 'Jaivik Bharat / PGS-India',
          description: 'Carbide-free, hay-straw ripened aromatic Gir Kesar mangoes. Harvested at full physiological maturity.',
          rating: 5.0,
        ),
        const MarketplaceProduct(
          id: 'prod-04',
          title: 'Neemastra Bio-Pesticide (Neem Extract)',
          category: 'Natural Pesticides',
          sellerId: 'sel_anand_01',
          sellerName: 'Patel Prakrutik Farm',
          sellerPhone: '+91 98251 12345',
          location: 'Anand, Gujarat',
          price: 60.0,
          unit: 'Litre',
          stockQuantity: 120.0,
          isCertifiedNatural: true,
          certificationBadge: 'Farmer Verified',
          description: 'Potent botanical extract of pure neem leaves and desi cow urine. Highly effective against sucking pests, aphids, and jassids.',
          rating: 4.7,
        ),
        const MarketplaceProduct(
          id: 'prod-05',
          title: 'Cold-Pressed Desi Groundnut Oil (Wood Churned)',
          category: 'Crops & Grains',
          sellerId: 'sel_anand_04',
          sellerName: 'Amul Khedut Shuddh Tel',
          sellerPhone: '+91 97123 45678',
          location: 'Anand, Gujarat',
          price: 260.0,
          unit: 'Litre',
          stockQuantity: 180.0,
          isCertifiedNatural: true,
          certificationBadge: 'PGS-India Green Certified',
          description: 'Authentic cold pressed (Kachi Ghani) wooden press oil from naturally cultivated Saurashtra groundnuts. Zero chemical refining or bleaching.',
          rating: 4.9,
        ),
      ]);
    }
    _isInitialized = true;
  }

  Future<List<MarketplaceProduct>> getProducts({
    String? category,
    bool? naturalOnly,
    String? searchQuery,
  }) async {
    await init();
    return _products.where((p) {
      if (category != null && category.isNotEmpty && category != 'All') {
        if (p.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (naturalOnly == true && !p.isCertifiedNatural) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matches =
            p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  Future<void> addProduct(MarketplaceProduct product) async {
    await init();
    _products.insert(0, product);
    await _saveProducts();
  }

  Future<MarketplaceOrder> placeOrder({
    required String productId,
    required String productTitle,
    required String buyerName,
    required String buyerPhone,
    required String deliveryAddress,
    required double quantity,
    required String unit,
    required double unitPrice,
    required String paymentMethod,
  }) async {
    await init();
    final order = MarketplaceOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      productId: productId,
      productTitle: productTitle,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      deliveryAddress: deliveryAddress,
      quantity: quantity,
      unit: unit,
      totalAmount: quantity * unitPrice,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'UPI QR Code'
          ? 'Paid via UPI'
          : 'Pending (COD)',
      orderStatus: 'Confirmed',
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);
    await _saveOrders();
    return order;
  }

  Future<List<MarketplaceOrder>> getOrders() async {
    await init();
    return _orders;
  }

  Future<void> _saveProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_products.map((p) => p.toJson()).toList());
      await prefs.setString(_productsKey, data);
    } catch (e) {
      debugPrint('[MarketplaceService] Save products error: $e');
    }
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_orders.map((o) => o.toJson()).toList());
      await prefs.setString(_ordersKey, data);
    } catch (e) {
      debugPrint('[MarketplaceService] Save orders error: $e');
    }
  }
}
