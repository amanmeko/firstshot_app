import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Product {
  final int id;
  final String productId;
  final String name;
  final int categoryId;
  final String? imagePath;
  final double price;
  final int stock;
  final String description;
  final String createdAt;
  final String updatedAt;
  final Category category;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.categoryId,
    this.imagePath,
    required this.price,
    required this.stock,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      categoryId: json['category_id'],
      imagePath: json['image_path'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      description: json['description'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      category: Category.fromJson(json['category']),
    );
  }

  String? get imageUrl {
    return imagePath != null ? 'https://firstshot.my/public/storage/$imagePath' : null;
  }
}

class Category {
  final int id;
  final String name;
  final String description;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ListProductsPage extends StatefulWidget {
  const ListProductsPage({super.key});

  @override
  State<ListProductsPage> createState() => _ListProductsPageState();
}

class _ListProductsPageState extends State<ListProductsPage> {
  int _selectedIndex = 2;
  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis,
    Icons.settings,
  ];

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];
  String? selectedCategory;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int lastPage = 1;
  final storage = FlutterSecureStorage();
  Map<Product, int> selectedProducts = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where((product) => product.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _fetchProducts({String? category, String? searchQuery, int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? token = await storage.read(key: 'auth_token');
      final queryParameters = {
        if (category != null) 'category': category,
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        'page': page.toString(),
      };
      final uri = Uri.parse('https://firstshot.my/api/auth/products')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            products = (jsonData['products']['data'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
            filteredProducts = products;
            if (_searchController.text.isNotEmpty) {
              _onSearchChanged();
            }
            categories = (jsonData['categories'] as List)
                .map((json) => Category.fromJson(json))
                .toList();
            currentPage = jsonData['products']['current_page'];
            lastPage = jsonData['products']['last_page'];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = jsonData['message'] ?? 'Failed to load products';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load products: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

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

  void _proceedToCheckout() {
    if (selectedProducts.isNotEmpty) {
      Navigator.pushNamed(context, '/productcheckout', arguments: selectedProducts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _proceedToCheckout,
        backgroundColor: const Color(0xFF4997D0),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(Icons.shopping_cart_checkout, color: Colors.white),
            if (selectedProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  selectedProducts.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Back and Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.more_horiz, color: Colors.black87, size: 20),
                  ),
                ],
              ),
            ),

            // Category Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  hint: const Text('Select Category', style: TextStyle(color: Colors.grey)),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All', style: TextStyle(color: Colors.black87)),
                    ),
                    ...categories.map((category) => DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(category.name, style: const TextStyle(color: Colors.black87)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                    _fetchProducts(category: value, searchQuery: _searchController.text.trim());
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid of products
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4997D0)))
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                      : filteredProducts.isEmpty
                          ? const Center(child: Text('No products found', style: TextStyle(color: Colors.grey)))
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _buildProductCard(context, filteredProducts[index]),
                            ),
            ),

            // Pagination
            if (!isLoading && filteredProducts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (currentPage > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF4997D0)),
                        onPressed: () => _fetchProducts(
                          category: selectedCategory,
                          searchQuery: _searchController.text.trim(),
                          page: currentPage - 1,
                        ),
                      ),
                    Text('Page $currentPage of $lastPage', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (currentPage < lastPage)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF4997D0)),
                        onPressed: () => _fetchProducts(
                          category: selectedCategory,
                          searchQuery: _searchController.text.trim(),
                          page: currentPage + 1,
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

  Widget _buildProductCard(BuildContext context, Product product) {
    final quantity = selectedProducts[product] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => SvgPicture.asset(
                        'assets/images/paddle_m5.svg',
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/images/paddle_m5.svg',
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF4997D0)),
                ),
                const SizedBox(height: 4),
                Text(
                  product.stock > 0 ? 'In Stock: ${product.stock}' : 'Out of Stock',
                  style: TextStyle(
                    color: product.stock > 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFF4997D0)),
                          onPressed: quantity > 0
                              ? () {
                                  setState(() {
                                    selectedProducts[product] = quantity - 1;
                                    if (selectedProducts[product] == 0) {
                                      selectedProducts.remove(product);
                                    }
                                  });
                                }
                              : null,
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF4997D0)),
                          onPressed: quantity < product.stock
                              ? () {
                                  setState(() {
                                    selectedProducts[product] = quantity + 1;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: product.stock > 0
                          ? () {
                              setState(() {
                                selectedProducts[product] = (selectedProducts[product] ?? 0) + 1;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4997D0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}