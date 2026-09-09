import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Models geographic coordinates extracted from an external source.
class LatLngCoordinates {
  final double latitude;
  final double longitude;

  const LatLngCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'LatLngCoordinates($latitude, $longitude)';
}

/// Pure Dart URI parser strictly for Phase 1 `geo:` schemes.
class GeoUriParser {
  static final RegExp _standardGeoRegex =
      RegExp(r'^geo:\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)', caseSensitive: false);
  static final RegExp _queryGeoRegex =
      RegExp(r'[?&]q=\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)', caseSensitive: false);

  static LatLngCoordinates? parse(String rawUri) {
    final trimmed = rawUri.trim();
    if (!trimmed.toLowerCase().startsWith('geo:')) return null;

    double? lat;
    double? lng;

    // 1. Query parameter format: geo:0,0?q=lat,lng or geo:0,0?q=lat,lng(Label)
    if (trimmed.contains('?q=') || trimmed.contains('&q=')) {
      final match = _queryGeoRegex.firstMatch(trimmed);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lng = double.tryParse(match.group(2)!);
      }
    }

    // 2. Standard format: geo:lat,lng or geo:lat,lng?z=16
    if (lat == null || lng == null) {
      final match = _standardGeoRegex.firstMatch(trimmed);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lng = double.tryParse(match.group(2)!);
      }
    }

    // 3. Mathematical and geographic bounds validation
    if (lat == null || lng == null) return null;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) return null;
    if (lat < -90.0 || lat > 90.0) return null;
    if (lng < -180.0 || lng > 180.0) return null;
    if (lat == 0.0 && lng == 0.0) return null; // Reject dummy unresolved coordinates

    return LatLngCoordinates(latitude: lat, longitude: lng);
  }
}

/// Singleton service managing Android -> Flutter external location intents.
class SharedLocationService {
  SharedLocationService._internal() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static final SharedLocationService instance = SharedLocationService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.example.riderzz_app/shared_location');

  final StreamController<LatLngCoordinates> _locationController =
      StreamController<LatLngCoordinates>.broadcast();

  Stream<LatLngCoordinates> get onLocationStream => _locationController.stream;

  // In-memory cache for unauthenticated / splash delay
  LatLngCoordinates? _pendingLocation;
  LatLngCoordinates? get pendingLocation => _pendingLocation;

  DateTime? _lastDispatchedTime;
  LatLngCoordinates? _lastDispatchedCoords;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onLocationReceived') {
      final rawUri = call.arguments as String?;
      if (rawUri != null) {
        _handleRawUri(rawUri);
      }
    }
  }

  /// Consumes cold-start location from Android native buffer.
  Future<LatLngCoordinates?> consumeInitialLocation() async {
    try {
      final rawUri = await _channel.invokeMethod<String>('getInitialLocation');
      if (rawUri != null && rawUri.isNotEmpty) {
        final coords = GeoUriParser.parse(rawUri);
        if (coords != null) {
          _pendingLocation = coords;
          return coords;
        }
      }
    } on PlatformException catch (e) {
      debugPrint('[SharedLocation] Error fetching initial location: $e');
    }
    return _pendingLocation;
  }

  void _handleRawUri(String rawUri) {
    final coords = GeoUriParser.parse(rawUri);
    if (coords == null) {
      debugPrint('[SharedLocation] Rejected invalid geo URI: $rawUri');
      return;
    }

    // Debounce duplicate events within 1.5 seconds
    final now = DateTime.now();
    if (_lastDispatchedTime != null &&
        now.difference(_lastDispatchedTime!).inMilliseconds < 1500 &&
        _lastDispatchedCoords != null &&
        _lastDispatchedCoords!.latitude == coords.latitude &&
        _lastDispatchedCoords!.longitude == coords.longitude) {
      debugPrint('[SharedLocation] Debounced duplicate event.');
      return;
    }

    _lastDispatchedTime = now;
    _lastDispatchedCoords = coords;
    _pendingLocation = coords;
    _locationController.add(coords);
  }

  /// Clears any consumed pending location.
  void clearPendingLocation() {
    _pendingLocation = null;
  }
}
