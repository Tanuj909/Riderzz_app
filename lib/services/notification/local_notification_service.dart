import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riderzz_app/core/services/reward_notification_coordinator.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static const _channelId = 'booking_requests_high_v1';
  static const _channelName = 'Booking Requests';
  static const _channelDescription =
      'Alerts for new delivery booking requests.';

  static const _bookingChannelId = 'new_booking_alert_v1';
  static const _bookingChannelName = 'New Booking Alerts';
  static const _bookingChannelDescription =
      'Alerts with custom sound for new delivery booking requests.';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static int generateLocalId(String notificationId) {
    return notificationId.hashCode.abs() % (1 << 31);
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_overlay_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final Map<String, dynamic> data =
                  jsonDecode(payload) as Map<String, dynamic>;
              final type = data['type']?.toString();
              final actionUrl = data['actionUrl']?.toString();
              if (type == 'REWARD_RECEIVED' ||
                  actionUrl == '/customer/coupons' ||
                  actionUrl == '/rewards/customer/coupons') {
                RewardNotificationCoordinator.instance
                    .handleRewardFromLocalPayload(data);
              }
            } catch (e) {
              debugPrint('[LocalNotificationService] Non-JSON payload on tap: $payload');
            }
          }
        },
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin == null) {
        _isInitialized = true;
        return;
      }

      debugPrint('[NOTIFICATION_CHANNEL] Creating channel: $_channelId');
      debugPrint('[NOTIFICATION_CHANNEL] Importance: HIGH');
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      debugPrint('[NOTIFICATION_CHANNEL] Creating channel: $_bookingChannelId');
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _bookingChannelId,
          _bookingChannelName,
          description: _bookingChannelDescription,
          importance: Importance.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('booking_alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        ),
      );

      final notificationsEnabled = await androidPlugin
          .areNotificationsEnabled();
      if (notificationsEnabled != true) {
        final permissionGranted = await androidPlugin
            .requestNotificationsPermission();
        if (permissionGranted != true) {
          debugPrint(
            '[LocalNotificationService] Notification permission was not granted.',
          );
        }
      }

      _isInitialized = true;
    } catch (error) {
      debugPrint('[LocalNotificationService] Initialization failed: $error');
    }
  }

  static Future<void> showBookingNotification({
    required BookingModel booking,
    String? notificationId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin == null ||
            await androidPlugin.areNotificationsEnabled() != true) {
          return;
        }
      }

      const title = 'New Delivery Request';
      final pickup = _textOrFallback(booking.pickupAddressName);
      final drop = _textOrFallback(booking.dropAddressName);
      final fare = booking.totalFare > 0
          ? '₹${booking.totalFare.toStringAsFixed(2)}'
          : 'Not available';
      final body = 'Estimated Fare: $fare\nPickup: $pickup\nDrop: $drop';

      debugPrint('========== LOCAL NOTIFICATION ==========');
      debugPrint('Showing booking notification');
      debugPrint('Booking ID: ${booking.id}');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('========================================');

      int localId;
      if (notificationId != null && notificationId.isNotEmpty) {
        localId = generateLocalId(notificationId);
        debugPrint('[LOCAL_ID] notificationId: $notificationId');
        debugPrint('[LOCAL_ID] localNotificationId: $localId');
      } else {
        localId = booking.id > 0
            ? booking.id
            : DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      }

      if (Platform.isIOS) {
        try {
          const MethodChannel channel = MethodChannel('com.riderzz.app/haptic');
          await channel.invokeMethod('playBookingHaptic');
        } catch (e) {
          debugPrint('Error playing iOS haptic: $e');
        }
      }

      await _notifications.show(
        id: localId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _bookingChannelId,
            _bookingChannelName,
            channelDescription: _bookingChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('booking_alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
            autoCancel: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'booking_alert.caf',
          ),
        ),
        payload: booking.id.toString(),
      );
    } catch (error) {
      debugPrint(
        '[LocalNotificationService] Unable to show booking notification: $error',
      );
    }
  }

  static Future<void> showGenericNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isBookingAlert = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin == null ||
            await androidPlugin.areNotificationsEnabled() != true) {
          return;
        }
      }

      debugPrint('========== LOCAL NOTIFICATION ==========');
      debugPrint('Showing generic notification');
      debugPrint('ID: $id');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('========================================');

      if (isBookingAlert && Platform.isIOS) {
        try {
          const MethodChannel channel = MethodChannel('com.riderzz.app/haptic');
          await channel.invokeMethod('playBookingHaptic');
        } catch (e) {
          debugPrint('Error playing iOS haptic: $e');
        }
      }

      await _notifications.show(
        id: id > 0 ? id : DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: isBookingAlert
              ? AndroidNotificationDetails(
                  _bookingChannelId,
                  _bookingChannelName,
                  channelDescription: _bookingChannelDescription,
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  sound: const RawResourceAndroidNotificationSound('booking_alert'),
                  enableVibration: true,
                  vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
                  autoCancel: true,
                  fullScreenIntent: true,
                  visibility: NotificationVisibility.public,
                )
              : const AndroidNotificationDetails(
                  _channelId,
                  _channelName,
                  channelDescription: _channelDescription,
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                  autoCancel: true,
                ),
          iOS: isBookingAlert
              ? const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  sound: 'booking_alert.caf',
                )
              : const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
        ),
        payload: payload,
      );
    } catch (error) {
      debugPrint(
        '[LocalNotificationService] Unable to show generic notification: $error',
      );
    }
  }

  static String _textOrFallback(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty || trimmedValue == 'N/A'
        ? 'Not available'
        : trimmedValue;
  }
}
