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
        price: (map['basePrice'] ?? map['price'] ?? 0.0).toDouble(),
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
      itemPrice: (map['itemPrice'] ?? map['price'] ?? 0.0).toDouble(),
    );
  }
}

class CartModel {
  final List<CartItemModel> items;
  final String restaurantId;

  CartModel({
    required this.items,
    required this.restaurantId,
  });

  double get totalPrice => items.fold(0, (sum, item) => sum + (item.itemPrice * item.quantity));
}
