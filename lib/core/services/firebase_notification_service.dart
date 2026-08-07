import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riderzz_app/features/notification/data/repositories/notification_repository.dart';

/// Phase 1 + Phase 2 – Firebase Cloud Messaging Service
///
/// Responsibilities:
/// 1. Initialize Firebase Messaging
/// 2. Request notification permissions (Android 13+ / iOS)
/// 3. Generate & listen for FCM token refresh
/// 4. Register foreground message listener
/// 5. Handle notification tap (app opened from background/terminated)
/// 6. Upload refreshed tokens to the backend via [NotificationRepository]
///
/// This class is a singleton – use [FirebaseNotificationService.instance].
class FirebaseNotificationService {
  FirebaseNotificationService._internal();

  static final FirebaseNotificationService instance =
      FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  /// Current FCM token (null until [initialize] completes).
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Injected after Provider tree is ready – used for token refresh uploads.
  NotificationRepository? _notificationRepository;

  /// Inject the [NotificationRepository] so token-refresh events can
  /// automatically upload the new token to the backend.
  void setNotificationRepository(NotificationRepository repo) {
    _notificationRepository = repo;
    debugPrint('[FCM] NotificationRepository injected.');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Call once during app startup (after [Firebase.initializeApp]).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request permission
      await _requestPermission();

      // 2. Get the initial FCM token
      await _getFcmToken();

      // 3. Listen for token refresh events
      _listenTokenRefresh();

      // 4. Configure foreground notification presentation (iOS)
      await _configureForegroundPresentation();

      // 5. Setup message listeners
      _setupMessageListeners();

      _isInitialized = true;
      debugPrint('[FCM] ✅ FirebaseNotificationService initialized.');
    } catch (e) {
      debugPrint('[FCM] ❌ Initialization failed: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Permission
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[FCM] Permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] ⚠️ User denied notification permission.');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FCM Token
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _getFcmToken() async {
    _fcmToken = await _messaging.getToken();
    debugPrint('[FCM] 🔑 FCM Token: $_fcmToken');
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('[FCM] 🔄 Token refreshed: $newToken');

      // Phase 2: Upload the refreshed token to the backend
      if (_notificationRepository != null) {
        debugPrint('[FCM] Uploading refreshed token...');
        await _notificationRepository!.registerDeviceToken(newToken);
      } else {
        debugPrint('[FCM] ⚠️ NotificationRepository not injected, '
            'skipping token upload.');
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Foreground presentation (iOS-specific)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _configureForegroundPresentation() async {
    if (!Platform.isIOS) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] iOS foreground presentation options set.');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Message Listeners
  // ──────────────────────────────────────────────────────────────────────────

  void _setupMessageListeners() {
    // ── Foreground messages ──────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('========== FCM FOREGROUND MESSAGE ==========');
      debugPrint('Message ID : ${message.messageId}');
      debugPrint('Title      : ${message.notification?.title}');
      debugPrint('Body       : ${message.notification?.body}');
      debugPrint('Data       : ${message.data}');
      debugPrint('=============================================');

      // TODO (Phase 3): Show a local notification using LocalNotificationService
    });

    // ── Notification tap – app was in background ────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('========== FCM NOTIFICATION TAP (BG) ==========');
      debugPrint('Message ID : ${message.messageId}');
      debugPrint('Data       : ${message.data}');
      debugPrint('================================================');

      // TODO (Phase 3): Navigate to appropriate screen based on data
    });

    // ── Notification tap – app was terminated ────────────────────────────
    _handleTerminatedNotification();
  }

  Future<void> _handleTerminatedNotification() async {
    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('========== FCM INITIAL MESSAGE (TERMINATED) ==========');
      debugPrint('Message ID : ${initialMessage.messageId}');
      debugPrint('Data       : ${initialMessage.data}');
      debugPrint('======================================================');

      // TODO (Phase 3): Navigate to appropriate screen based on data
    }
  }
}
