import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';

/// Standalone service that handles driver location tracking.
/// Owns the GPS stream, 5-second timer, and PUT /driver/location API call.
/// Does NOT extend ChangeNotifier — no UI rebuilds triggered.
class LocationTrackingService {
  final DriverRepository _driverRepository;

  Position? _latestPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationUpdateTimer;
  bool _isTracking = false;

  LocationTrackingService(this._driverRepository);

  Position? get latestPosition => _latestPosition;
  bool get isTracking => _isTracking;

  /// Start GPS stream + 5-second periodic timer.
  /// Call this once from DriverHomeScreen.initState().
  /// Idempotent — calling multiple times won't create duplicate streams.
  Future<void> start() async {
    if (_isTracking) return;

    // 1. Check & Request Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LocationTrackingService: Permission denied.');
      return;
    }

    _isTracking = true;

    // 2. Get initial position
    try {
      _latestPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('LocationTrackingService: Failed to get initial position: $e');
    }

    // 3. Start GPS Position Stream — just updates _latestPosition, no notify
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _latestPosition = position;
    }, onError: (e) {
      debugPrint('LocationTrackingService: Stream error: $e');
    });

    // 4. Start 5-second timer — sends location to server
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendLocationUpdate(),
    );

    debugPrint('LocationTrackingService: Started.');
  }

  /// Stop GPS stream + timer.
  void stop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    debugPrint('LocationTrackingService: Stopped.');
  }

  /// Called by the 5-sec timer. Sends PUT only if we have a position.
  /// The "is driver online?" check is NOT here — the timer only runs
  /// while the driver IS online (start/stop is toggled by setOnlineStatus).
  Future<void> _sendLocationUpdate() async {
    if (_latestPosition == null) return;

    try {
      await _driverRepository.updateLocation(
        _latestPosition!.latitude,
        _latestPosition!.longitude,
      );
      debugPrint(
        'LocationTrackingService: Sent ${_latestPosition!.latitude}, ${_latestPosition!.longitude}',
      );
    } catch (e) {
      debugPrint('LocationTrackingService: Failed to send: $e');
    }
  }

  /// Call this when disposing the service (e.g., app exit).
  void dispose() {
    stop();
  }
}
