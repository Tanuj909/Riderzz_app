import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper utility to generate smooth, premium curved route lines (floating bridge dome shape)
/// between two coordinates using clean vector mathematics and Cubic Bezier curves.
class CurvedRouteGenerator {
  // Configuration Constants
  static const double defaultCurveFactor = 0.20; // 20% of the straight-line distance
  static const double minOffset = 0.0001;        // Minimum bulge (approx 11m) in coordinate space
  static const double maxOffset = 0.05;          // Maximum bulge (approx 5.5km) in coordinate space

  /// Generates a list of LatLng points representing a symmetric Cubic Bezier curve
  /// between [start] and [end], bulging perpendicularly (Northward/Upward) to the direction of travel.
  /// Exactly 200 points are generated for maximum visual smoothness.
  static List<LatLng> generateCurvedRoute(
    LatLng start,
    LatLng end, {
    int numPoints = 200,
    double curveFactor = defaultCurveFactor,
  }) {
    if (numPoints < 2) return [start, end];

    final List<LatLng> points = [];

    // 1. Calculate direction vector
    final double latDiff = end.latitude - start.latitude;
    final double lngDiff = end.longitude - start.longitude;

    // 2. Magnitude (Euclidean distance in coordinate space)
    final double distance = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);

    if (distance == 0) {
      return List.filled(numPoints, start);
    }

    // 3. Normalization (unit direction vector)
    final double dirLat = latDiff / distance;
    final double dirLng = lngDiff / distance;

    // 4. Perpendicular Vector (Rotated 90 degrees counter-clockwise)
    // For vector (dx, dy), the counter-clockwise perpendicular is (-dy, dx).
    // In our coordinate space: (lat, lng) -> (-lng, lat)
    double perpLat = -dirLng;
    double perpLng = dirLat;

    // To ensure the dome curve always arches Northward/Upward on the map
    // (creating a consistent dome shape irrespective of travel direction),
    // we invert the perpendicular vector if its latitude component is negative.
    if (perpLat < 0) {
      perpLat = -perpLat;
      perpLng = -perpLng;
    }

    // 5. Scale & Clamp perpendicular offset (curve height)
    final double offsetVal = distance * curveFactor;
    final double clampedOffset = offsetVal.clamp(minOffset, maxOffset);

    // 6. Calculate Control Points C1 and C2 at 1/3 and 2/3 of the baseline
    // C1 = start + (1/3 * direction) + (clampedOffset * perpendicular)
    final LatLng control1 = LatLng(
      start.latitude + (1.0 / 3.0 * latDiff) + (clampedOffset * perpLat),
      start.longitude + (1.0 / 3.0 * lngDiff) + (clampedOffset * perpLng),
    );

    // C2 = start + (2/3 * direction) + (clampedOffset * perpendicular)
    final LatLng control2 = LatLng(
      start.latitude + (2.0 / 3.0 * latDiff) + (clampedOffset * perpLat),
      start.longitude + (2.0 / 3.0 * lngDiff) + (clampedOffset * perpLng),
    );

    // 7. Generate intermediate points along the Cubic Bezier Curve
    // B(t) = (1-t)^3 * P0 + 3*(1-t)^2*t * C1 + 3*(1-t)*t^2 * C2 + t^3 * P3
    for (int i = 0; i <= numPoints; i++) {
      final double t = i / numPoints;
      final double oneMinusT = 1.0 - t;
      
      final double lat = (oneMinusT * oneMinusT * oneMinusT * start.latitude) +
          (3.0 * oneMinusT * oneMinusT * t * control1.latitude) +
          (3.0 * oneMinusT * t * t * control2.latitude) +
          (t * t * t * end.latitude);
          
      final double lng = (oneMinusT * oneMinusT * oneMinusT * start.longitude) +
          (3.0 * oneMinusT * oneMinusT * t * control1.longitude) +
          (3.0 * oneMinusT * t * t * control2.longitude) +
          (t * t * t * end.longitude);

      points.add(LatLng(lat, lng));
    }

    return points;
  }
}
