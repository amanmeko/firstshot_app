import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'listproducts.dart'; // Import Product class

class ProductCheckoutPage extends StatefulWidget {
  const ProductCheckoutPage({super.key});

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  int _selectedIndex = 2;
  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis,
    Icons.settings,
  ];

  void _navigate(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/booking');
        break;
      case 1:
        Navigator.pushNamed(context, '/coaching');
        break;
      case 2:
        Navigator.pushNamed(context, '/main');
        break;
      case 3:
        Navigator.pushNamed(context, '/instructors');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve selected products from arguments
    final Map<Product, int>? selectedProducts =
        ModalRoute.of(context)!.settings.arguments as Map<Product, int>?;

    if (selectedProducts == null || selectedProducts.isEmpty) {
      // Navigate back to ListProductsPage if no products are selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/merchandise');
      });
      return Scaffold(
        // body: Center(child: Text('No products selected, redirecting...')),
      );
    }

    // Calculate prices
    final double adminCharge = 2.00;
    final double subtotal =
        selectedProducts.entries.fold(0, (sum, entry) => sum + entry.key.price * entry.value);
    final double total = subtotal + adminCharge;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: Colors.black,
        height: 65,
        animationDuration: const Duration(milliseconds: 300),
        items: List.generate(_icons.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icons[index],
                color: _selectedIndex == index ? const Color(0xFF4997D0) : Colors.white,
                size: 24,
              ),
              if (_selectedIndex != index)
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _navigate,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                  ),
                  const SizedBox(width: 4),
                  const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),

              // Product Details
              _buildSection("Selected Products", child: _buildProductDetails(context, selectedProducts)),

              // Delivery Address
              _buildSection("Self Collection", child: _buildAddressBox()),

              // Summary
              _buildSection("Order Summary", child: _buildSummary(subtotal, adminCharge, total)),

              const SizedBox(height: 20),
              // Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedProducts.isNotEmpty
                      ? () => _confirmPayment(context, selectedProducts, total)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4997D0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Proceed to Fiuu Payment", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildProductDetails(BuildContext context, Map<Product, int> selectedProducts) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: selectedProducts.entries.map((entry) {
          final product = entry.key;
          final quantity = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => SvgPicture.asset(
                            'assets/images/paddle_m5.svg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/images/paddle_m5.svg',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${product.price.toStringAsFixed(2)} x $quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.stock > 0 ? 'In Stock: ${product.stock}' : 'Out of Stock',
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: quantity > 1
                                ? () {
                                    setState(() {
                                      selectedProducts[product] = quantity - 1;
                                      if (selectedProducts.isEmpty) {
                                        Navigator.pushReplacementNamed(context, '/main');
                                      }
                                    });
                                  }
                                : null,
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: quantity < product.stock
                                ? () {
                                    setState(() {
                                      selectedProducts[product] = quantity + 1;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                selectedProducts.remove(product);
                                if (selectedProducts.isEmpty) {
                                  Navigator.pushReplacementNamed(context, '/main');
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("FirstShot Store", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text("Kuala Lumpur, Malaysia", style: TextStyle(fontSize: 12)),
                TextButton(
                  onPressed: () {
                    // Mock address selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address selection not implemented')),
                    );
                  },
                  child: const Text("Change Address", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double subtotal, double adminCharge, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", "RM ${subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _summaryRow("Admin Charge", "RM ${adminCharge.toStringAsFixed(2)}"),
          const Divider(height: 24),
          _summaryRow("Total", "RM ${total.toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }

  void _confirmPayment(BuildContext context, Map<Product, int> selectedProducts, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text(
          "You are about to purchase ${selectedProducts.entries.length} item(s) for RM ${total.toStringAsFixed(2)} via Fiuu Payment Gateway. Proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // Mock Fiuu payment initiation
              _initiateFiuuPayment(selectedProducts, total);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to Fiuu Payment Gateway...')),
              );
              Navigator.pushReplacementNamed(context, '/main'); // Return to ListProductsPage
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4997D0),
            ),
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  void _initiateFiuuPayment(Map<Product, int> selectedProducts, double total) {
    // Mock Fiuu payment integration
    print('Initiating Fiuu payment for:');
    selectedProducts.forEach((product, quantity) {
      print('${product.name} x $quantity: RM ${(product.price * quantity).toStringAsFixed(2)}');
    });
    print('Total: RM ${total.toStringAsFixed(2)}');
    // Example: Call Fiuu SDK or redirect to payment URL
    // await FiuuSDK.initiatePayment(
    //   merchantId: 'your_merchant_id',
    //   amount: total,
    //   orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
    //   description: 'Purchase from FirstShot Store',
    // );
  }
}