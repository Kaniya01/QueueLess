// lib/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;
  static final _ordersRef = _db.collection(AppConstants.ordersCollection);

  /// Generate a unique token (1–999)
 static Future<int> _getDailyToken() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    final counterRef = _db.collection('counters').doc(dateKey);

    return await _db.runTransaction((transaction) async {
      final snap = await transaction.get(counterRef);
      int next = 1;
      if (snap.exists) {
        next = (snap.data()!['count'] as int) + 1;
      }
      transaction.set(counterRef, {'count': next, 'date': dateKey});
      return next;
    });
  }

  /// Place a new order — returns token + Firestore doc id (tokens repeat daily).
  static Future<({int token, String orderId})> placeOrder({
    required Map<String, int> cart,
    required List<Map<String, dynamic>> menu,
    String? note,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await _getDailyToken();

    int total = 0;
    cart.forEach((itemName, qty) {
      final food = menu.firstWhere(
        (f) => f['name'] == itemName,
        orElse: () => {'price': 0},
      );
      total += (food['price'] as int) * qty;
    });

    final ref = await _ordersRef.add({
      'items': cart,
      'total': total,
      'token': token,
      'status': AppConstants.statusWaiting,
      'time': FieldValue.serverTimestamp(),
      'user': user.email!,
      if (note != null && note.isNotEmpty) 'note': note,
    });

    return (token: token, orderId: ref.id);
  }

  /// Stream of all orders ordered by time (admin)
  static Stream<QuerySnapshot> allOrdersStream() {
    return _ordersRef.orderBy('time').snapshots();
  }

  /// Stream of orders for specific user, most recent first
  static Stream<QuerySnapshot> userOrdersStream(String email) {
    return _ordersRef
        .where('user', isEqualTo: email)
        .orderBy('time', descending: true)
        .snapshots();
  }

  /// Stream of active orders (waiting + preparing) for queue display
  static Stream<QuerySnapshot> activeOrdersStream() {
    return _ordersRef.orderBy('time').snapshots();
  }

  /// Update order status
  static Future<void> updateStatus(String orderId, String status) async {
    await _ordersRef.doc(orderId).update({'status': status});
  }

  /// Cancel an order (only if still waiting)
  static Future<bool> cancelOrder(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    if (data['status'] != AppConstants.statusWaiting) return false;
    await _ordersRef.doc(orderId).update({
      'status': AppConstants.statusCancelled,
    });
    return true;
  }

  static bool _isActiveStatus(dynamic s) {
    return s == AppConstants.statusWaiting || s == AppConstants.statusPreparing;
  }

  static int _timeMs(Map<String, dynamic> data) {
    final t = data['time'];
    if (t is Timestamp) return t.millisecondsSinceEpoch;
    return 0;
  }

  static int _tokenVal(Map<String, dynamic> data) {
    final v = data['token'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  /// Waiting + preparing orders, sorted by kitchen queue order (oldest first).
  static List<QueryDocumentSnapshot> activeOrdersSorted(
    List<QueryDocumentSnapshot> docs,
  ) {
    final active = docs.where((d) {
      final s = (d.data() as Map<String, dynamic>)['status'];
      return _isActiveStatus(s);
    }).toList();
    active.sort((a, b) {
      final ma = a.data() as Map<String, dynamic>;
      final mb = b.data() as Map<String, dynamic>;
      final c = _timeMs(ma).compareTo(_timeMs(mb));
      if (c != 0) return c;
      return _tokenVal(ma).compareTo(_tokenVal(mb));
    });
    return active;
  }

  /// Get queue position for a token (0 = next, -1 = not found)
  static int getQueuePosition(List<QueryDocumentSnapshot> docs, int token) {
    final active = activeOrdersSorted(docs);
    return active.indexWhere((d) => _tokenVal(d.data() as Map<String, dynamic>) == token);
  }

  /// Position in active queue by order document id (avoids duplicate daily tokens).
  static int getQueuePositionByOrderId(
    List<QueryDocumentSnapshot> docs,
    String orderId,
  ) {
    final active = activeOrdersSorted(docs);
    return active.indexWhere((d) => d.id == orderId);
  }

  /// Estimated wait time in minutes (2 min per order ahead)
  static int estimatedWait(int position) {
    return position * 2;
  }
}