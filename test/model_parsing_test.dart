import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_multi_restaurant/models/order_model.dart';
import 'package:app_multi_restaurant/models/pizza_model.dart';

void main() {
  group('Model Parsing Tests', () {
    test('OrderModel.fromMap should parse correctly with Timestamp', () {
      final now = DateTime.now();
      final map = {
        'id': 'order_123',
        'userId': 'user_456',
        'restaurantId': 'res_789',
        'items': [],
        'totalAmount': 1500.50,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'deliveryAddress': '123 Street, City',
        'paymentMethod': 'COD',
      };

      final order = OrderModel.fromMap(map);

      expect(order.id, 'order_123');
      expect(order.totalAmount, 1500.50);
      expect(order.createdAt.millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
    });

    test('PizzaModel.fromMap should parse correctly', () {
      final map = {
        'id': 'pizza_1',
        'name': 'Margherita',
        'description': 'Classic pizza',
        'imageUrl': 'http://image.com',
        'price': 999.0,
        'restaurantId': 'res_1',
        'restaurantName': 'Pizzeria',
        'category': 'Classic',
        'ingredients': ['Cheese', 'Tomato'],
      };

      final pizza = PizzaModel.fromMap(map);

      expect(pizza.name, 'Margherita');
      expect(pizza.ingredients, contains('Cheese'));
    });
  });
}
