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
}
