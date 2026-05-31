import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/restaurant_admin_model.dart';
import 'audit_service.dart';

class RestaurantAdminService {
  static final RestaurantAdminService _instance = RestaurantAdminService._internal();
  factory RestaurantAdminService() => _instance;
  RestaurantAdminService._internal();

  final _db = FirebaseFirestore.instance;
  final _audit = AuditService();

  // ─── IMPORTANT ────────────────────────────────────────────────────────────
  // Replace with your Firebase Web API key (found in Project Settings → General
  // → Your apps → Web API Key). This key is safe to ship in client code; it is
  // scoped to your project and protected by App Check.
  static const String _firebaseWebApiKey = 'YOUR_FIREBASE_WEB_API_KEY';
  // ──────────────────────────────────────────────────────────────────────────

  /// Create a restaurant admin without signing out the super admin.
  /// Returns the new admin's UID on success, null on failure.
  Future<String?> createRestaurantAdmin({
    required String email,
    required String password,
    required String name,
    required String restaurantId,
    required String restaurantName,
    List<String>? permissions,
    String? superAdminId,
  }) async {
    try {
      // Step 1 — create the Firebase Auth account via REST (no session swap)
      final authResponse = await http.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseWebApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': false,
        }),
      );

      if (authResponse.statusCode != 200) {
        final error = jsonDecode(authResponse.body);
        debugPrint('RestaurantAdminService: auth error: ${error['error']['message']}');
        throw Exception(error['error']['message'] ?? 'Failed to create auth account');
      }

      final uid = jsonDecode(authResponse.body)['localId'] as String;

      // Step 2 — write the Firestore user document
      final adminModel = RestaurantAdminModel(
        uid: uid,
        email: email,
        name: name,
        assignedRestaurantId: restaurantId,
        assignedRestaurantName: restaurantName,
        isActive: true,
        createdAt: DateTime.now(),
        permissions: permissions ?? RestaurantAdminModel.defaultPermissions,
      );

      await _db.collection('users').doc(uid).set(adminModel.toMap());

      // Step 3 — audit log (best-effort)
      if (superAdminId != null) {
        await _audit.log(
          action: AuditAction.restaurantAdminCreated,
          target: 'users/$uid',
          restaurantId: restaurantId,
          after: {
            'email': email,
            'name': name,
            'assignedRestaurantId': restaurantId,
            'assignedRestaurantName': restaurantName,
          },
          meta: {'createdBy': superAdminId},
        );
      }

      return uid;
    } catch (e) {
      debugPrint('RestaurantAdminService.createRestaurantAdmin error: $e');
      rethrow;
    }
  }

  /// Stream of all restaurant admins — for the super admin management screen.
  Stream<List<RestaurantAdminModel>> getAllRestaurantAdmins() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'restaurant_admin')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RestaurantAdminModel.fromMap({...d.data(), 'uid': d.id}))
            .toList());
  }

  /// Fetch a single restaurant admin by UID.
  Future<RestaurantAdminModel?> getRestaurantAdmin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return RestaurantAdminModel.fromMap({...doc.data()!, 'uid': doc.id});
  }

  /// Deactivate (not delete) a restaurant admin.
  Future<void> deactivateRestaurantAdmin(String uid, {String? superAdminId}) async {
    final before = await getRestaurantAdmin(uid);
    await _db.collection('users').doc(uid).update({'isActive': false});

    if (superAdminId != null && before != null) {
      await _audit.log(
        action: AuditAction.restaurantAdminDeactivated,
        target: 'users/$uid',
        restaurantId: before.assignedRestaurantId,
        before: before.toMap(),
        after: {...before.toMap(), 'isActive': false},
        meta: {'deactivatedBy': superAdminId},
      );
    }
  }

  /// Update permissions for a restaurant admin.
  Future<void> updatePermissions(
    String uid,
    List<String> permissions, {
    String? superAdminId,
    String? restaurantId,
  }) async {
    final before = await getRestaurantAdmin(uid);
    await _db.collection('users').doc(uid).update({'permissions': permissions});

    if (superAdminId != null && before != null) {
      await _audit.log(
        action: AuditAction.restaurantAdminPermissionsUpdated,
        target: 'users/$uid',
        restaurantId: restaurantId ?? before.assignedRestaurantId,
        before: {'permissions': before.permissions},
        after: {'permissions': permissions},
        meta: {'updatedBy': superAdminId},
      );
    }
  }
}
