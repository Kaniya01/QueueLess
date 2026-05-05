// lib/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String user;
  final Map<String, int> items;
  final int total;
  final int token;
  final String status;
  final Timestamp time;
  final String? note;

  OrderModel({
    required this.id,
    required this.user,
    required this.items,
    required this.total,
    required this.token,
    required this.status,
    required this.time,
    this.note,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      user: data['user'] ?? '',
      items: Map<String, int>.from(data['items'] ?? {}),
      total: data['total'] ?? 0,
      token: data['token'] ?? 0,
      status: data['status'] ?? 'waiting',
      time: data['time'] ?? Timestamp.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'items': items,
      'total': total,
      'token': token,
      'status': status,
      'time': time,
      if (note != null) 'note': note,
    };
  }

  String get itemsSummary {
    return items.entries.map((e) => '${e.key} x${e.value}').join(', ');
  }

  bool get isWaiting => status == 'waiting';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isActive => isWaiting || isPreparing;
}