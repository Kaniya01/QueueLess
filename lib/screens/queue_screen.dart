// lib/screens/queue_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';

class QueueScreen extends StatefulWidget {
  final int token;
  /// When set, tracks this exact order (fixes duplicate token numbers across days).
  final String? orderId;

  const QueueScreen({super.key, required this.token, this.orderId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String? _lastStatus;

  /// Prefer [orderId]; else newest doc matching token + signed-in user (tokens repeat daily).
  int _resolveOrderIndex(List<QueryDocumentSnapshot> docs) {
    final oid = widget.orderId;
    if (oid != null && oid.isNotEmpty) {
      return docs.indexWhere((d) => d.id == oid);
    }
    final email = FirebaseAuth.instance.currentUser?.email;
    for (var i = docs.length - 1; i >= 0; i--) {
      final data = docs[i].data() as Map<String, dynamic>;
      if (data['token'] == widget.token &&
          (email == null || data['user'] == email)) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.ordersCollection)
            .orderBy('time')
            .snapshots(),
        builder: (context, snapshot) {
          // Only block UI before first snapshot; later updates stay visible (real-time).
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Unable to load queue'));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Order not found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Token #${widget.token}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orderIndex = _resolveOrderIndex(docs);

          if (orderIndex == -1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Order not found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Token #${widget.token}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orderData = docs[orderIndex].data() as Map<String, dynamic>;
          final status = orderData['status'] as String? ?? 'waiting';
          final items = Map<String, dynamic>.from(orderData['items'] ?? {});
          final total = orderData['total'] ?? 0;

          // Notify on status change
          if (_lastStatus != null && _lastStatus != status) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (status == 'ready') {
                NotificationService.showLocalNotification(
                  context,
                  '🔔 Your order #${widget.token} is READY for pickup!',
                  color: Colors.green,
                );
              } else if (status == 'preparing') {
                NotificationService.showLocalNotification(
                  context,
                  '👨‍🍳 Your order is being prepared!',
                  color: Colors.blue,
                );
              }
            });
          }
          _lastStatus = status;

          // Queue position (among active orders)
          final isActive = status == AppConstants.statusWaiting ||
              status == AppConstants.statusPreparing;
          final oid = widget.orderId;
          final rawPosition = isActive
              ? (oid != null && oid.isNotEmpty)
                  ? OrderService.getQueuePositionByOrderId(docs, oid)
                  : OrderService.getQueuePosition(docs, widget.token)
              : -1;
          final position = rawPosition < 0 ? 0 : rawPosition;
          final eta = isActive ? OrderService.estimatedWait(position) : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status card
                _buildStatusCard(status),

                const SizedBox(height: 20),

                // Token display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepOrange, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR TOKEN',
                        style: TextStyle(color: Colors.white70, letterSpacing: 2),
                      ),
                      Text(
                        '#${widget.token}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Queue info row
                if (status != AppConstants.statusReady &&
                    status != AppConstants.statusCompleted)
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          '${position > 0 ? position : 0}',
                          'People Ahead',
                          Icons.people_outline,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          '~$eta min',
                          'Est. Wait',
                          Icons.timer_outlined,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                if (status == AppConstants.statusReady) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 50),
                        SizedBox(height: 8),
                        Text(
                          'Your Order is Ready! 🎉',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please collect from the counter',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Order summary card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(height: 16),
                        ...items.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record,
                                    size: 8, color: Colors.deepOrange),
                                const SizedBox(width: 8),
                                Text(e.key),
                                const Spacer(),
                                Text('x${e.value}',
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '₹$total',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Status timeline
                _buildTimeline(status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    final config = switch (status) {
      'waiting' => (
          icon: Icons.schedule,
          color: Colors.orange,
          label: 'Waiting',
          subtitle: 'Your order is in queue',
        ),
      'preparing' => (
          icon: Icons.restaurant,
          color: Colors.blue,
          label: 'Preparing',
          subtitle: 'Kitchen is preparing your order',
        ),
      'ready' => (
          icon: Icons.check_circle,
          color: Colors.green,
          label: 'Ready!',
          subtitle: 'Collect from the counter',
        ),
      'completed' => (
          icon: Icons.done_all,
          color: Colors.grey,
          label: 'Completed',
          subtitle: 'Enjoy your meal!',
        ),
      _ => (
          icon: Icons.info,
          color: Colors.grey,
          label: status,
          subtitle: '',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.label,
                style: TextStyle(
                  color: config.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(config.subtitle,
                  style: TextStyle(color: config.color.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      ('Order Placed', AppConstants.statusWaiting, Icons.receipt_long),
      ('Preparing', AppConstants.statusPreparing, Icons.restaurant),
      ('Ready', AppConstants.statusReady, Icons.check_circle),
    ];

    final order = [
      AppConstants.statusWaiting,
      AppConstants.statusPreparing,
      AppConstants.statusReady,
      AppConstants.statusCompleted,
    ];
    final currentIndex = order.indexOf(currentStatus);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final stepIndex = order.indexOf(step.$2);
              final isDone = currentIndex >= stepIndex;
              final isCurrent = currentIndex == stepIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDone ? Colors.deepOrange : Colors.grey.shade200,
                        child: Icon(
                          step.$3,
                          size: 16,
                          color: isDone ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 30,
                          color: isDone && currentIndex > stepIndex
                              ? Colors.deepOrange
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isDone ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.deepOrange.shade300,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}