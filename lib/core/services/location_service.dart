import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A clean, standalone service for location permissions and GPS access.
/// This handles all low-level geolocator interactions.
class LocationService {
  /// Checks and requests location permission.
  /// Returns the resulting [LocationPermission] status.
  Future<LocationPermission> requestPermission() async {
    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission from the user
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: Permission after request → $permission');
    }

    // If permission is active, check if device GPS / location services are on
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled. Prompting to enable.');
        await Geolocator.openLocationSettings();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission permanently denied.');
    }

    return permission;
  }

  /// Gets the device's current position.
  /// Returns `null` if permission is not granted or location services are off.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('LocationService: Error getting position → $e');
      return null;
    }
  }
}
