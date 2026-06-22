import 'dart:async';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/firestore_service.dart';

class WalletProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = false;

  StreamSubscription? _walletSub;
  StreamSubscription? _txnSub;

  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  void listenToWallet(String id) {
    if (id.isEmpty) return;
    _isLoading = true;
    
    _walletSub?.cancel();
    _walletSub = _firestoreService.getWallet(id).listen((data) {
      if (data != null) {
        _wallet = WalletModel.fromMap(id, data);
        notifyListeners();
      }
      _isLoading = false;
    });

    _txnSub?.cancel();
    _txnSub = _firestoreService.getWalletTransactions(id).listen((data) {
      _transactions = data.map((t) => WalletTransactionModel.fromMap(t['id'], t)).toList();
      notifyListeners();
    });
  }

  Future<void> requestWithdrawal({
    required String id,
    required double amount,
    required String method,
    required String details,
  }) async {
    try {
      await _firestoreService.requestWithdrawal(id, amount, method, details);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _txnSub?.cancel();
    super.dispose();
  }
}
