import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/services/foreground_location_service.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';

/// Standalone service that handles driver location tracking.
/// Delegates task management to the Android Foreground Service (ForegroundLocationService).
class LocationTrackingService {
  final DriverRepository _driverRepository;
  bool _isTracking = false;
  bool _hasPromptedBackground = false;
  bool _hasActiveBooking = false;

  LocationTrackingService(this._driverRepository);

  bool get isTracking => _isTracking;

  /// Check if the Foreground Service is actively running.
  Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Update active booking status and inform background isolate if running.
  void updateHasActiveBooking(bool hasActive) {
    if (_hasActiveBooking == hasActive) return;
    _hasActiveBooking = hasActive;
    if (_isTracking) {
      FlutterForegroundTask.sendDataToTask(hasActive);
      debugPrint('LocationTrackingService: Sent hasActiveBooking = $hasActive to foreground task.');
    }
  }

  /// Start Foreground Service background tracking.
  Future<void> start({bool hasActiveBooking = false}) async {
    _hasActiveBooking = hasActiveBooking;
    if (_isTracking || await FlutterForegroundTask.isRunningService) {
      _isTracking = true;
      debugPrint('LocationTrackingService: Foreground service is already running.');
      // Keep background isolate in sync
      FlutterForegroundTask.sendDataToTask(_hasActiveBooking);
      return;
    }

    // 1. Request Notification Permission (Android 13+)
    await FlutterForegroundTask.requestNotificationPermission();

    // 2. Check & Request Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LocationTrackingService: Location permission denied.');
      return;
    }

    // 3. Request Background Location Permission (Allow all the time) via default system redirect
    if (permission == LocationPermission.whileInUse && !_hasPromptedBackground) {
      _hasPromptedBackground = true;
      permission = await Geolocator.requestPermission();
    }

    // 4. Save Api Base URL and initial booking state so background isolate can retrieve it
    await FlutterForegroundTask.saveData(
      key: 'api_base_url',
      value: ApiConstants.baseUrl,
    );
    await FlutterForegroundTask.saveData(
      key: 'has_active_booking',
      value: _hasActiveBooking,
    );

    // 5. Start Android Foreground Service
    final success = await ForegroundLocationService.start();
    if (success) {
      _isTracking = true;
      debugPrint('LocationTrackingService: Foreground service started successfully.');
    } else {
      debugPrint('LocationTrackingService: Failed to start foreground service.');
    }
  }

  /// Stop Foreground Service.
  Future<void> stop() async {
    if (!_isTracking && !await FlutterForegroundTask.isRunningService) {
      debugPrint('LocationTrackingService: Foreground service is already stopped.');
      return;
    }
    await ForegroundLocationService.stop();
    _isTracking = false;
    _hasPromptedBackground = false; // Reset session prompt on stop
    debugPrint('LocationTrackingService: Stopped.');
  }

  /// Expose helper to prompt the driver to disable battery optimization.
  Future<bool> requestIgnoreBatteryOptimization() async {
    return await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  /// Clean up resources on disposal.
  void dispose() {
    stop();
  }
}
