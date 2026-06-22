import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/restaurant_admin_model.dart';
import '../models/invitation_model.dart';
import 'audit_service.dart';
import 'email_service.dart';

class RestaurantAdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _audit = AuditService();
  final _emailService = EmailService();
  static FirebaseApp? _secondaryApp;

  Future<FirebaseApp> _secondaryFirebase() async {
    if (_secondaryApp != null) return _secondaryApp!;
    try {
      _secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      _secondaryApp = Firebase.app('secondary');
    }
    return _secondaryApp!;
  }

  Future<void> sendInvitation({
    required String name,
    required String email,
    required String restaurantId,
    required String restaurantName,
    List<String>? permissions,
    String? superAdminId,
  }) async {
    debugPrint('📫 [SERVICE] Starting sendInvitation for $email');
    try {
      // 1. Check if user already exists
      debugPrint('⏳ [SERVICE] Step 1: Checking if user exists...');
      final existingUser = await _db.collection('users').where('email', isEqualTo: email.toLowerCase()).get();
      if (existingUser.docs.isNotEmpty) {
        debugPrint('⚠️ [SERVICE] User already exists in "users" collection');
        throw Exception('A user with this email already exists.');
      }

      // 2. Generate unique token
      final docRef = _db.collection('invitations').doc();
      final String invitationId = docRef.id;
      debugPrint('🎫 [SERVICE] Step 2: Generated invitation ID: $invitationId');
      
      // 3. Create invitation model
      final invitation = InvitationModel(
        id: invitationId,
        email: email.trim().toLowerCase(),
        name: name.trim(),
        assignedRestaurantId: restaurantId,
        assignedRestaurantName: restaurantName,
        permissions: permissions ?? RestaurantAdminModel.defaultPermissions,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // 4. Save to Firestore
      debugPrint('⏳ [SERVICE] Step 3: Saving invitation to Firestore...');
      await _db.collection('invitations').doc(invitationId)
          .set(invitation.toMap())
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw Exception('Firestore write timed out. Check your connection or security rules.');
          });
      debugPrint('✅ [SERVICE] Invitation saved to Firestore');

      // 5. Send Email
      debugPrint('⏳ [SERVICE] Step 4: Calling _emailService.sendInvitationEmail...');
      final String link = 'https://pizza-hub-vehari.web.app/#/accept-invitation?token=$invitationId';

      final emailSent = await _emailService.sendInvitationEmail(
        targetEmail: email.trim(),
        name: name.trim(),
        invitationLink: link,
        restaurantName: restaurantName,
      ).timeout(const Duration(seconds: 20), onTimeout: () {
        debugPrint('⚠️ [SERVICE] Email service timed out, continuing flow...');
        return false;
      });

      if (emailSent) {
        debugPrint('⏳ [SERVICE] Step 5: Email sent, updating invitation status to "sent"...');
        await _db.collection('invitations').doc(invitationId)
            .update({'status': 'sent', 'sentAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ [SERVICE] Invitation status updated');
      }

      // 6. Audit Log
      if (superAdminId != null) {
        debugPrint('⏳ [SERVICE] Step 6: Recording audit log...');
        await _audit.log(
          action: AuditAction.restaurantAdminCreated,
          target: 'invitations/$invitationId',
          restaurantId: restaurantId,
          after: invitation.toMap(),
          meta: {'createdBy': superAdminId, 'flow': 'invitation'},
        );
        debugPrint('✅ [SERVICE] Audit log recorded');
      }
      debugPrint('🎉 [SERVICE] sendInvitation flow finished successfully');
    } catch (e) {
      debugPrint('❌ [SERVICE] Error in sendInvitation: $e');
      rethrow;
    }
  }

  Future<InvitationModel?> getInvitationByToken(String token) async {
    final doc = await _db.collection('invitations').doc(token).get();
    if (!doc.exists) return null;
    return InvitationModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> acceptInvitation({
    required String token,
    required String password,
  }) async {
    final invitation = await getInvitationByToken(token);
    if (invitation == null) throw Exception('Invalid invitation link.');
    if (invitation.status != 'pending') throw Exception('This invitation has already been used.');
    if (invitation.isExpired) throw Exception('This invitation has expired.');

    final String uid;
    try {
      // Create user in Auth
      // NOTE: Since this is usually called by the invited user themselves, 
      // we use the default app instance.
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: invitation.email,
        password: password,
      );
      uid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already in use. Please try logging in.');
      }
      rethrow;
    }

    try {
      // Create user record in Firestore
      final adminModel = RestaurantAdminModel(
        uid: uid,
        email: invitation.email,
        name: invitation.name,
        assignedRestaurantId: invitation.assignedRestaurantId,
        assignedRestaurantName: invitation.assignedRestaurantName,
        isActive: true,
        permissions: invitation.permissions,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();
      
      // 1. Add to users collection
      batch.set(_db.collection('users').doc(uid), adminModel.toMap());
      
      // 2. Update invitation status
      batch.update(_db.collection('invitations').doc(token), {
        'status': 'accepted',
        'acceptedByUid': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      
      await _audit.log(
        action: AuditAction.restaurantAdminCreated,
        target: 'users/$uid',
        restaurantId: invitation.assignedRestaurantId,
        after: adminModel.toMap(),
        meta: {'invitationToken': token},
      );
    } catch (e) {
      // Cleanup auth user if firestore fails (manual rollback)
      await FirebaseAuth.instance.currentUser?.delete();
      rethrow;
    }
  }

  @Deprecated('Use sendInvitation instead to support email flow')
  Future<void> createRestaurantAdmin({
    required String name,
    required String email,
    required String password,
    required String restaurantId,
    required String restaurantName,
    String? phone,
    List<String>? permissions,
    String? superAdminId,
  }) async {
    // ── Step 1: Firebase Auth via secondary app (preserves Super Admin session) ──
    final String uid;
    try {
      final app = await _secondaryFirebase();
      final auth = FirebaseAuth.instanceFor(app: app);

      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = cred.user!.uid;
      await auth.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint('RestaurantAdminService: auth error: ${e.code}');

      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered. Use a different email.');
      } else if (e.code == 'weak-password') {
        throw Exception('Password must be at least 6 characters.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    }

    // ── Step 2: Firestore (only runs when Step 1 fully succeeds) ─────────────────
    try {
      final adminModel = RestaurantAdminModel(
        uid: uid,
        email: email.trim().toLowerCase(),
        name: name.trim(),
        assignedRestaurantId: restaurantId,
        assignedRestaurantName: restaurantName,
        isActive: true,
        phoneNumber: phone?.trim(),
        permissions: permissions ?? RestaurantAdminModel.defaultPermissions,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(adminModel.toMap());

      // Step 3 — audit log (best-effort)
      if (superAdminId != null) {
        await _audit.log(
          action: AuditAction.restaurantAdminCreated,
          target: 'users/$uid',
          restaurantId: restaurantId,
          after: adminModel.toMap(),
          meta: {'createdBy': superAdminId},
        );
      }
    } catch (e) {
      debugPrint('RestaurantAdminService.createRestaurantAdmin error: $e');
      rethrow;
    }
  }

  Future<void> updateRestaurantAdmin({
    required String uid,
    required String name,
    String? phone,
    required String restaurantId,
    required bool isActive,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name.trim(),
        'phoneNumber': phone?.trim(),
        'assignedRestaurantId': restaurantId,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('RestaurantAdminService.updateRestaurantAdmin error: $e');
      rethrow;
    }
  }

  Future<void> deactivateRestaurantAdmin(String uid, {String? superAdminId}) async {
    try {
      final before = await getRestaurantAdminModel(uid);
      await _db.collection('users').doc(uid).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
    } catch (e) {
      debugPrint('RestaurantAdminService.deactivateRestaurantAdmin error: $e');
      rethrow;
    }
  }

  Future<void> setActiveStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('RestaurantAdminService.setActiveStatus error: $e');
      rethrow;
    }
  }

  Future<void> deleteRestaurantAdmin(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('RestaurantAdminService.deleteRestaurantAdmin error: $e');
      rethrow;
    }
  }

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

  Stream<List<InvitationModel>> getPendingInvitations() {
    return _db
        .collection('invitations')
        .where('status', whereIn: ['pending', 'sent'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InvitationModel.fromMap(d.data(), d.id))
            .toList());
  }

  // Helper for backwards compatibility with RestaurantAdminProvider
  Future<Map<String, dynamic>?> getRestaurantAdmin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }

  Future<RestaurantAdminModel?> getRestaurantAdminModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return RestaurantAdminModel.fromMap({...doc.data()!, 'uid': doc.id});
  }
}
