import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String photoUrl;
  final String vehicleType;
  final String vehicleNumber;
  final String status; // 'available', 'busy', 'offline'
  final String? activeOrderId;
  final double rating;
  final int totalDeliveries;
  final GeoPoint? currentLocation;
  final DateTime createdAt;

  RiderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl = '',
    this.vehicleType = 'bike',
    this.vehicleNumber = '',
    this.status = 'offline',
    this.activeOrderId,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.currentLocation,
    required this.createdAt,
  });

  // ✅ Convert Firestore document to RiderModel
  factory RiderModel.fromMap(Map<String, dynamic> map) {
    return RiderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      vehicleType: map['vehicleType'] ?? 'bike',
      vehicleNumber: map['vehicleNumber'] ?? '',
      status: map['status'] ?? 'offline',
      activeOrderId: map['activeOrderId'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      currentLocation: map['currentLocation'] as GeoPoint?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ✅ Convert RiderModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'activeOrderId': activeOrderId,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'currentLocation': currentLocation,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ✅ Copy with updated fields
  RiderModel copyWith({
    String? status,
    String? activeOrderId,
    GeoPoint? currentLocation,
    double? rating,
    int? totalDeliveries,
  }) {
    return RiderModel(
      id: id,
      userId: userId,
      name: name,
      phone: phone,
      email: email,
      photoUrl: photoUrl,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      status: status ?? this.status,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      currentLocation: currentLocation ?? this.currentLocation,
      createdAt: createdAt,
    );
  }
}
