import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/driver/home/data/datasource/driver_remote_datasource.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';

// The callback function must be a top-level or static function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundLocationService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'driver_location_tracking',
        channelName: 'Driver Location Tracker',
        channelDescription: 'Maintains live tracking of the driver location.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(2000), // Repeat every 2 seconds to support active booking rate
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Riderzz Driver',
      notificationText: 'Sharing your live location',
      callback: startCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<bool> stop() async {
    if (!await FlutterForegroundTask.isRunningService) {
      return true;
    }
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }
}

class ForegroundTaskHandler extends TaskHandler {
  DriverRepository? _driverRepository;
  Position? _latestPosition;
  Position? _lastSentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _hasActiveBooking = false;
  DateTime? _lastAttemptTime;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('ForegroundTaskHandler: Started background service isolate.');

    // 1. Load custom base URL saved from the main isolate
    final savedBaseUrl = await FlutterForegroundTask.getData<String>(key: 'api_base_url');
    if (savedBaseUrl != null) {
      ApiConstants.customBaseUrl = savedBaseUrl;
      debugPrint('ForegroundTaskHandler: Configured baseUrl: $savedBaseUrl');
    }

    // Load initial active booking state
    _hasActiveBooking = await FlutterForegroundTask.getData<bool>(key: 'has_active_booking') ?? false;
    debugPrint('ForegroundTaskHandler: Loaded initial active booking status: $_hasActiveBooking');

    // 2. Initialize dependencies for HTTP requests in this separate isolate
    final storage = SecureStorageService();
    final apiClient = ApiClient(storageService: storage);
    final remoteDataSource = DriverRemoteDataSource(apiClient);
    _driverRepository = DriverRepository(remoteDataSource);

    // 3. Obtain initial location
    try {
      _latestPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('ForegroundTaskHandler: Failed to get initial position: $e');
    }

    // 4. Start listening to GPS stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _latestPosition = position;
    }, onError: (e) {
      debugPrint('ForegroundTaskHandler: GPS stream error: $e');
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_latestPosition == null) {
      debugPrint('ForegroundTaskHandler: No position available to send.');
      return;
    }
    if (_driverRepository == null) {
      debugPrint('ForegroundTaskHandler: Repository not initialized.');
      return;
    }

    // Determine target interval: 2 seconds if booking active, 10 seconds otherwise
    final requiredInterval = _hasActiveBooking
        ? const Duration(seconds: 2)
        : const Duration(seconds: 10);

    if (_lastAttemptTime != null) {
      final elapsed = timestamp.difference(_lastAttemptTime!);
      if (elapsed < requiredInterval) {
        // Skip this repeat check because not enough time has elapsed
        return;
      }
    }

    // Filter duplicate/stationary updates using a 5-meter movement threshold
    if (_lastSentPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        _latestPosition!.latitude,
        _latestPosition!.longitude,
      );
      if (distance < 5.0) {
        debugPrint('ForegroundTaskHandler: Stationary (moved $distance m, threshold: 5.0m). Skipping API update.');
        _lastAttemptTime = timestamp; // Record attempt time even if skipped to avoid spamming checks
        return;
      }
    }

    // Send location update to the backend
    try {
      await _driverRepository!.updateLocation(
        _latestPosition!.latitude,
        _latestPosition!.longitude,
      );
      _lastSentPosition = _latestPosition;
      _lastAttemptTime = timestamp;
      debugPrint('ForegroundTaskHandler: Location updated: ${_latestPosition!.latitude}, ${_latestPosition!.longitude} (activeBooking: $_hasActiveBooking)');
    } catch (e) {
      // Offline/connection errors are handled gracefully without crashing the service
      debugPrint('ForegroundTaskHandler: Failed to update location (offline/server error): $e');
      _lastAttemptTime = timestamp; // Record attempt time even if failed to avoid instant retries
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('ForegroundTaskHandler: Service destroyed. Releasing all resources.');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _latestPosition = null;
    _lastSentPosition = null;
    _driverRepository = null;
  }

  @override
  void onReceiveData(Object data) {
    debugPrint('ForegroundTaskHandler: Data received from UI: $data');
    if (data is bool) {
      _hasActiveBooking = data;
      debugPrint('ForegroundTaskHandler: Set _hasActiveBooking to $_hasActiveBooking');
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
