import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderReadyScreen extends StatefulWidget {
  const OrderReadyScreen({super.key});

  @override
  State<OrderReadyScreen> createState() => _OrderReadyScreenState();
}

class _OrderReadyScreenState extends State<OrderReadyScreen> {

  bool notified = false;

  void showNotification(int token) {

    if (notified) return;

    notified = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(
          "🔔 Order Ready! Token $token is ready for pickup.",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Status"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('time', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          for (var order in orders) {

            if (order['status'] == 'ready') {

              int token = order['token'];

              Future.microtask(() => showNotification(token));

            }

          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {

              var order = orders[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
  (order['items'] as Map).entries
      .map((e) => "${e.key} x${e.value}")
      .join(", "),
),
                  subtitle: Text("Token: ${order['token']}"),
                  trailing: Text(
                    order['status'],
                    style: TextStyle(
                      color: order['status'] == "ready"
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );

        },
      ),
    );
  }
}