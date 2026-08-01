import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncherService {
  static Future<void> launchMaps({
    required double latitude,
    required double longitude,
  }) async {
    final nativeUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=l');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (innerError) {
        debugPrint('Fallback map launch failed: $innerError');
      }
    }
  }

  /// Opens Google Maps navigation from [originLat],[originLng] to [destLat],[destLng].
  /// Falls back to web URL if the native app is not available.
  static Future<void> launchNavigation({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    // Google Maps native deep-link with explicit origin
    final nativeUri = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );
    // Web URL with origin & destination
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching navigation: $e');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (innerError) {
        debugPrint('Fallback navigation launch failed: $innerError');
      }
    }
  }
}
