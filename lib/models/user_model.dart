// lib/models/user_model.dart
// Changes: add assignedRestaurantId, add roleRestaurantAdmin constant, update fromMap/toMap

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'customer' | 'admin' | 'restaurant_admin' | 'rider'
  final String? profilePic;
  final String? phoneNumber;
  final List<String>? addresses;
  final String? status; // For riders: 'available', 'busy', 'offline'
  final String? activeOrderId;
  final String? fcmToken;

  final bool pushEnabled;
  final bool smsEnabled;
  final bool emailEnabled;

  // ── NEW: for restaurant_admin role only ───────────────────────────────────
  final String? assignedRestaurantId;
  final String? assignedRestaurantName;

  static const String roleAdmin           = 'admin';
  static const String roleCustomer        = 'customer';
  static const String roleRider           = 'rider';
  static const String roleRestaurantAdmin = 'restaurant_admin'; // NEW

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profilePic,
    this.phoneNumber,
    this.addresses,
    this.status,
    this.activeOrderId,
    this.fcmToken,
    this.assignedRestaurantId,    // NEW
    this.assignedRestaurantName,  // NEW
    this.pushEnabled = true,
    this.smsEnabled = false,
    this.emailEnabled = true,
  });

  bool get isRestaurantAdmin => role == roleRestaurantAdmin;
  bool get isSuperAdmin      => role == roleAdmin;
  bool get isRider           => role == roleRider;
  bool get isCustomer        => role == roleCustomer;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'profilePic': profilePic,
      'phoneNumber': phoneNumber,
      'addresses': addresses,
      'status': status,
      'activeOrderId': activeOrderId,
      'fcmToken': fcmToken,
      'assignedRestaurantId': assignedRestaurantId,    // NEW
      'assignedRestaurantName': assignedRestaurantName, // NEW
      'pushEnabled': pushEnabled,
      'smsEnabled': smsEnabled,
      'emailEnabled': emailEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'customer',
      profilePic: map['profilePic'],
      phoneNumber: map['phoneNumber'],
      addresses: List<String>.from(map['addresses'] ?? []),
      status: map['status'],
      activeOrderId: map['activeOrderId'],
      fcmToken: map['fcmToken'],
      assignedRestaurantId: map['assignedRestaurantId'],    // NEW
      assignedRestaurantName: map['assignedRestaurantName'], // NEW
      pushEnabled: map['pushEnabled'] ?? true,
      smsEnabled: map['smsEnabled'] ?? false,
      emailEnabled: map['emailEnabled'] ?? true,
    );
  }
}
