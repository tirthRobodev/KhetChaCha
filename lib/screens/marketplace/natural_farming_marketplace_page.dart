import 'package:flutter/material.dart';
import '../../models/farmer_profile.dart';
import '../../models/marketplace_product.dart';
import '../../services/marketplace_service.dart';

/// Full-Featured Natural Farming Marketplace Screen.
/// Supports buying & selling of verified natural products (Jeevamrut, Bhalia wheat,
/// organic vegetables, bio-pesticides), organic certification badges, and UPI QR payments.
class NaturalFarmingMarketplacePage extends StatefulWidget {
  final FarmerProfile profile;

  const NaturalFarmingMarketplacePage({super.key, required this.profile});

  @override
  State<NaturalFarmingMarketplacePage> createState() => _NaturalFarmingMarketplacePageState();
}

class _NaturalFarmingMarketplacePageState extends State<NaturalFarmingMarketplacePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  bool _certifiedOnly = true;
  List<MarketplaceProduct> _products = [];
  List<MarketplaceOrder> _orders = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Bio-Fertilizers & Jeevamrut',
    'Crops & Grains',
    'Fruits',
    'Vegetables',
    'Natural Pesticides',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prods = await MarketplaceService.instance.getProducts(
      category: _selectedCategory,
      naturalOnly: _certifiedOnly,
      searchQuery: _searchController.text,
    );
    final ords = await MarketplaceService.instance.getOrders();

    if (!mounted) return;
    setState(() {
      _products = prods;
      _orders = ords;
      _isLoading = false;
    });
  }

  void _openOrderDialog(MarketplaceProduct prod) {
    double qty = 1.0;
    String paymentMethod = 'UPI QR Code';
    final addrController = TextEditingController(
      text: '${widget.profile.effectiveVillage}, ${widget.profile.effectiveDistrict}, ${widget.profile.effectiveState}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = qty * prod.price;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(prod.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 4),
                    Text('Seller: ${prod.sellerName} (${prod.location})', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                    const Divider(height: 20),

                    // Quantity Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Quantity (${prod.unit}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF1B5E20)),
                              onPressed: qty > 1 ? () => setSheetState(() => qty--) : null,
                            ),
                            Text(
                              qty.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
                              onPressed: qty < prod.stockQuantity ? () => setSheetState(() => qty++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Delivery Address
                    const Text('Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addrController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Selection
                    const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 16),
                                SizedBox(width: 4),
                                Text('UPI QR Code'),
                              ],
                            ),
                            selected: paymentMethod == 'UPI QR Code',
                            selectedColor: const Color(0xFFE8F5E9),
                            onSelected: (_) => setSheetState(() => paymentMethod = 'UPI QR Code'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 16),
                                SizedBox(width: 4),
                                Text('Cash on Delivery'),
                              ],
                            ),
                            selected: paymentMethod == 'Cash on Delivery',
                            selectedColor: const Color(0xFFE8F5E9),
                            onSelected: (_) => setSheetState(() => paymentMethod = 'Cash on Delivery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Calculation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Payable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Confirm Order Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final order = await MarketplaceService.instance.placeOrder(
                          productId: prod.id,
                          productTitle: prod.title,
                          buyerName: widget.profile.fullName.isNotEmpty ? widget.profile.fullName : 'Farmer Buyer',
                          buyerPhone: widget.profile.mobileNumber,
                          deliveryAddress: addrController.text,
                          quantity: qty,
                          unit: prod.unit,
                          unitPrice: prod.price,
                          paymentMethod: paymentMethod,
                        );

                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        _loadData();
                        _showOrderSuccessDialog(order, paymentMethod);
                      },
                      child: Text('Confirm Order (₹${total.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderSuccessDialog(MarketplaceOrder order, String paymentMethod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 8),
            Text('Order Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Item: ${order.productTitle} (${order.quantity} ${order.unit})'),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(0)}'),
            Text('Payment: $paymentMethod'),
            const SizedBox(height: 12),
            if (paymentMethod == 'UPI QR Code') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_rounded, size: 36, color: Color(0xFF1B5E20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'BHIM / GooglePay / PhonePe UPI transaction verified. Seller will dispatch item within 24 hours.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAddProductSheet() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Bio-Fertilizers & Jeevamrut';
    String unit = 'kg';
    bool isCertified = true;
    String badge = 'Jaivik Bharat / PGS-India';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('List Natural Farming Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 12),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Product Name / Title',
                        hintText: 'e.g. Desi Cow Jeevamrut, Organic Wheat',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price (₹)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: unit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['kg', 'Quintal', 'Litre', 'Bag', 'Packet'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) => setSheetState(() => unit = v ?? 'kg'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Available Stock Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text('Verified Natural Farming Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(badge, style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      value: isCertified,
                      activeThumbColor: const Color(0xFF1B5E20),
                      onChanged: (v) => setSheetState(() => isCertified = v),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Brief Description & Certification Details',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

                        final newProd = MarketplaceProduct(
                          id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          category: category,
                          sellerId: widget.profile.firebaseUid ?? 'default_seller',
                          sellerName: widget.profile.fullName.isNotEmpty ? widget.profile.fullName : 'Local Farmer',
                          sellerPhone: widget.profile.mobileNumber,
                          location: '${widget.profile.effectiveDistrict}, ${widget.profile.effectiveState}',
                          price: double.tryParse(priceCtrl.text) ?? 100.0,
                          unit: unit,
                          stockQuantity: double.tryParse(qtyCtrl.text) ?? 10.0,
                          isCertifiedNatural: isCertified,
                          certificationBadge: isCertified ? badge : 'Unverified Natural',
                          description: descCtrl.text.trim(),
                        );

                        await MarketplaceService.instance.addProduct(newProd);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Natural product listed successfully!'), backgroundColor: Color(0xFF1B5E20)),
                        );
                      },
                      child: const Text('Publish Product Listing', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Natural Farming Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9933),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Browse & Buy', icon: Icon(Icons.storefront_rounded, size: 20)),
            Tab(text: 'Seller Hub & Orders (${_orders.length})', icon: const Icon(Icons.inventory_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Buyer Catalog
          _buildBuyerCatalog(),

          // Tab 2: Seller Hub & Orders
          _buildSellerHub(),
        ],
      ),
    );
  }

  Widget _buildBuyerCatalog() {
    return Column(
      children: [
        // Top Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => _loadData(),
                decoration: InputDecoration(
                  hintText: 'Search natural crops, Jeevamrut, bio-pesticides...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B5E20)),
                  filled: true,
                  fillColor: const Color(0xFFF9FBF9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Certified Natural Only:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Switch(
                    value: _certifiedOnly,
                    activeThumbColor: const Color(0xFF1B5E20),
                    onChanged: (val) {
                      setState(() => _certifiedOnly = val);
                      _loadData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Category Filter
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
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF424242),
                      ),
                    ),
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: const Color(0xFFF1F5F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _loadData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Products List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text('No natural products match your search', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _products.length,
                      itemBuilder: (context, i) {
                        final p = _products[i];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE8F5E9)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (p.isCertifiedNatural)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF81C784)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF2E7D32)),
                                            const SizedBox(width: 4),
                                            Text(
                                              p.certificationBadge,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      'Stock: ${p.stockQuantity} ${p.unit}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  p.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.description,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF616161), height: 1.3),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '₹${p.price.toStringAsFixed(0)} / ${p.unit}',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                        ),
                                        Text(
                                          'By ${p.sellerName} (${p.location})',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B5E20),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                                      label: const Text('Order Now'),
                                      onPressed: () => _openOrderDialog(p),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSellerHub() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seller Action Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Natural Farmer Seller Hub',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sell your certified natural harvest, cow-based bio-inputs, and seeds directly to buyers.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _openAddProductSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Customer Orders & Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
          const SizedBox(height: 10),

          if (_orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No orders placed yet. Products you order will appear here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
            )
          else
            ..._orders.map(
              (o) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: Text(o.orderStatus, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(o.productTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Quantity: ${o.quantity} ${o.unit} • Total: ₹${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF424242))),
                      const SizedBox(height: 4),
                      Text('Payment: ${o.paymentMethod} (${o.paymentStatus})', style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
