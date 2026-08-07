import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static const _channelId = 'booking_requests';
  static const _channelName = 'Booking Requests';
  static const _channelDescription =
      'Alerts for new delivery booking requests.';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_overlay_notification'),
      );
      await _notifications.initialize(settings: initializationSettings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin == null) {
        _isInitialized = true;
        return;
      }

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
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null ||
          await androidPlugin.areNotificationsEnabled() != true) {
        return;
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

      await _notifications.show(
        id: booking.id > 0
            ? booking.id
            : DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
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

  static String _textOrFallback(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty || trimmedValue == 'N/A'
        ? 'Not available'
        : trimmedValue;
  }
}
