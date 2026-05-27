import 'cart_model.dart';
import '../core/constants/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'
  final DateTime createdAt;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String paymentMethod;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String? riderPhoto;
  final double? riderRating;
  final DateTime? estimatedDeliveryTime;

  OrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.paymentMethod,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderPhoto,
    this.riderRating,
    this.estimatedDeliveryTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'paymentMethod': paymentMethod,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderPhoto': riderPhoto,
      'riderRating': riderRating,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    }

    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      items: (map['items'] as List?)?.map((item) => CartItemModel.fromMap(item)).toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? FirestoreConstants.statusPending,
      createdAt: parseDateTime(map['createdAt']),
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryLat: (map['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (map['deliveryLng'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'COD',
      riderId: map['riderId'],
      riderName: map['riderName'],
      riderPhone: map['riderPhone'],
      riderPhoto: map['riderPhoto'],
      riderRating: (map['riderRating'] as num?)?.toDouble(),
      estimatedDeliveryTime: parseOptionalDateTime(map['estimatedDeliveryTime']),
    );
  }
}
