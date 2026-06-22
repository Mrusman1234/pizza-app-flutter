import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/firestore_constants.dart';
import '../models/cart_model.dart';
import '../models/pizza_model.dart';
import '../services/firestore_service.dart';
import 'config_provider.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  FirestoreService? _firestoreService;
  ConfigProvider? _configProvider;
  
  FirestoreService get firestoreService => _firestoreService ??= FirestoreService();

  void updateConfig(ConfigProvider provider) {
    _configProvider = provider;
    notifyListeners();
  }

  Map<String, dynamic>? _appliedPromo;
  double _discountAmount = 0.0;

  List<CartItemModel> get items => [..._items];
  Map<String, dynamic>? get appliedPromo => _appliedPromo;
  double get discountAmount => _discountAmount;

  double get _baseDeliveryFee => _configProvider?.baseDeliveryFee ?? 50.0;
  double get _taxRate => _configProvider?.taxRate ?? 0.05;

  /// Returns the restaurant ID if all items belong to the same restaurant.
  /// Returns null if the cart contains items from multiple restaurants or is empty.
  String? get restaurantId {
    if (_items.isEmpty) return null;
    final firstId = _items.first.pizza.restaurantId;
    final isMulti = _items.any((item) => item.pizza.restaurantId != firstId);
    return isMulti ? null : firstId;
  }

  String? get restaurantName {
    if (_items.isEmpty) return null;
    final firstId = _items.first.pizza.restaurantId;
    final isMulti = _items.any((item) => item.pizza.restaurantId != firstId);
    if (isMulti) return "Multi-restaurant Order";
    return _items.first.pizza.restaurantName ?? "Restaurant";
  }

  /// NEW: Group items by restaurant for multi-restaurant support
  List<CartGroup> get groups {
    final Map<String, List<CartItemModel>> groupedMap = {};
    final Map<String, String> nameMap = {};

    for (var item in _items) {
      final resId = item.pizza.restaurantId;
      groupedMap.putIfAbsent(resId, () => []);
      groupedMap[resId]!.add(item);
      nameMap[resId] = item.pizza.restaurantName ?? "Restaurant";
    }

    return groupedMap.entries.map((e) => CartGroup(
      restaurantId: e.key,
      restaurantName: nameMap[e.key]!,
      items: e.value,
      baseDeliveryFee: _baseDeliveryFee,
      taxRate: _taxRate,
    )).toList();
  }

  int get itemCount => _items.length;

  double get subtotal => _items.fold(0.0, (acc, item) => acc + (item.itemPrice * item.quantity));

  // Multi-restaurant delivery logic: Charge once or per restaurant?
  // Industry standard: Usually per restaurant if they are far apart, but for simplicity here
  // we'll charge a base fee per unique restaurant involved.
  double get deliveryFee => groups.length * _baseDeliveryFee;
  
  double get tax => subtotal * _taxRate; // Dynamic tax rate

  double get total {
    if (_items.isEmpty) return 0.0;
    return (subtotal - _discountAmount) + deliveryFee + tax;
  }

  /// Alias for total, used by some screens
  double get totalAmount => total;

  Future<String?> applyPromoCode(String code) async {
    if (_items.isEmpty) return "Add items to cart first";
    
    final promo = await firestoreService.validatePromoCode(code);
    if (promo == null) return "Invalid or expired promo code";

    _appliedPromo = promo;
    final type = promo[FirestoreConstants.discountType] ?? 'percentage';
    final value = (promo[FirestoreConstants.discountValue] ?? promo['discountPercent'] ?? 0).toDouble();
    
    if (type == 'percentage') {
      _discountAmount = subtotal * (value / 100);
    } else {
      _discountAmount = value;
    }
    
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

  Future<void> clearCart({String? userId}) async {
    _items.clear();
    removePromoCode();
    notifyListeners();
    if (userId != null) await syncCartToFirestore(userId);
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

  Future<void> syncCartToFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.cart)
          .doc(userId)
          .set({
        'items': _items.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  Future<void> loadCartFromFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.cart)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudItems = (data['items'] as List<dynamic>)
            .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
            .toList();
        
        for (var item in cloudItems) {
          _addCartItem(item);
        }
        
        notifyListeners();
        await syncCartToFirestore(userId);
      }
    } catch (e) {
      debugPrint('Cart load error: $e');
    }
  }

  Future<void> clearCartFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.cart)
          .doc(userId)
          .delete();
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Cart clear error: $e');
    }
  }
}
