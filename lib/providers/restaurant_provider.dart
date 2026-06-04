import 'dart:async';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../models/pizza_model.dart';
import '../services/firestore_service.dart';
import '../core/utils/location_helper.dart';

class RestaurantProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<RestaurantModel> _restaurants = [];
  Map<String, double> _distances = {};
  bool _isLoading = false;
  StreamSubscription? _restaurantsSubscription;

  String? _error;

  List<RestaurantModel> get restaurants => _restaurants;
  Map<String, double> get distances => _distances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants({String? searchQuery, String? filter, double? userLat, double? userLng}) async {
    await _restaurantsSubscription?.cancel();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _restaurantsSubscription = _firestoreService.getRestaurants(searchQuery: searchQuery, filter: filter).listen(
        (data) {
          _restaurants = data.map((item) => RestaurantModel.fromMap(item)).toList();
          
          if (userLat != null && userLng != null) {
            _calculateDistances(userLat, userLng);
          }

          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _isLoading = false;
          _error = e.toString();
          debugPrint("Error in stream: $e");
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint("Error fetching restaurants: $e");
      notifyListeners();
    }
  }

  void _calculateDistances(double userLat, double userLng) {
    for (var res in _restaurants) {
      if (res.latitude != null && res.longitude != null) {
        _distances[res.id] = LocationHelper.calculateDistance(
          userLat, userLng, res.latitude!, res.longitude!
        );
      }
    }
  }

  @override
  void dispose() {
    _restaurantsSubscription?.cancel();
    super.dispose();
  }

  Stream<RestaurantModel?> getRestaurantStream(String restaurantId) {
    return _firestoreService.getRestaurantByIdStream(restaurantId).map(
      (data) => data != null ? RestaurantModel.fromMap(data) : null,
    );
  }

  Future<List<PizzaModel>> getRestaurantMenu(String restaurantId) async {
    try {
      final snapshot = await _firestoreService.getMenuItems(restaurantId).first;
      return snapshot.map((item) => PizzaModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Error fetching menu: $e");
      return [];
    }
  }

  Stream<List<PizzaModel>> getRestaurantMenuStream(String restaurantId) {
    return _firestoreService.getMenuItems(restaurantId).map(
      (list) => list.map((item) => PizzaModel.fromMap(item)).toList(),
    );
  }

  Stream<List<PizzaModel>> getGlobalPopularItems() {
    return _firestoreService.getAllMenuItems().map(
      (list) {
        final items = list.map((item) => PizzaModel.fromMap(item)).toList();
        // Filter for best sellers and sort by rating
        return items.where((item) => item.isBestSeller).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
      },
    );
  }

  Stream<List<PizzaModel>> searchPizzas(String query) {
    return _firestoreService.searchMenuItems(query).map(
      (list) => list.map((item) => PizzaModel.fromMap(item)).toList(),
    );
  }

  Future<RestaurantModel?> getRestaurantById(String id) async {
    final data = await _firestoreService.getRestaurantById(id);
    if (data != null) {
      return RestaurantModel.fromMap(data);
    }
    return null;
  }
}
