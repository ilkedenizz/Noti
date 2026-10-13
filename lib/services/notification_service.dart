import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/noti_alert.dart';

/// Configuration details for Android Emergency Notification Channel
class AndroidEmergencyChannel {
  static const String id = 'noti_emergency';
  static const String name = 'NOTI EMERGENCY';
  static const String description = 'High priority emergency communication alerts';
  static const bool enableVibration = true;
  static const bool enableSound = true;

  static final Int64List vibrationPattern =
      Int64List.fromList([0, 500, 200, 500, 200, 1000]);

  static final AndroidNotificationChannel channel = AndroidNotificationChannel(
    id,
    name,
    description: description,
    importance: Importance.max,
    playSound: enableSound,
    enableVibration: enableVibration,
    vibrationPattern: vibrationPattern,
  );
}

/// Top-level background message handler required for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('> FIREBASE_BG_INIT_WARN: $e');
  }
  debugPrint('> FIREBASE_BG_MSG_RECEIVED: ${message.messageId}');
  final notificationService = NotificationService();
  await notificationService.handleRemoteMessage(message, isBackground: true);
}

/// Service handling Android local & Firebase Cloud Messaging (FCM) notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final StreamController<NotiAlert> _alertStreamController = StreamController<NotiAlert>.broadcast();
  final StreamController<NotiAlert> _notificationTapStreamController = StreamController<NotiAlert>.broadcast();
  final StreamController<String> _tokenRefreshStreamController = StreamController<String>.broadcast();

  Stream<NotiAlert> get alertStream => _alertStreamController.stream;
  Stream<NotiAlert> get notificationTapStream => _notificationTapStreamController.stream;
  Stream<String> get onTokenRefresh => _tokenRefreshStreamController.stream;

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  String? _fcmToken;
  bool _isFirebaseInitialized = false;
  bool _hasNotificationPermission = false;

  // Deduplication cache and in-memory alert history
  final Set<String> _processedAlertIds = <String>{};
  final List<NotiAlert> _recentAlerts = <NotiAlert>[];

  bool get isFirebaseInitialized => _isFirebaseInitialized;
  bool get hasNotificationPermission => _hasNotificationPermission;
  String? get fcmToken => _fcmToken;
  List<NotiAlert> get recentAlerts => List.unmodifiable(_recentAlerts);

  /// Initializes Android notification channels, Flutter Local Notifications, and Firebase Messaging safely.
  Future<void> initialize() async {
    // 1. Initialize Flutter Local Notifications & Android Emergency Channel
    await _initLocalNotifications();

    // 2. Safely initialize Firebase & FCM handlers
    await _initFirebaseMessaging();
  }

  /// Initializes Local Notifications and creates the NOTI EMERGENCY Android notification channel
  Future<void> _initLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@android:drawable/sym_def_app_icon');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications?.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('> NOTIFICATION_TAP_RECEIVED: ${response.payload}');
          final payloadId = response.payload;
          if (payloadId != null) {
            final matched = _recentAlerts.cast<NotiAlert?>().firstWhere(
                  (a) => a?.id == payloadId,
                  orElse: () => null,
                );
            if (matched != null) {
              _notificationTapStreamController.add(matched);
            }
          }
        },
      );

      final androidImplementation = _localNotifications
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(AndroidEmergencyChannel.channel);
    } catch (e) {
      debugPrint('> LOCAL_NOTIFICATIONS_INIT_ERROR: $e');
    }
  }

  /// Safely initializes Firebase App & FCM event listeners
  Future<void> _initFirebaseMessaging() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;
      _messaging = FirebaseMessaging.instance;

      debugPrint('> FIREBASE_INIT_STATUS: SUCCESS (APP: ${Firebase.app().name})');

      // Request notification permissions
      _hasNotificationPermission = await requestNotificationPermission();

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('> FCM_FOREGROUND_MSG_RECEIVED: ${message.messageId}');
        handleRemoteMessage(message, isBackground: false);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('> FCM_MSG_OPENED_APP: ${message.messageId}');
        final alert = _parseMessageToAlert(message);
        _notificationTapStreamController.add(alert);
        handleRemoteMessage(message, isBackground: false);
      });

      // Handle initial message when app is launched from terminated state
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('> FCM_INITIAL_MSG_RECEIVED: ${initialMessage.messageId}');
        final alert = _parseMessageToAlert(initialMessage);
        _notificationTapStreamController.add(alert);
        handleRemoteMessage(initialMessage, isBackground: false);
      }

      // Listen to token refresh events
      _messaging?.onTokenRefresh.listen((String newToken) {
        _fcmToken = newToken;
        debugPrint('> FCM_TOKEN_REFRESHED: $newToken');
        _tokenRefreshStreamController.add(newToken);
      });

      // Retrieve initial FCM token
      await getToken();
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('> FIREBASE_INIT_STATUS: UNINITIALIZED_OR_FAILED - $e');
    }
  }

  /// Request POST_NOTIFICATIONS permissions for Android 13+ / iOS
  Future<bool> requestNotificationPermission() async {
    try {
      if (_messaging != null) {
        final settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        _hasNotificationPermission =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        debugPrint('> NOTIFICATION_PERMISSION_STATUS: ${settings.authorizationStatus}');
        return _hasNotificationPermission;
      }
    } catch (e) {
      debugPrint('> NOTIFICATION_PERMISSION_ERROR: $e');
    }
    return false;
  }

  /// Retrieve current FCM registration token
  Future<String?> getToken() async {
    if (!_isFirebaseInitialized || _messaging == null) {
      debugPrint('> FCM_TOKEN_FETCH: SKIPPED (Firebase uninitialized)');
      return null;
    }

    try {
      _fcmToken = await _messaging!.getToken();
      debugPrint('> FCM_TOKEN_RETRIEVED: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('> FCM_TOKEN_FETCH_ERROR: $e');
      return null;
    }
  }

  /// Explicit token refresh helper API
  Future<String?> refreshToken() async {
    return await getToken();
  }

  NotiAlert _parseMessageToAlert(RemoteMessage message) {
    final data = message.data;
    final alertId = data['alertId'] ?? message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';
    final senderId = data['senderId'] ?? 'fcm_sender';
    final senderUsername = data['senderUsername'] ?? '@remote_user';
    final recipientId = data['recipientId'] ?? 'self';
    final recipientUsername = data['recipientUsername'] ?? '@me';
    final title = data['title'] ?? message.notification?.title ?? 'NOTI ALERT';
    final body = data['message'] ?? message.notification?.body ?? 'Incoming alert message';
    final rawPriority = (data['priority'] ?? 'NORMAL').toString().toUpperCase();
    final priority = rawPriority == 'EMERGENCY' ? NotiAlertPriority.emergency : NotiAlertPriority.normal;
    final createdAtStr = data['createdAt'] ?? DateTime.now().toIso8601String();

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (_) {
      createdAt = DateTime.now();
    }

    return NotiAlert(
      id: alertId,
      senderId: senderId,
      senderUsername: senderUsername,
      recipientId: recipientId,
      recipientUsername: recipientUsername,
      title: title,
      message: body,
      createdAt: createdAt,
      priority: priority,
      status: NotiAlertStatus.delivered,
    );
  }

  /// Parses incoming FCM RemoteMessage, performs deduplication, maps to NotiAlert model & triggers notification
  Future<void> handleRemoteMessage(RemoteMessage message, {bool isBackground = false}) async {
    final alert = _parseMessageToAlert(message);

    // Deduplication check
    if (_processedAlertIds.contains(alert.id)) {
      debugPrint('> FCM_DUPLICATE_ALERT_DROPPED: ${alert.id}');
      return;
    }

    _processedAlertIds.add(alert.id);
    if (_processedAlertIds.length > 250) {
      _processedAlertIds.remove(_processedAlertIds.first);
    }

    _recordAlert(alert);

    // Emit alert to UI stream listeners
    await showLocalAlert(alert);

    // If app is in foreground or message notification is present, show Android local notification
    if (!isBackground) {
      await _displayAndroidLocalNotification(alert);
    }
  }

  void _recordAlert(NotiAlert alert) {
    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > 100) {
      _recentAlerts.removeLast();
    }
  }

  /// Displays Android local notification on NOTI EMERGENCY channel
  Future<void> _displayAndroidLocalNotification(NotiAlert alert) async {
    if (_localNotifications == null) return;

    final androidDetails = AndroidNotificationDetails(
      AndroidEmergencyChannel.id,
      AndroidEmergencyChannel.name,
      channelDescription: AndroidEmergencyChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: AndroidEmergencyChannel.vibrationPattern,
      ticker: '[NOTI EMERGENCY ALERT]',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      final id = alert.id.hashCode & 0x7FFFFFFF;
      await _localNotifications!.show(
        id,
        '[${alert.priority.label}] ${alert.title}',
        'From ${alert.senderUsername}: ${alert.message}',
        notificationDetails,
        payload: alert.id,
      );
    } catch (e) {
      debugPrint('> LOCAL_NOTIFICATION_DISPLAY_ERROR: $e');
    }
  }

  /// Dispatches alert to UI stream
  Future<bool> showLocalAlert(NotiAlert alert) async {
    _recordAlert(alert);
    _alertStreamController.add(alert);
    return true;
  }

  void dispose() {
    _alertStreamController.close();
    _notificationTapStreamController.close();
    _tokenRefreshStreamController.close();
  }
}
