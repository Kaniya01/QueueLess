// lib/screens/admin/admin_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';
import '../login_screen.dart';
import 'admin_menu_manager.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription _newOrderSub;
  int _newOrderCount = 0;

  // Filter
  String _statusFilter = 'active'; // 'active' | 'all' | 'completed'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenForNewOrders();
  }

  void _listenForNewOrders() {
    bool firstLoad = true;
    _newOrderSub = FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .snapshots()
        .listen((snapshot) {
      if (firstLoad) {
        firstLoad = false;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          setState(() => _newOrderCount++);
          if (mounted) {
            NotificationService.showLocalNotification(
              context,
              '🔔 New order received! Token #${change.doc['token']}',
              color: Colors.deepOrange,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _newOrderSub.cancel();
    _tabController.dispose();
    super.dispose();
  }

Stream<QuerySnapshot> _getOrdersStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .orderBy('time', descending: true)
        .snapshots();
  }

  Color _statusColor(String status) {
    return switch (status) {
      'waiting' => Colors.orange,
      'preparing' => Colors.blue,
      'ready' => Colors.green,
      'completed' => Colors.grey,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'waiting' => Icons.schedule,
      'preparing' => Icons.restaurant,
      'ready' => Icons.check_circle,
      'completed' => Icons.done_all,
      'cancelled' => Icons.cancel,
      _ => Icons.help,
    };
  }

  Widget _buildOrderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'waiting';
    final items = Map<String, dynamic>.from(data['items'] ?? {});
    final token = data['token'];
    final total = data['total'];
    final user = data['user'] ?? 'Unknown';
    final note = data['note'];
    final time = data['time'] as Timestamp?;

    final isActive = status == 'waiting' || status == 'preparing';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _statusColor(status).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Token #$token',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // User
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),

            const SizedBox(height: 6),
            const SizedBox(height: 2),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Items
            ...items.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 8, color: Colors.deepOrange),
                      const SizedBox(width: 6),
                      Text(e.key, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text('x${e.value}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )),

            if (note != null && note.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_outlined, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Note: $note',
                        style: const TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '₹$total',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const Spacer(),
                if (time != null)
                  Text(
                    _formatTime(time.toDate()),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),

            // Action buttons
            if (isActive) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (status == 'waiting')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => OrderService.updateStatus(
                          doc.id, AppConstants.statusPreparing),
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Start Preparing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (status == 'waiting') const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => OrderService.updateStatus(
                        doc.id, AppConstants.statusReady),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (status == 'ready') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => OrderService.updateStatus(
                    doc.id, AppConstants.statusCompleted),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark Completed (Picked Up)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Stats bar
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.ordersCollection)
              .snapshots(),
          builder: (context, snap) {
            int waiting = 0, preparing = 0, ready = 0;
            if (snap.hasData) {
              for (var d in snap.data!.docs) {
                final s = (d.data() as Map)['status'];
                if (s == 'waiting') waiting++;
                if (s == 'preparing') preparing++;
                if (s == 'ready') ready++;
              }
            }
            return Container(
              padding: const EdgeInsets.all(12),
              color: Colors.deepOrange.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip('Waiting', waiting, Colors.orange),
                  _statChip('Preparing', preparing, Colors.blue),
                  _statChip('Ready', ready, Colors.green),
                ],
              ),
            );
          },
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip('Active', 'active'),
              const SizedBox(width: 8),
              _filterChip('All', 'all'),
              const SizedBox(width: 8),
              _filterChip('Done', 'completed'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              final filtered = switch (_statusFilter) {
                    'active' => docs.where((d) {
                        final s = (d.data() as Map)['status'];
                        return s == 'waiting' || s == 'preparing';
                      }).toList(),
                    'completed' => docs.where((d) {
                        final s = (d.data() as Map)['status'];
                        return s == 'ready' || s == 'completed' || s == 'cancelled';
                      }).toList(),
                    _ => docs,
                  };

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _statusFilter == 'active'
                            ? 'No active orders 🎉'
                            : 'No orders found',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildOrderCard(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Admin Panel'),
            if (_newOrderCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_newOrderCount new',
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Orders'),
            Tab(icon: Icon(Icons.menu_book), text: 'Menu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          const AdminMenuManager(),
        ],
      ),
    );
  }
}