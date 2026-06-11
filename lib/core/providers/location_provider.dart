import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riderzz_app/core/services/location_service.dart';

/// State management provider for the user's current location.
/// Holds coordinates, reverse-geocoded address, and permission status.
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;

  LocationProvider(this._locationService);

  // ── State ──────────────────────────────────────────────────────────────

  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _isInitialized = false;

  // ── Getters ────────────────────────────────────────────────────────────

  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentAddress => _currentAddress;
  LocationPermission get permissionStatus => _permissionStatus;
  bool get isInitialized => _isInitialized;

  /// Returns true if we have valid coordinates.
  bool get hasLocation => _currentLatitude != null && _currentLongitude != null;

  // ── Public Methods ─────────────────────────────────────────────────────

  /// Requests permission, fetches current position, and reverse geocodes it.
  /// Call this once during app startup (e.g., from the splash screen).
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permission
    _permissionStatus = await _locationService.requestPermission();
    debugPrint('LocationProvider: Permission → $_permissionStatus');

    if (_permissionStatus == LocationPermission.denied ||
        _permissionStatus == LocationPermission.deniedForever) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // 2. Get current position
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // 3. Reverse geocode to get a readable address
      await _reverseGeocode(position.latitude, position.longitude);
    }

    _isInitialized = true;
    notifyListeners();
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = <String>[];

        if (pm.name != null && pm.name!.isNotEmpty && pm.name != pm.subLocality) {
          parts.add(pm.name!);
        }
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
          parts.add(pm.subLocality!);
        }
        if (pm.locality != null && pm.locality!.isNotEmpty) {
          parts.add(pm.locality!);
        }
        if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) {
          parts.add(pm.administrativeArea!);
        }
        if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
          parts.add(pm.postalCode!);
        }
        if (pm.country != null && pm.country!.isNotEmpty) {
          parts.add(pm.country!);
        }

        _currentAddress = parts.isEmpty ? null : parts.join(', ');
      }
    } catch (e) {
      debugPrint('LocationProvider: Reverse geocode failed → $e');
    }
  }
}
