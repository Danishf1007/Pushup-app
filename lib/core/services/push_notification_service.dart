import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/logger.dart';

/// Service for handling push notifications.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _currentUserId;

  /// Initializes the push notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info(
        'Notification permission: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _initializeLocalNotifications();
        await _setupMessageHandlers();
        _initialized = true;
        AppLogger.success('Push notification service initialized');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize push notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'pushup_channel',
      'PushUp Notifications',
      description: 'Notifications from PushUp app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages when tapped
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message received: ${message.notification?.title}',
    );
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Message opened app: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
    final data = message.data;
    if (data.containsKey('type')) {
      // Handle navigation based on notification type
      // This would integrate with your navigation service
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'pushup_channel',
      'PushUp Notifications',
      channelDescription: 'Notifications from PushUp app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Sets the current user and updates their FCM token.
  Future<void> setUser(String userId) async {
    _currentUserId = userId;
    await _updateFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await _saveFcmToken(newToken);
    });
  }

  /// Clears the current user's FCM token.
  Future<void> clearUser() async {
    if (_currentUserId != null) {
      try {
        await _firestore.collection('users').doc(_currentUserId).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
        AppLogger.error('Failed to clear FCM token: $e');
      }
    }
    _currentUserId = null;
  }

  Future<void> _updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
    } catch (e) {
      AppLogger.error('Failed to get FCM token: $e');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'fcmToken': token,
      });
      AppLogger.info('FCM token updated');
    } catch (e) {
      AppLogger.error('Failed to save FCM token: $e');
    }
  }

  /// Gets the current FCM token.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribes to a topic for group notifications.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $e');
    }
  }
}

/// Background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  if (kDebugMode) {
    print('Background message received: ${message.notification?.title}');
  }
}
