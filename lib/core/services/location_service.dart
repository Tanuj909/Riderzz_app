import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

/// A clean, standalone service for location permissions and GPS access.
/// This handles all low-level geolocator interactions.
class LocationService {
  Future<LocationPermission> requestPermission() async {
    // 1. Check current permission status first
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission from the user
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: Permission after request → $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission permanently denied.');
      await Geolocator.openAppSettings();
      return permission;
    }

    // 2. Check if location services (GPS) are enabled.
    // If we have permission, ensure the GPS is actually turned on.
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled. Prompting to enable.');
        // Use the location package to show the native Google Play Services dialog
        loc.Location location = loc.Location();
        bool isTurnedOn = await location.requestService();
        if (!isTurnedOn) {
          debugPrint('LocationService: User declined to turn on location services.');
        }
      }
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
