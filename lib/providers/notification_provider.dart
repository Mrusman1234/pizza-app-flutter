// Fixed imports and inheritance
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;
  String? _currentUserId;
  bool _currentIsAdmin = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void fetchNotifications(String userId, {bool isAdmin = false}) {
    // If already listening to this user/role, don't restart
    if (_currentUserId == userId && _currentIsAdmin == isAdmin && _subscription != null) {
      return;
    }

    _subscription?.cancel();
    _currentUserId = userId;
    _currentIsAdmin = isAdmin;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final stream = isAdmin
        ? _firestoreService.getAdminNotifications(adminId: userId)
        : _firestoreService.getUserNotifications(userId);

    _subscription = stream.listen(
      (data) {
        debugPrint('🔔 [NOTIFICATION FLOW] Step 2: Stream received ${data.length} notifications from Firestore.');
        final newNotifications = data
            .map((item) => NotificationModel.fromMap(item, item['id'] as String))
            .toList();

        // Optional: show local notification if new message arrives and app is in foreground
        if (_notifications.isNotEmpty && newNotifications.isNotEmpty) {
          final newest = newNotifications.first;
          bool isAlreadyPresent = _notifications.any((n) => n.id == newest.id);
          
          if (!isAlreadyPresent && !newest.isRead) {
            debugPrint('🔔 [NOTIFICATION FLOW] Step 3: New notification detected. Triggering local alert.');
            NotificationService().showInstantNotification(
              title: newest.title,
              body: newest.body,
              payload: newest.orderId,
            );
          }
        }

        _notifications = newNotifications;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error fetching notifications: $error');
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestoreService.markNotificationAsRead(notificationId);
      // Local update happens automatically via stream
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;
    try {
      await _firestoreService.markAllNotificationsAsRead(_currentUserId!, isAdmin: _currentIsAdmin);
      // Local update happens automatically via stream
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestoreService.deleteAdminNotification(notificationId);
      // Local update happens automatically via stream
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
