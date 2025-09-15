import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Types of notifications supported by the app
enum NotificationType {
  appointmentReminder('appointment_reminder', 'Appointment Reminder'),
  boothCheckin('booth_checkin', 'Booth Check-in'),
  emergency('emergency', 'Emergency Alert'),
  system('system', 'System Notification'),
  healthGoal('health_goal', 'Health Goal'),
  prescription('prescription', 'Prescription Reminder');

  const NotificationType(this.value, this.displayName);

  final String value;
  final String displayName;

  static NotificationType? fromString(String value) {
    for (NotificationType type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Notification service for handling push notifications and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _notificationController =
      StreamController<RemoteMessage>.broadcast();

  String? _currentUserId;
  bool _isInitialized = false;

  // Getters
  Stream<RemoteMessage> get notificationStream =>
      _notificationController.stream;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions
    await _requestPermissions();

    // Setup FCM handlers
    await _setupFCMHandlers();

    // Get and store FCM token
    await _setupFCMToken();

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // Request FCM permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      // Request local notification permissions
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final localPermission = await androidPlugin?.areNotificationsEnabled();

      return settings.authorizationStatus == AuthorizationStatus.authorized &&
          (localPermission ?? true);
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Initialize local notifications
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
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const appointmentChannel = AndroidNotificationChannel(
      'appointment_channel',
      'Appointments',
      description: 'Appointment reminders and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const boothChannel = AndroidNotificationChannel(
      'booth_channel',
      'Booth Updates',
      description: 'Booth check-in and availability updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const emergencyChannel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Alerts',
      description: 'Critical health and emergency notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const systemChannel = AndroidNotificationChannel(
      'system_channel',
      'System Notifications',
      description: 'General system updates and information',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(appointmentChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(boothChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(emergencyChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(systemChannel);
  }

  /// Setup FCM message handlers
  Future<void> _setupFCMHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is opened from background state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Setup FCM token management
  Future<void> _setupFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && _currentUserId != null) {
        // Store token in Firestore
        await _storeFCMToken(token);

        // Store locally for comparison
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }

      // Listen for token updates
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (_currentUserId != null) {
          await _storeFCMToken(newToken);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', newToken);
        }
      });
    } catch (e) {
      debugPrint('Error setting up FCM token: $e');
    }
  }

  /// Store FCM token in Firestore
  Future<void> _storeFCMToken(String token) async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // Emit to stream for UI updates
    _notificationController.add(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle background messages
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.notification?.title}');

    // Navigate to appropriate screen based on message data
    await _handleNotificationNavigation(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationData = message.data;
    final type = NotificationType.fromString(
      notificationData['type'] ?? 'system',
    );

    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(type),
      priority: _getPriority(type),
      playSound: type != NotificationType.system,
      enableVibration: type == NotificationType.emergency,
      enableLights: type == NotificationType.emergency,
      color: _getNotificationColor(type),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(notificationData),
    );
  }

  /// Handle notification tap navigation
  Future<void> _onLocalNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        await _handleNotificationNavigationFromData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle notification navigation
  Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    await _handleNotificationNavigationFromData(message.data);
  }

  /// Handle notification navigation from data
  Future<void> _handleNotificationNavigationFromData(
    Map<String, dynamic> data,
  ) async {
    final deepLink = data['deepLink'] as String?;
    if (deepLink == null) return;

    // Use GoRouter for navigation
    // This would be called from the app's navigation context
    // For now, we'll just log the deep link
    debugPrint('Navigate to: $deepLink');

    // In a real implementation, you'd use:
    // GoRouter.of(context).go(deepLink);
  }

  /// Send local notification for appointment reminder
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      scheduledTime.subtract(const Duration(minutes: 30)),
      tz.local,
    ); // 30 min before

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _localNotifications.zonedSchedule(
      appointmentId.hashCode,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointments',
          channelDescription: 'Appointment reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: json.encode({
        'type': 'appointment_reminder',
        'appointmentId': appointmentId,
        'deepLink': '/appointments/$appointmentId',
      }),
    );
  }

  /// Cancel scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    await _localNotifications.cancel(notificationId.hashCode);
  }

  /// Get notification channel ID based on type
  String _getChannelId(NotificationType? type) {
    switch (type) {
      case NotificationType.appointmentReminder:
        return 'appointment_channel';
      case NotificationType.boothCheckin:
        return 'booth_channel';
      case NotificationType.emergency:
        return 'emergency_channel';
      default:
        return 'system_channel';
    }
  }

  /// Get notification channel name
  String _getChannelName(NotificationType? type) {
    switch (type) {
      case NotificationType.appointmentReminder:
        return 'Appointments';
      case NotificationType.boothCheckin:
        return 'Booth Updates';
      case NotificationType.emergency:
        return 'Emergency Alerts';
      default:
        return 'System Notifications';
    }
  }

  /// Get notification channel description
  String _getChannelDescription(NotificationType? type) {
    switch (type) {
      case NotificationType.appointmentReminder:
        return 'Appointment reminders and updates';
      case NotificationType.boothCheckin:
        return 'Booth check-in and availability updates';
      case NotificationType.emergency:
        return 'Critical health and emergency notifications';
      default:
        return 'General system updates and information';
    }
  }

  /// Get notification importance
  Importance _getImportance(NotificationType? type) {
    return type == NotificationType.emergency
        ? Importance.max
        : Importance.high;
  }

  /// Get notification priority
  Priority _getPriority(NotificationType? type) {
    return type == NotificationType.emergency ? Priority.max : Priority.high;
  }

  /// Get notification color
  Color _getNotificationColor(NotificationType? type) {
    switch (type) {
      case NotificationType.emergency:
        return const Color(0xFFFF6B6B); // danger color
      case NotificationType.appointmentReminder:
        return const Color(0xFF9FD6FF); // accent blue
      case NotificationType.boothCheckin:
        return const Color(0xFF9CE29B); // accent green
      default:
        return const Color(0xFF0A0A0A); // primary
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _notificationController.close();
    _isInitialized = false;
  }
}
