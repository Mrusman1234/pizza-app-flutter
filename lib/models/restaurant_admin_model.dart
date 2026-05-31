import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantAdminModel {
  final String uid;
  final String email;
  final String name;
  final String role; // always 'restaurant_admin'
  final String assignedRestaurantId;
  final String assignedRestaurantName;
  final bool isActive;
  final DateTime? createdAt;
  final String? profilePic;
  final String? phoneNumber;
  final List<String> permissions; // ['orders', 'menu', 'stats']

  static const List<String> defaultPermissions = ['orders', 'menu', 'stats'];

  RestaurantAdminModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.assignedRestaurantId,
    required this.assignedRestaurantName,
    this.role = 'restaurant_admin',
    this.isActive = true,
    this.createdAt,
    this.profilePic,
    this.phoneNumber,
    List<String>? permissions,
  }) : permissions = permissions ?? defaultPermissions;

  bool get canManageOrders => permissions.contains('orders');
  bool get canManageMenu => permissions.contains('menu');
  bool get canViewStats => permissions.contains('stats');

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': 'restaurant_admin',
      'assignedRestaurantId': assignedRestaurantId,
      'assignedRestaurantName': assignedRestaurantName,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'profilePic': profilePic,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
    };
  }

  factory RestaurantAdminModel.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']);
    }

    return RestaurantAdminModel(
      uid: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      assignedRestaurantId: map['assignedRestaurantId'] ?? '',
      assignedRestaurantName: map['assignedRestaurantName'] ?? '',
      role: map['role'] ?? 'restaurant_admin',
      isActive: map['isActive'] ?? true,
      createdAt: parsedDate,
      profilePic: map['profilePic'],
      phoneNumber: map['phoneNumber'],
      permissions: List<String>.from(map['permissions'] ?? RestaurantAdminModel.defaultPermissions),
    );
  }

  RestaurantAdminModel copyWith({
    bool? isActive,
    List<String>? permissions,
    String? assignedRestaurantId,
    String? assignedRestaurantName,
    String? name,
    String? profilePic,
    String? phoneNumber,
  }) {
    return RestaurantAdminModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      assignedRestaurantId: assignedRestaurantId ?? this.assignedRestaurantId,
      assignedRestaurantName: assignedRestaurantName ?? this.assignedRestaurantName,
      role: role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      profilePic: profilePic ?? this.profilePic,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
    );
  }
}
