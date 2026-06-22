import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationModel {
  final String id;
  final String email;
  final String name;
  final String assignedRestaurantId;
  final String assignedRestaurantName;
  final List<String> permissions;
  final String role;
  final String status; // 'pending', 'accepted', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? acceptedByUid;

  InvitationModel({
    required this.id,
    required this.email,
    required this.name,
    required this.assignedRestaurantId,
    required this.assignedRestaurantName,
    required this.permissions,
    this.role = 'restaurant_admin',
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
    this.acceptedByUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email.toLowerCase(),
      'name': name,
      'assignedRestaurantId': assignedRestaurantId,
      'assignedRestaurantName': assignedRestaurantName,
      'permissions': permissions,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'acceptedByUid': acceptedByUid,
    };
  }

  factory InvitationModel.fromMap(Map<String, dynamic> map, String docId) {
    return InvitationModel(
      id: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      assignedRestaurantId: map['assignedRestaurantId'] ?? '',
      assignedRestaurantName: map['assignedRestaurantName'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      role: map['role'] ?? 'restaurant_admin',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      acceptedByUid: map['acceptedByUid'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending' && !isExpired;
}
