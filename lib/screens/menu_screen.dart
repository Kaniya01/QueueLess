import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import '../utils/constants.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, int> _cart = {};
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late Stream<QuerySnapshot> _menuStream;
  List<Map<String, dynamic>> _latestMenuItems = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _menuStream = FirebaseFirestore.instance
        .collection(AppConstants.menuCollection)
        .snapshots();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetCart() {
    setState(() => _cart = {});
  }

  void _addItem(String item) {
    setState(() => _cart[item] = (_cart[item] ?? 0) + 1);
  }

  void _removeItem(String item) {
    setState(() {
      if ((_cart[item] ?? 0) > 1) {
        _cart[item] = _cart[item]! - 1;
      } else {
        _cart.remove(item);
      }
    });
  }

  int get _cartTotal => _cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        cart: Map.from(_cart),
                        onOrderPlaced: _resetCart,
                        menuItems: _latestMenuItems.isNotEmpty
                            ? List<Map<String, dynamic>>.from(_latestMenuItems)
                            : null,
                      ),
                    ),
                  );
                },
              ),
              if (_cartTotal > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartTotal',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            color: Colors.deepOrange,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        (user?.email?.substring(0, 1) ?? 'S').toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hey 👋',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                            user?.email?.split('@').first ?? 'Student',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search food...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = AppConstants.categories[i];
                      final selected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? Colors.deepOrange
                                  : Colors.white,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _menuStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> allItems;
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  allItems = List.from(AppConstants.defaultMenu);
                } else {
                  allItems = snapshot.data!.docs
                      .map((d) => {
                            ...(d.data() as Map<String, dynamic>),
                            'id': d.id
                          })
                      .toList();
                }
                _latestMenuItems =
                    allItems.map((item) => Map<String, dynamic>.from(item)).toList();

                var filtered = allItems.where((item) {
                  final catMatch = _selectedCategory == 'All' ||
                      item['category'] == _selectedCategory;
                  final searchMatch = _searchQuery.isEmpty ||
                      (item['name'] as String)
                          .toLowerCase()
                          .contains(_searchQuery);
                  return catMatch && searchMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          'No items found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  controller: _scrollController,
                  key: const PageStorageKey('menu_grid'),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final name = item['name'] as String;
                    final price = item['price'] as int;
                    final image = item['image'] as String? ?? '';
                    final available = item['available'] as bool? ?? true;
                    final qty = _cart[name] ?? 0;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: image.isNotEmpty
                                  ? Image.network(
                                      image,
                                      height: 90,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        height: 90,
                                        color: Colors.deepOrange
                                            .withOpacity(0.1),
                                        child: const Icon(Icons.restaurant,
                                            size: 40,
                                            color: Colors.deepOrange),
                                      ),
                                      loadingBuilder:
                                          (_, child, progress) =>
                                              progress == null
                                                  ? child
                                                  : Container(
                                                      height: 90,
                                                      color: Colors
                                                          .grey.shade100,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2),
                                                      ),
                                                    ),
                                    )
                                  : Container(
                                      height: 90,
                                      color: Colors.deepOrange
                                          .withOpacity(0.1),
                                      child: const Icon(Icons.restaurant,
                                          size: 40,
                                          color: Colors.deepOrange),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: available
                                    ? Colors.black
                                    : Colors.grey,
                                decoration: available
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            if (!available)
                              Container(
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Not Available',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 11),
                                ),
                              )
                            else if (qty == 0)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _addItem(name),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 18),
                                      onPressed: () => _removeItem(name),
                                      color: Colors.deepOrange,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => _addItem(name),
                                      color: Colors.deepOrange,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _cartTotal > 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      cart: Map.from(_cart),
                      onOrderPlaced: _resetCart,
                      menuItems: _latestMenuItems.isNotEmpty
                          ? List<Map<String, dynamic>>.from(_latestMenuItems)
                          : List<Map<String, dynamic>>.from(AppConstants.defaultMenu),
                    ),
                  ),
                );
              },
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart ($_cartTotal)'),
            )
          : null,
    );
  }
}
