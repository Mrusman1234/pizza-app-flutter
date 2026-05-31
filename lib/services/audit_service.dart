import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuditAction {
  restaurantAdminCreated,
  restaurantAdminDeactivated,
  restaurantAdminPermissionsUpdated,
  orderStatusUpdated,
  menuItemAdded,
  menuItemUpdated,
  menuItemDeleted,
}

class AuditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionAudit = 'audit_logs';

  /// General log method used by newer services
  Future<void> log({
    required AuditAction action,
    required String target,
    String? restaurantId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Map<String, dynamic>? meta,
  }) async {
    final user = _auth.currentUser;
    await _db.collection(collectionAudit).add({
      'adminId': user?.uid,
      'adminEmail': user?.email,
      'action': action.name,
      'target': target,
      'restaurantId': restaurantId,
      'before': before,
      'after': after,
      'metadata': meta,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Legacy logAction method for compatibility
  Future<void> logAction({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    await _db.collection(collectionAudit).add({
      'adminId': user?.uid,
      'adminEmail': user?.email,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Convenience methods
  Future<void> logOrderUpdate(String orderId, String status) async {
    await log(
      action: AuditAction.orderStatusUpdated,
      target: 'orders/$orderId',
      meta: {'status': status},
    );
  }

  Future<void> logMenuUpdate(String restaurantId, String itemId, String action) async {
    AuditAction auditAction;
    switch (action) {
      case 'ADD_MENU_ITEM':
        auditAction = AuditAction.menuItemAdded;
        break;
      case 'UPDATE_MENU_ITEM':
        auditAction = AuditAction.menuItemUpdated;
        break;
      case 'DELETE_MENU_ITEM':
        auditAction = AuditAction.menuItemDeleted;
        break;
      default:
        auditAction = AuditAction.menuItemUpdated;
    }

    await log(
      action: auditAction,
      target: 'restaurants/$restaurantId/menu/$itemId',
      restaurantId: restaurantId,
    );
  }

  Stream<List<Map<String, dynamic>>> getLogsForRestaurant(String restaurantId) {
    return _db
        .collection(collectionAudit)
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
