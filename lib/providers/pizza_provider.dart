import 'package:flutter/material.dart';
import '../models/pizza_model.dart';
import '../services/firestore_service.dart';

class PizzaProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<PizzaModel> _menuItems = [];
  List<PizzaModel> _filteredItems = [];
  bool _isLoading = false;

  List<PizzaModel> get menuItems => _menuItems;
  List<PizzaModel> get filteredItems => _filteredItems;
  bool get isLoading => _isLoading;

  void fetchMenuItems(String restaurantId) {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getMenuItems(restaurantId).listen((data) {
      _menuItems = data.map((item) => PizzaModel.fromMap(item)).toList();
      _filteredItems = _menuItems;
      _isLoading = false;
      notifyListeners();
    });
  }

  void fetchAllMenuItems() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getAllMenuItems().listen((data) {
      _menuItems = data.map((item) => PizzaModel.fromMap(item)).toList();
      _filteredItems = _menuItems;
      _isLoading = false;
      notifyListeners();
    });
  }

  void searchItems(String query) {
    if (query.isEmpty) {
      _filteredItems = _menuItems;
    } else {
      _filteredItems = _menuItems
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> addMenuItem(String restaurantId, PizzaModel item) async {
    await _firestoreService.addMenuItem(restaurantId, item.toMap());
  }

  Future<void> updateMenuItem(String restaurantId, PizzaModel item) async {
    await _firestoreService.updateMenuItem(restaurantId, item.id, item.toMap());
  }

  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    await _firestoreService.deleteMenuItem(restaurantId, itemId);
  }
}
