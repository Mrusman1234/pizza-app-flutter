class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'customer', 'admin', 'owner'
  final String? profilePic;
  final String? phoneNumber;
  final List<String>? addresses;

  final String? status; // For riders: 'available', 'busy', 'offline'
  final String? activeOrderId;

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
  });

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
    );
  }
}
