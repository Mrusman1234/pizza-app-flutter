import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/firestore_constants.dart';

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  StreamSubscription? _ordersSubscription;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderModel? get activeOrder {
    if (_orders.isEmpty) return null;
    // Return the first order that is not delivered or cancelled
    try {
      return _orders.firstWhere((order) => 
        order.status != FirestoreConstants.statusDelivered && 
        order.status != FirestoreConstants.statusCancelled
      );
    } catch (_) {
      return null;
    }
  }

  void fetchOrders(String userId) {
    _ordersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = _firestoreService.getOrders(userId).listen(
      (data) {
        _orders = data.map((item) => OrderModel.fromMap(item)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
