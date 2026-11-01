import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Farmer Marketplace for selling farm produce directly to traders & mills.
class SellProductsPage extends StatefulWidget {
  final FarmerProfile profile;

  const SellProductsPage({super.key, required this.profile});

  @override
  State<SellProductsPage> createState() => _SellProductsPageState();
}

class _SellProductsPageState extends State<SellProductsPage> {
  final _qtyController = TextEditingController();
  final _expectedPriceController = TextEditingController();
  String? _selectedCrop;

  @override
  void initState() {
    super.initState();
    if (widget.profile.effectiveProducts.isNotEmpty) {
      _selectedCrop = widget.profile.effectiveProducts.first;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _expectedPriceController.dispose();
    super.dispose();
  }

  void _submitListing() {
    if (_selectedCrop == null || _qtyController.text.isEmpty || _expectedPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all listing details to connect with buyers.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Listing Created!'),
          ],
        ),
        content: Text(
          'Your listing for ${_qtyController.text} Quintals of $_selectedCrop at ₹${_expectedPriceController.text}/Q has been broadcasted to verified APMC traders in ${widget.profile.effectiveDistrict}.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final crops = widget.profile.effectiveProducts.isNotEmpty
        ? widget.profile.effectiveProducts
        : ['Wheat', 'Paddy (Rice)', 'Cotton', 'Tomato'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.sellFarmProductsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sell Produce Directly (No Middlemen)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect with verified buyers across ${widget.profile.effectiveState}.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 16),

                  // Crop Selector
                  const Text('Select Produce', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCrop,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF9FBF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCrop = v),
                  ),

                  const SizedBox(height: 14),

                  // Quantity
                  const Text('Available Quantity (Quintals)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 50 Quintals',
                      filled: true,
                      fillColor: const Color(0xFFF9FBF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Expected Price
                  const Text('Expected Price (₹ per Quintal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _expectedPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'e.g. 2400',
                      filled: true,
                      fillColor: const Color(0xFFF9FBF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitListing,
                      child: const Text('Post Produce Listing →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
