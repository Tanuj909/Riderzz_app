import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable UI banner that prompts Drivers or Customers to enable notifications
/// if they haven't allowed notification permissions yet.
///
/// Automatically hides itself if permissions are granted, and dynamically re-checks
/// when the user resumes the app (e.g., from system Settings).
class NotificationPermissionBanner extends StatefulWidget {
  final String? role; // 'DRIVER' or 'CUSTOMER'
  final String? title;
  final String? message;
  final EdgeInsetsGeometry? margin;

  const NotificationPermissionBanner({
    super.key,
    this.role,
    this.title,
    this.message,
    this.margin,
  });

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner> with WidgetsBindingObserver {
  bool _isPermissionGranted = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifyPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPermission();
    }
  }

  Future<void> _verifyPermission() async {
    final granted = await _checkPermissionStatus();
    if (mounted && _isPermissionGranted != granted) {
      setState(() {
        _isPermissionGranted = granted;
      });
    }
  }

  static Future<bool> _checkPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? areEnabled = await androidPlugin?.areNotificationsEnabled();
        if (areEnabled == false) return false;
      }

      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[NotificationPermissionBanner] check error: $e');
      return true; // Fail-safe: do not block or flash on check error
    }
  }

  Future<void> _handleEnableNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. First request permission natively
      if (Platform.isAndroid) {
        final androidPlugin = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 2. Re-check status
      final granted = await _checkPermissionStatus();
      if (granted) {
        if (mounted) {
          setState(() {
            _isPermissionGranted = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled successfully! 🔔'),
              backgroundColor: Color(0xFF16A34A),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 3. If still denied (e.g. permanently denied), open OS Settings
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Notifications in App Settings.'),
            backgroundColor: Color(0xFFE2A03F),
            duration: Duration(seconds: 3),
          ),
        );
      }
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('[NotificationPermissionBanner] request error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionGranted) {
      return const SizedBox.shrink();
    }

    final isDriver = widget.role == 'DRIVER';
    final title = widget.title ?? 'Turn on notifications';
    final message = widget.message ??
        (isDriver
            ? 'Enable notifications to get instant ride alerts & booking requests.'
            : 'Enable notifications for ride updates, driver arrival & offers.');

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05121214),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFD90429),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _isLoading ? null : _handleEnableNotifications,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFD90429),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Turn On',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

