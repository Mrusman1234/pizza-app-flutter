import 'cart_model.dart';
import '../core/constants/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? userName;
  final String restaurantId;
  final String? restaurantName;
  final String? parentCheckoutId;
  final List<CartItemModel> items;
  final double totalAmount;
  final double? subtotal;
  final double? tax;
  final double? deliveryFee;
  final String status;
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
  final bool ratingSubmitted;

  OrderModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.restaurantId,
    this.restaurantName,
    this.parentCheckoutId,
    required this.items,
    required this.totalAmount,
    this.subtotal,
    this.tax,
    this.deliveryFee,
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
    this.ratingSubmitted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'parentCheckoutId': parentCheckoutId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'address': deliveryAddress,
      'deliveryLat': deliveryLat,
      'lat': deliveryLat,
      'deliveryLng': deliveryLng,
      'lng': deliveryLng,
      'paymentMethod': paymentMethod,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderPhoto': riderPhoto,
      'riderRating': riderRating,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'ratingSubmitted': ratingSubmitted,
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
      userName: map['userName'],
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'],
      parentCheckoutId: map['parentCheckoutId'],
      items: (map['items'] as List?)?.map((item) => CartItemModel.fromMap(item)).toList() ?? [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
      status: map['status'] ?? FirestoreConstants.statusPending,
      createdAt: parseDateTime(map['createdAt']),
      deliveryAddress: map['deliveryAddress'] ?? map['address'] ?? '',
      deliveryLat: (map['deliveryLat'] as num? ?? map['lat'] as num?)?.toDouble(),
      deliveryLng: (map['deliveryLng'] as num? ?? map['lng'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'COD',
      riderId: map['riderId'],
      riderName: map['riderName'],
      riderPhone: map['riderPhone'],
      riderPhoto: map['riderPhoto'],
      riderRating: (map['riderRating'] as num?)?.toDouble(),
      estimatedDeliveryTime: parseOptionalDateTime(map['estimatedDeliveryTime']),
      ratingSubmitted: map['ratingSubmitted'] ?? false,
    );
  }
}
