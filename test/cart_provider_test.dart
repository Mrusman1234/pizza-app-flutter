import 'package:flutter_test/flutter_test.dart';
import 'package:app_multi_restaurant/providers/cart_provider.dart';
import 'package:app_multi_restaurant/models/pizza_model.dart';

void main() {
  group('CartProvider Multi-restaurant Logic Tests', () {
    late CartProvider cartProvider;

    setUp(() {
      cartProvider = CartProvider();
    });

    final pizza1 = PizzaModel(
      id: 'p1',
      name: 'Pizza 1',
      description: 'Desc 1',
      imageUrl: 'url1',
      price: 10.0,
      restaurantId: 'r1',
      restaurantName: 'Restaurant 1',
      category: 'Cat 1',
      ingredients: [],
    );

    final pizza2 = PizzaModel(
      id: 'p2',
      name: 'Pizza 2',
      description: 'Desc 2',
      imageUrl: 'url2',
      price: 12.0,
      restaurantId: 'r1',
      restaurantName: 'Restaurant 1',
      category: 'Cat 1',
      ingredients: [],
    );

    final pizza3 = PizzaModel(
      id: 'p3',
      name: 'Pizza 3',
      description: 'Desc 3',
      imageUrl: 'url3',
      price: 15.0,
      restaurantId: 'r2',
      restaurantName: 'Restaurant 2',
      category: 'Cat 2',
      ingredients: [],
    );

    test('Initial cart should have null restaurantId and restaurantName', () {
      expect(cartProvider.restaurantId, isNull);
      expect(cartProvider.restaurantName, isNull);
    });

    test('Single restaurant items should return that restaurant id and name', () {
      cartProvider.addToCart(pizza1);
      expect(cartProvider.restaurantId, 'r1');
      expect(cartProvider.restaurantName, 'Restaurant 1');

      cartProvider.addToCart(pizza2);
      expect(cartProvider.restaurantId, 'r1');
      expect(cartProvider.restaurantName, 'Restaurant 1');
    });

    test('Multi-restaurant items should return null id and "Multi-restaurant Order" name', () {
      cartProvider.addToCart(pizza1);
      cartProvider.addToCart(pizza3);

      expect(cartProvider.restaurantId, isNull);
      expect(cartProvider.restaurantName, 'Multi-restaurant Order');
    });

    test('Removing multi-restaurant items should revert to single restaurant state', () {
      cartProvider.addToCart(pizza1);
      cartProvider.addToCart(pizza3);
      
      expect(cartProvider.restaurantId, isNull);

      cartProvider.removeFromCart(pizza3.id);
      
      expect(cartProvider.restaurantId, 'r1');
      expect(cartProvider.restaurantName, 'Restaurant 1');
    });

    test('Clearing cart should reset restaurant properties', () {
      cartProvider.addToCart(pizza1);
      cartProvider.addToCart(pizza3);
      
      cartProvider.clearLocalCart();
      
      expect(cartProvider.restaurantId, isNull);
      expect(cartProvider.restaurantName, isNull);
    });
  });
}
