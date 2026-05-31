import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void fetchNotifications(String userId, {bool isAdmin = false}) {
    _isLoading = true;
    notifyListeners();

    final stream = isAdmin
        ? _firestoreService.getAdminNotifications(adminId: userId)
        : _firestoreService.getUserNotifications(userId);

    stream.listen((data) {
      _notifications = data
          .map((item) => NotificationModel.fromMap(item, item['id'] as String))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Mark a single notification as read in Firestore and locally.
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Optimistically update local list so UI refreshes immediately
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          createdAt: old.createdAt,
          type: old.type,
          orderId: old.orderId,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  /// Mark all notifications as read in a single Firestore batch.
  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in unread) {
        final ref = FirebaseFirestore.instance
            .collection('notifications')
            .doc(n.id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();

      // Update local state
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                type: n.type,
                orderId: n.orderId,
                isRead: true,
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestoreService.deleteAdminNotification(notificationId);
  }
}
