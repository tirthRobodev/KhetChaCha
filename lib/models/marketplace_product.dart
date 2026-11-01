/// Model representing a product in the Natural Farming Marketplace.
/// Clearly distinguishes verified natural/organic certified products from unverified items.
class MarketplaceProduct {
  final String id;
  final String title;
  final String category; // 'Crops & Grains', 'Vegetables', 'Fruits', 'Bio-Fertilizers & Jeevamrut', 'Natural Pesticides', 'Desi Seeds'
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String location;
  final double price;
  final String unit; // 'kg', 'Quintal', 'Litre', 'Packet'
  final double stockQuantity;
  final bool isCertifiedNatural;
  final String certificationBadge; // 'Jaivik Bharat / PGS-India', 'State Natural Mission', 'Farmer Verified'
  final String description;
  final String? imageUrl;
  final double rating;

  const MarketplaceProduct({
    required this.id,
    required this.title,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.location,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.isCertifiedNatural,
    required this.certificationBadge,
    required this.description,
    this.imageUrl,
    this.rating = 4.8,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'location': location,
        'price': price,
        'unit': unit,
        'stockQuantity': stockQuantity,
        'isCertifiedNatural': isCertifiedNatural,
        'certificationBadge': certificationBadge,
        'description': description,
        'imageUrl': imageUrl,
        'rating': rating,
      };

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) => MarketplaceProduct(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'Crops & Grains',
        sellerId: json['sellerId'] as String? ?? '',
        sellerName: json['sellerName'] as String? ?? 'Farmer Seller',
        sellerPhone: json['sellerPhone'] as String? ?? '',
        location: json['location'] as String? ?? 'Gujarat',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'kg',
        stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
        isCertifiedNatural: json['isCertifiedNatural'] as bool? ?? false,
        certificationBadge: json['certificationBadge'] as String? ?? 'Farmer Verified',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      );
}

/// Model for Customer Orders in the Marketplace
class MarketplaceOrder {
  final String id;
  final String productId;
  final String productTitle;
  final String buyerName;
  final String buyerPhone;
  final String deliveryAddress;
  final double quantity;
  final String unit;
  final double totalAmount;
  final String paymentMethod; // 'UPI QR Code', 'Cash on Delivery'
  final String paymentStatus;
  final String orderStatus; // 'Confirmed', 'Dispatched', 'Delivered'
  final DateTime createdAt;

  const MarketplaceOrder({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerName,
    required this.buyerPhone,
    required this.deliveryAddress,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productTitle': productTitle,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'deliveryAddress': deliveryAddress,
        'quantity': quantity,
        'unit': unit,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'createdAt': createdAt.toIso8601String(),
      };
}

