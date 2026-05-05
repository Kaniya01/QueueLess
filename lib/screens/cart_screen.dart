// lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import 'token_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cart;
  final VoidCallback? onOrderPlaced; // callback to reset parent cart
  final List<Map<String, dynamic>>? menuItems;

  const CartScreen({
    super.key,
    required this.cart,
    this.onOrderPlaced,
    this.menuItems,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> _cart;
  List<Map<String, dynamic>> _menu = List<Map<String, dynamic>>.from(AppConstants.defaultMenu);
  final _noteController = TextEditingController();
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.cart);
    _loadMenu();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    if (widget.menuItems != null && widget.menuItems!.isNotEmpty) {
      setState(() => _menu = widget.menuItems!);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.menuCollection)
          .get();
      if (!mounted) return;
      setState(() {
        _menu = snap.docs.isEmpty
            ? List<Map<String, dynamic>>.from(AppConstants.defaultMenu)
            : snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menu = List<Map<String, dynamic>>.from(AppConstants.defaultMenu);
      });
    }
  }

  int get _total {
    int t = 0;
    _cart.forEach((name, qty) {
      final food = _menu.firstWhere(
        (f) => f['name'] == name,
        orElse: () => {'price': 0},
      );
      t += (food['price'] as int) * qty;
    });
    return t;
  }

  int _itemPrice(String name) {
    final food = _menu.firstWhere(
      (f) => f['name'] == name,
      orElse: () => {'price': 0},
    );
    return food['price'] as int;
  }

  void _increase(String name) => setState(() => _cart[name] = (_cart[name] ?? 0) + 1);

  void _decrease(String name) {
    setState(() {
      if ((_cart[name] ?? 0) > 1) {
        _cart[name] = _cart[name]! - 1;
      } else {
        _cart.remove(name);
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _isPlacing = true);

    try {
      final placed = await OrderService.placeOrder(
        cart: _cart,
        menu: _menu,
        note: _noteController.text.trim(),
      );

      widget.onOrderPlaced?.call();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TokenScreen(
            token: placed.token,
            orderId: placed.orderId,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Permission denied while placing order. Check Firestore rules.'
          : 'Error placing order: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: _cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Browse Menu'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              Text(
                                user?.email ?? 'Guest',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Order Items',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),

                        // Cart items
                        ..._cart.entries.map((entry) {
                          final price = _itemPrice(entry.key);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '₹$price each',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline,
                                            color: Colors.deepOrange),
                                        onPressed: () => _decrease(entry.key),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      ),
                                      Text(
                                        '${entry.value}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline,
                                            color: Colors.deepOrange),
                                        onPressed: () => _increase(entry.key),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '₹${price * entry.value}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Special note
                        const Text(
                          'Special Instructions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Any special requests? (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.note_outlined),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bill summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Bill Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              ..._cart.entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Text('${e.key} x${e.value}'),
                                        const Spacer(),
                                        Text('₹${_itemPrice(e.key) * e.value}'),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹$_total',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Place order button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isPlacing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isPlacing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Place Order • ₹$_total',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}