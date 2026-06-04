import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectionProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectionProvider() {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // results is a list because a device can be connected to multiple networks (wifi + mobile)
    // If any of the results is not 'none', we consider the device online.
    _isOnline = !results.contains(ConnectivityResult.none);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
