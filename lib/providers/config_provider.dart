import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_config_model.dart';
import '../core/constants/firestore_constants.dart';

class ConfigProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppConfigModel? _config;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _sub;

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ConfigProvider() {
    _listenToConfig();
  }

  void _listenToConfig() {
    _sub?.cancel();
    _sub = _db
        .collection(FirestoreConstants.appConfig)
        .doc('settings')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _config = AppConfigModel.fromMap(snapshot.data()!);
      } else {
        // Initialize with defaults if not exists
        _config = AppConfigModel.fromMap({});
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateConfig(AppConfigModel newConfig) async {
    try {
      await _db
          .collection(FirestoreConstants.appConfig)
          .doc('settings')
          .set(newConfig.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating config: $e');
      rethrow;
    }
  }

  Future<void> resetToDefaults() async {
    final defaults = AppConfigModel.fromMap({});
    await updateConfig(defaults);
  }

  // Helper getters for easy access
  String get appName => _config?.appName ?? 'Pizza Hub Vehari';
  String get supportEmail => _config?.supportEmail ?? 'support@pizzahubvehari.com';
  String get supportPhone => _config?.supportPhone ?? '+92 300 0000000';
  String get supportWhatsApp => _config?.supportWhatsApp ?? '+92 300 0000000';
  double get defaultCommission => _config?.defaultCommission ?? 10.0;
  double get minOrderAmount => _config?.minOrderAmount ?? 200.0;
  double get baseDeliveryFee => _config?.baseDeliveryFee ?? 50.0;
  double get taxRate => _config?.taxRate ?? 0.05;
  bool get maintenanceMode => _config?.maintenanceMode ?? false;
  bool get ordersEnabled => _config?.ordersEnabled ?? true;
  bool get notificationsEnabled => _config?.notificationsEnabled ?? true;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
