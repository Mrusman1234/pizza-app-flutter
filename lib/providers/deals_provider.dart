import 'dart:async';
import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../services/firestore_service.dart';

class DealsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<DealModel> _deals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _dealsSubscription;

  List<DealModel> get deals => _deals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void fetchDeals() {
    _dealsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _dealsSubscription = _firestoreService.getDeals().listen(
      (data) {
        _deals = data.map((item) => DealModel.fromMap(item, item['id'])).toList();
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
    _dealsSubscription?.cancel();
    super.dispose();
  }
}
