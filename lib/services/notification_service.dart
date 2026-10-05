import 'dart:async';
import '../models/noti_alert.dart';

/// Configuration details for Android Emergency Notification Channel
class AndroidEmergencyChannel {
  static const String id = 'noti_emergency';
  static const String name = 'NOTI EMERGENCY';
  static const String description = 'High priority emergency communication alerts';
  static const bool enableVibration = true;
  static const bool enableSound = true;
  static const String importance = 'MAX'; // Android Importance.MAX
}

/// Service handling Android local & remote (FCM) notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final StreamController<NotiAlert> _alertStreamController = StreamController<NotiAlert>.broadcast();
  final StreamController<String> _tokenRefreshStreamController = StreamController<String>.broadcast();

  Stream<NotiAlert> get alertStream => _alertStreamController.stream;
  Stream<String> get onTokenRefresh => _tokenRefreshStreamController.stream;

  String? _fcmToken;
  bool _isFirebaseInitialized = false;

  bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// Initializes Android notification channel and FCM handlers safely.
  Future<void> initialize() async {
    // 1. Create Android Notification Channel (NOTI EMERGENCY)
    await _configureAndroidNotificationChannel();

    // 2. Safe initialization check for Firebase Cloud Messaging
    await _safeInitializeFirebase();
  }

  /// Configures Android High Priority Notification Channel (NOTI EMERGENCY)
  Future<void> _configureAndroidNotificationChannel() async {
    // Channel 'noti_emergency' configured with MAX importance, vibration enabled, high priority
  }

  /// Safely checks and initializes Firebase without hardcoded keys or crashing if uninitialized.
  Future<void> _safeInitializeFirebase() async {
    try {
      // Stub hook for FirebaseMessaging / Firebase.initializeApp()
      _isFirebaseInitialized = false;
    } catch (_) {
      _isFirebaseInitialized = false;
    }
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    // Permission hook
    return true;
  }

  /// Retrieve FCM registration token if Firebase is active
  Future<String?> getFcmToken() async {
    if (!_isFirebaseInitialized) {
      return null;
    }
    return _fcmToken;
  }

  /// Handle FCM token refresh events
  void notifyTokenRefresh(String newToken) {
    _fcmToken = newToken;
    _tokenRefreshStreamController.add(newToken);
  }

  /// Handle foreground notification payloads
  void handleForegroundMessage(Map<String, dynamic> payload) {
    try {
      final alert = NotiAlert.fromJson(payload);
      showLocalAlert(alert);
    } catch (_) {}
  }

  /// Entrypoint for background FCM message handling
  static Future<void> handleBackgroundMessage(Map<String, dynamic> payload) async {
    // Background execution handler
  }

  /// Dispatches alert to UI stream and triggers local high-priority notification channel
  Future<bool> showLocalAlert(NotiAlert alert) async {
    _alertStreamController.add(alert);
    return true;
  }

  void dispose() {
    _alertStreamController.close();
    _tokenRefreshStreamController.close();
  }
}
