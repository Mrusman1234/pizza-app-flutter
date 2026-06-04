import 'pizza_model.dart';

class CartItemModel {
  final PizzaModel pizza;
  int quantity;
  final String? instructions;
  final String? size;
  final List<String>? extraToppings;
  final double itemPrice;

  CartItemModel({
    required this.pizza,
    this.quantity = 1,
    this.instructions,
    this.size,
    this.extraToppings,
    required this.itemPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'pizza': pizza.toMap(),
      'quantity': quantity,
      'instructions': instructions,
      'size': size,
      'extraToppings': extraToppings,
      'itemPrice': itemPrice,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
     PizzaModel pizza;
    if (map['pizza'] != null) {
      pizza = PizzaModel.fromMap(map['pizza']);
    } else {
      // Robust reconstruction from flat structure (backward compatibility for orders)
      pizza = PizzaModel(
        id: map['pizzaId'] ?? map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        price: (map['basePrice'] as num? ?? map['price'] as num? ?? 0.0).toDouble(),
        restaurantId: map['restaurantId'] ?? '',
        category: map['category'] ?? '',
        ingredients: map['ingredients'] != null ? List<String>.from(map['ingredients']) : [],
      );
    }

    return CartItemModel(
      pizza: pizza,
      quantity: map['quantity'] ?? 1,
      instructions: map['instructions'],
      size: map['size'],
      extraToppings: map['extraToppings'] != null ? List<String>.from(map['extraToppings']) : null,
      itemPrice: (map['itemPrice'] as num? ?? map['price'] as num? ?? 0.0).toDouble(),
    );
  }
}

/// Represents a subset of the cart belonging to a specific restaurant.
class CartGroup {
  final String restaurantId;
  final String restaurantName;
  final List<CartItemModel> items;

  CartGroup({
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
  });

  double get subtotal => items.fold(0.0, (acc, item) => acc + (item.itemPrice * item.quantity));
  
  // Logic for per-restaurant fees if needed (e.g., individual delivery fees)
  double get deliveryFee => 50.0; 
  double get tax => subtotal * 0.05; // 5% GST example

  double get total => subtotal + deliveryFee + tax;
}

/// The entire cart containing multiple restaurant groups.
class MasterCart {
  final List<CartGroup> groups;

  MasterCart({required this.groups});

  double get grandSubtotal => groups.fold(0.0, (acc, group) => acc + group.subtotal);
  double get totalDeliveryFee => groups.fold(0.0, (acc, group) => acc + group.deliveryFee);
  double get totalTax => groups.fold(0.0, (acc, group) => acc + group.tax);
  
  double get grandTotal => grandSubtotal + totalDeliveryFee + totalTax;

  bool get isEmpty => groups.isEmpty;
  int get totalItemCount => groups.fold(0, (acc, group) => acc + group.items.length);
}
