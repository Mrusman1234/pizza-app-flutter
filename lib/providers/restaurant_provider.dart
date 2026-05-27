import 'dart:async';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../models/pizza_model.dart';
import '../services/firestore_service.dart';

class RestaurantProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<RestaurantModel> _restaurants = [];
  bool _isLoading = false;
  StreamSubscription? _restaurantsSubscription;

  String? _error;

  List<RestaurantModel> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants({String? searchQuery, String? filter}) async {
    await _restaurantsSubscription?.cancel();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _restaurantsSubscription = _firestoreService.getRestaurants(searchQuery: searchQuery, filter: filter).listen(
        (data) {
          _restaurants = data.map((item) => RestaurantModel.fromMap(item)).toList();
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

  @override
  void dispose() {
    _restaurantsSubscription?.cancel();
    super.dispose();
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
}
