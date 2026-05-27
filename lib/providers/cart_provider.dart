import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/firestore_constants.dart';
import '../models/cart_model.dart';
import '../models/pizza_model.dart';
import '../services/firestore_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _appliedPromo;
  double _discountAmount = 0.0;

  List<CartItemModel> get items => [..._items];
  Map<String, dynamic>? get appliedPromo => _appliedPromo;
  double get discountAmount => _discountAmount;

  /// Returns the restaurant ID if all items belong to the same restaurant.
  /// Returns null if the cart contains items from multiple restaurants or is empty.
  String? get restaurantId {
    if (_items.isEmpty) return null;
    return _items.first.pizza.restaurantId;
  }

  String? get restaurantName {
    if (_items.isEmpty) return null;
    return _items.first.pizza.restaurantName ?? "Restaurant";
  }

  int get itemCount => _items.length;

  double get totalAmount {
    double subtotal = _items.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity));
    return subtotal - _discountAmount;
  }

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity));
  }

  double get deliveryFee => _items.isEmpty ? 0.0 : 50.0;
  double get tax => _items.isEmpty ? 0.0 : 100.0;

  double get total {
    if (_items.isEmpty) return 0.0;
    return (subtotal - _discountAmount) + deliveryFee + tax;
  }

  Future<String?> applyPromoCode(String code) async {
    if (_items.isEmpty) return "Add items to cart first";
    
    final promo = await _firestoreService.validatePromoCode(code);
    if (promo == null) return "Invalid or expired promo code";

    _appliedPromo = promo;
    final type = promo[FirestoreConstants.discountType] ?? 'percentage';
    final value = (promo[FirestoreConstants.discountValue] ?? promo['discountPercent'] ?? 0).toDouble();
    
    if (type == 'percentage') {
      _discountAmount = subtotal * (value / 100);
    } else {
      _discountAmount = value;
    }
    
    // Never exceed subtotal
    if (_discountAmount > subtotal) {
      _discountAmount = subtotal;
    }

    notifyListeners();
    return null; // Success
  }

  void removePromoCode() {
    _appliedPromo = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void addToCart(PizzaModel pizza, {
    int quantity = 1, 
    String? instructions,
    String? size,
    List<String>? extraToppings,
    double? customPrice,
    String? restaurantName,
    String? userId,
  }) {
    // Ensure the pizza model has the restaurant name if it was passed separately
    final updatedPizza = (pizza.restaurantName == null && restaurantName != null)
        ? pizza.copyWith(restaurantName: restaurantName)
        : pizza;

    final newItem = CartItemModel(
      pizza: updatedPizza,
      quantity: quantity,
      instructions: instructions,
      size: size,
      extraToppings: extraToppings,
      itemPrice: customPrice ?? pizza.price,
    );

    _addCartItem(newItem);
    
    notifyListeners();
    if (userId != null) syncCartToFirestore(userId);
  }

  void _addCartItem(CartItemModel newItem) {
    // Check if the exact same item (same pizza, size, toppings, AND restaurant) is already in cart
    final index = _items.indexWhere((item) => 
      item.pizza.id == newItem.pizza.id && 
      item.pizza.restaurantId == newItem.pizza.restaurantId &&
      item.size == newItem.size && 
      _compareToppings(item.extraToppings, newItem.extraToppings)
    );

    if (index >= 0) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
  }

  void removeItem(String pizzaId, {String? userId, String? restaurantId, String? size, List<String>? extraToppings}) {
    _items.removeWhere((item) => 
      item.pizza.id == pizzaId && 
      (restaurantId == null || item.pizza.restaurantId == restaurantId) &&
      item.size == size && 
      _compareToppings(item.extraToppings, extraToppings)
    );
    notifyListeners();
    if (userId != null) syncCartToFirestore(userId);
  }

  void removeFromCart(String pizzaId, {String? userId}) {
    _items.removeWhere((item) => item.pizza.id == pizzaId);
    notifyListeners();
    if (userId != null) syncCartToFirestore(userId);
  }

  void updateQuantity(String pizzaId, int quantity, {String? userId, String? restaurantId, String? size, List<String>? extraToppings}) {
    final index = _items.indexWhere((item) => 
      item.pizza.id == pizzaId && 
      (restaurantId == null || item.pizza.restaurantId == restaurantId) &&
      item.size == size && 
      _compareToppings(item.extraToppings, extraToppings)
    );

    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
      if (userId != null) syncCartToFirestore(userId);
    }
  }

  void clearCart({String? userId}) {
    _items.clear();
    removePromoCode();
    notifyListeners();
    if (userId != null) syncCartToFirestore(userId);
  }

  void clearLocalCart() {
    _items.clear();
    notifyListeners();
  }

  bool _compareToppings(List<String>? t1, List<String>? t2) {
    if (t1 == null && t2 == null) return true;
    if (t1 == null || t2 == null) return false;
    if (t1.length != t2.length) return false;
    return t1.every((t) => t2.contains(t));
  }

  // Save cart to Firestore so it persists
  Future<void> syncCartToFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .set({
        'items': _items.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  // Load cart from Firestore when app opens or user logs in
  Future<void> loadCartFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudItems = (data['items'] as List<dynamic>)
            .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
            .toList();
        
        // Merge cloud items into local cart (preserving any guest items)
        for (var item in cloudItems) {
          _addCartItem(item);
        }
        
        notifyListeners();
        // Sync the merged result back to Firestore
        await syncCartToFirestore(userId);
      } else if (_items.isNotEmpty) {
        // If no cloud cart exists but we have guest items, sync them now
        await syncCartToFirestore(userId);
      }
    } catch (e) {
      debugPrint('Cart load error: $e');
    }
  }

  // Clear cart from Firestore after order placed
  Future<void> clearCartFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .delete();
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Cart clear error: $e');
    }
  }
}
