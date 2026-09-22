import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

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
  static Timer? _delayedPromptTimer;
  static bool _initialized = false;
  static bool _permissionPromptVisible = false;
  static bool _sessionPromptShown = false;

  /// Helper to verify whether current logged-in user has the DRIVER role.
  static bool _isDriverActive() {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return false;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.currentUser?.role == 'DRIVER';
    } catch (_) {
      return false;
    }
  }

  static void initialize() {
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onNativeEvent);
  }

  static void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _delayedPromptTimer?.cancel();
    _delayedPromptTimer = null;
    if (_initialized) _channel.setMethodCallHandler(null);
    _initialized = false;
  }

  /// Checks whether Android overlay permission is already granted.
  static Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Explicitly hides and dismisses any active native overlay.
  static Future<void> hideOverlay() async {
    if (!Platform.isAndroid) return;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    await _invoke('hideOverlay');
  }

  /// Schedules the 'Stay connected' permission prompt 20 seconds after app open
  /// for drivers, showing at most once per app launch session.
  static void scheduleDriverPermissionPrompt({
    Duration delay = const Duration(seconds: 20),
  }) {
    if (!Platform.isAndroid || _sessionPromptShown) return;
    _delayedPromptTimer?.cancel();
    _delayedPromptTimer = Timer(delay, () async {
      if (!_isDriverActive() || _sessionPromptShown || _permissionPromptVisible) return;
      final granted = await isPermissionGranted();
      if (granted) {
        _sessionPromptShown = true;
        return;
      }
      _showPermissionRationale();
    });
  }

  /// Debounces Flutter's duplicate paused/hidden notifications. Native code
  /// repeats this protection and verifies that no activity is visible.
  static void onAppMovedToBackground() {
    if (!Platform.isAndroid) return;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    if (!_isDriverActive()) {
      // Ensure overlay is never shown/persisted for non-drivers
      hideOverlay();
      return;
    }

    _backgroundTimer = Timer(_debounce, () {
      if (_isDriverActive()) {
        _invoke('onAppLifecycle', {'state': 'background'});
      }
    });
  }

  static void onAppReturnedToForeground() {
    if (!Platform.isAndroid) return;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _invoke('onAppLifecycle', {'state': 'foreground'});

    if (_isDriverActive()) {
      if (!_sessionPromptShown) {
        scheduleDriverPermissionPrompt();
      }
    }
  }

  static Future<dynamic> _onNativeEvent(MethodCall call) async {
    switch (call.method) {
      case 'permissionRequired':
        if (_isDriverActive() && !_sessionPromptShown) {
          scheduleDriverPermissionPrompt(delay: const Duration(seconds: 20));
        }
        return null;
      case 'overlayError':
        debugPrint('[NativeOverlay] ${call.arguments}');
        return null;
      default:
        debugPrint('[NativeOverlay] unknown native event: ${call.method}');
    }
  }

  static void _showPermissionRationale() {
    if (_permissionPromptVisible || !_isDriverActive()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_permissionPromptVisible || !_isDriverActive()) return;
      final context = AppRoutes.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      _sessionPromptShown = true;
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
      if (approved == true) {
        await _invoke('requestOverlayPermission');
      }
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


