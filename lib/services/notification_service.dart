import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/firestore_constants.dart';
import '../routes/route_names.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stored so we can navigate from handlers
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (kIsWeb) return;
    _navigatorKey = navigatorKey;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Navigate when user taps a local notification
          if (response.payload != null) {
            _navigateFromPayload(response.payload!);
          }
        },
      );

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _fcm.getToken();
        if (token != null) await saveTokenToFirestore(token);

        _fcm.onTokenRefresh.listen(saveTokenToFirestore);
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle notification that launched the app from terminated state
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          // Slight delay to ensure app is fully ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleMessageOpenedApp(initialMessage);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing notifications: $e');
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection(FirestoreConstants.users).doc(uid).update({
        FirestoreConstants.fcmToken: token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null) {
      // Pass orderId as payload so tapping navigates correctly
      final orderId = message.data['orderId'] as String?;
      _showLocalNotification(notification, android, payload: orderId);
    }
  }

  Future<void> _showLocalNotification(
    RemoteNotification notification,
    AndroidNotification? android, {
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important order notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,   // ← carries orderId to the tap handler
    );
  }

  /// Called when user taps a notification while app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    final orderId = message.data['orderId'] as String?;
    final type = message.data['type'] as String?;
    if (orderId != null) {
      _navigateToOrder(orderId, type);
    }
  }

  /// Navigate based on payload string (orderId)
  void _navigateFromPayload(String payload) {
    _navigateToOrder(payload, null);
  }

  /// Core navigation logic
  void _navigateToOrder(String orderId, String? type) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    // Navigate to order tracking screen
    navigator.pushNamed(
      RouteNames.orderTracking,   // Make sure this matches your RouteNames
      arguments: orderId,
    );
  }
}
