import '../core/constants/firestore_constants.dart';
import '../core/utils/datetime_helper.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final double rating;
  final String ownerId;
  final bool isOpen;
  final bool isBusy;
  final double? latitude;
  final double? longitude;
  final double deliveryRadius;
  final Map<String, dynamic>? operatingHours;

  bool get isOperatingNow => isOpen && !isBusy && DateTimeHelper.isOpenNow(operatingHours);

  RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.ownerId,
    this.isOpen = true,
    this.isBusy = false,
    this.latitude,
    this.longitude,
    this.deliveryRadius = 10.0,
    this.operatingHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'address': address,
      'rating': rating,
      'ownerId': ownerId,
      'isOpen': isOpen,
      'isBusy': isBusy,
      FirestoreConstants.latitude: latitude,
      FirestoreConstants.longitude: longitude,
      FirestoreConstants.deliveryRadius: deliveryRadius,
      'operatingHours': operatingHours,
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic r) {
      if (r == null) return 0.0;
      if (r is double) return r;
      if (r is int) return r.toDouble();
      if (r is String) return double.tryParse(r) ?? 0.0;
      return 0.0;
    }

    return RestaurantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['image'] ?? map['imageUrl'] ?? '',
      address: map['address'] ?? map['description'] ?? '',
      rating: parseDouble(map['rating']),
      ownerId: map['ownerId'] ?? map[FirestoreConstants.adminId] ?? '',
      isOpen: map['isOpen'] ?? true,
      isBusy: map['isBusy'] ?? false,
      latitude: (map[FirestoreConstants.latitude] as num?)?.toDouble(),
      longitude: (map[FirestoreConstants.longitude] as num?)?.toDouble(),
      deliveryRadius: parseDouble(map[FirestoreConstants.deliveryRadius] ?? 10.0),
      operatingHours: map['operatingHours'] as Map<String, dynamic>?,
    );
  }
}
