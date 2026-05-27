import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  void fetchNotifications(String userId, {bool isAdmin = false}) {
    _isLoading = true;
    notifyListeners();

    final stream = isAdmin
        ? _firestoreService.getAdminNotifications(adminId: userId)
        : _firestoreService.getUserNotifications(userId);

    stream.listen((data) {
      _notifications = data.map((item) => NotificationModel.fromMap(item, item['id'])).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    // Logic to mark as read in Firestore
    // For now we just delete or update if supported
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestoreService.deleteAdminNotification(notificationId);
  }
}
