import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/rider_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class RiderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  List<RiderModel> _riders = [];
  bool _isLoading = false;
  bool _isTracking = false;
  RiderModel? _currentRider;

  List<RiderModel> get riders => _riders;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  RiderModel? get currentRider => _currentRider;

  void listenToCurrentRider(String riderId) {
    _firestoreService.getRiderById(riderId).listen((data) {
      if (data != null) {
        _currentRider = RiderModel.fromMap(data);
        notifyListeners();
      }
    });
  }

  void fetchRiders(String adminId) {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getRiders(adminId: adminId).listen((data) {
      _riders = data.map((item) => RiderModel.fromMap(item)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> startLocationUpdates(String riderId) async {
    if (_isTracking) return;

    final hasPermission = await _locationService.requestPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    notifyListeners();

    _locationService.startTracking((Position position) {
      _firestoreService.updateRiderLocation(
        riderId,
        position.latitude,
        position.longitude,
      );
    });
  }

  void stopLocationUpdates() {
    _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }

  Future<void> addRider(RiderModel rider) async {
    await _firestoreService.addRider(rider.toMap());
  }

  Future<void> updateRider(RiderModel rider) async {
    await _firestoreService.updateRider(rider.id, rider.toMap());
  }

  Future<void> deleteRider(String riderId) async {
    await _firestoreService.deleteRider(riderId);
  }
}
