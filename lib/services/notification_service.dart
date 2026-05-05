import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class NotificationService {
  static void showLocalNotification(BuildContext context, String message,
      {Color color = Colors.deepOrange}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Stream<QuerySnapshot> studentOrderUpdates(String email) {
    return FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .where('user', isEqualTo: email)
        .where('status', whereIn: [
          AppConstants.statusPreparing,
          AppConstants.statusReady,
        ])
        .snapshots();
  }

  static Stream<QuerySnapshot> newOrdersStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: AppConstants.statusWaiting)
        .snapshots();
  }

  static Future<void> initialize(BuildContext context) async {}
}
