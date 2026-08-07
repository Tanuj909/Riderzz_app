import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';

/// Thin Flutter facade for the Android-native floating overlay.
///
/// Flutter reports stable app lifecycle transitions only. The Android service
/// owns rendering, drag handling, permission state, foreground-service state,
/// position persistence, and restoring the activity.
class NativeOverlayController {
  NativeOverlayController._();

  static const _channel = MethodChannel('com.example.riderzz_app/overlay');
  static const _debounce = Duration(milliseconds: 350);

  static Timer? _backgroundTimer;
  static bool _initialized = false;
  static bool _permissionPromptPending = false;
  static bool _permissionPromptVisible = false;

  static void initialize() {
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onNativeEvent);
  }

  static void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    if (_initialized) _channel.setMethodCallHandler(null);
    _initialized = false;
  }

  /// Debounces Flutter's duplicate paused/hidden notifications. Native code
  /// repeats this protection and verifies that no activity is visible.
  static void onAppMovedToBackground() {
    if (!Platform.isAndroid) return;
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(_debounce, () {
      _invoke('onAppLifecycle', {'state': 'background'});
    });
  }

  static void onAppReturnedToForeground() {
    if (!Platform.isAndroid) return;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _invoke('onAppLifecycle', {'state': 'foreground'});
    _showPermissionRationaleIfNeeded();
  }

  static Future<dynamic> _onNativeEvent(MethodCall call) async {
    switch (call.method) {
      case 'permissionRequired':
        _permissionPromptPending = true;
        return null;
      case 'overlayError':
        debugPrint('[NativeOverlay] ${call.arguments}');
        return null;
      default:
        debugPrint('[NativeOverlay] unknown native event: ${call.method}');
    }
  }

  static void _showPermissionRationaleIfNeeded() {
    if (!_permissionPromptPending || _permissionPromptVisible) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_permissionPromptPending || _permissionPromptVisible) return;
      final context = AppRoutes.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      _permissionPromptVisible = true;
      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Stay connected',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Allow Riderzz to display a small floating icon while the app is '
            'in the background.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now', style: TextStyle(color: Colors.black54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE31C2E),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Allow', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      _permissionPromptVisible = false;
      _permissionPromptPending = false;
      await _invoke(
        approved == true
            ? 'requestOverlayPermission'
            : 'suppressOverlayPermissionPrompt',
      );
    });
  }

  static Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error) {
      debugPrint('[NativeOverlay] $method failed: ${error.message}');
    } on MissingPluginException {
      // Expected on non-Android test targets and during engine teardown.
    }
  }
}
