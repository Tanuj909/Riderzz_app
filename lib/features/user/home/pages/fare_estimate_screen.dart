import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';

class FareEstimateView extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const FareEstimateView({
    super.key,
    required this.bookingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FareEstimateView> createState() => _FareEstimateViewState();
}

class _RefundStats {
  final double distance;
  final int time;
  final double baseFare;
  final double distanceFare;
  final double finalFare;
  final String? encodedPolyline;

  _RefundStats({
    required this.distance,
    required this.time,
    required this.baseFare,
    required this.distanceFare,
    required this.finalFare,
    this.encodedPolyline,
  });
}

class _FareEstimateViewState extends State<FareEstimateView> {
  _RefundStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRouteAndCalculateFare();
  }

  String _getTravelMode(String vehicleName) {
    final nameLower = vehicleName.toLowerCase();
    if (nameLower.contains('bike') ||
        nameLower.contains('scooty') ||
        nameLower.contains('scooter')) {
      return 'TWO_WHEELER';
    }
    return 'DRIVE';
  }

  double convertMetersToKm(int distanceMeters) {
    return (distanceMeters / 1000.0 * 100.0).round() / 100.0;
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) / 2;
    double dist = 12742 * math.asin(math.sqrt(a)) * 1.25; // Scale to estimate road distance
    if (dist < 1.0) dist = 1.0;
    return dist;
  }

  Future<void> _fetchRouteAndCalculateFare() async {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final pickupLat = widget.bookingData['pickupLatitude'] as double?;
    final pickupLng = widget.bookingData['pickupLongitude'] as double?;
    final dropLat = widget.bookingData['dropLatitude'] as double?;
    final dropLng = widget.bookingData['dropLongitude'] as double?;

    debugPrint('FareEstimate: Pickup ($pickupLat, $pickupLng) → Drop ($dropLat, $dropLng)');

    double distance = 8.4;
    int estTime = 28;
    String? encodedPolyline;

    if (widget.bookingData['estimatedDistanceKm'] != null) {
      distance = widget.bookingData['estimatedDistanceKm'] as double;
      estTime = widget.bookingData['estimatedDurationMin'] as int? ?? widget.bookingData['estimatedTimeMin'] as int? ?? 28;
      encodedPolyline = widget.bookingData['routePolyline'] as String?;
    } else if (pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
      try {
        final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
        if (googleApiKey.isNotEmpty) {
          final dio = Dio();
          final response = await dio.post(
            'https://routes.googleapis.com/directions/v2:computeRoutes',
            data: {
              "origin": {
                "location": {
                  "latLng": {
                    "latitude": pickupLat,
                    "longitude": pickupLng,
                  }
                }
              },
              "destination": {
                "location": {
                  "latLng": {
                    "latitude": dropLat,
                    "longitude": dropLng,
                  }
                }
              },
              "travelMode": _getTravelMode(vehicle.name),
              "routingPreference": "TRAFFIC_AWARE"
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': googleApiKey,
                'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final routes = response.data['routes'] as List?;
            if (routes != null && routes.isNotEmpty) {
              final route = routes.first;
              final distanceMeters = route['distanceMeters'] as int?;
              final durationStr = route['duration'] as String?;
              encodedPolyline = route['polyline']?['encodedPolyline'] as String?;

              if (distanceMeters != null) {
                distance = convertMetersToKm(distanceMeters);
              }

              if (durationStr != null) {
                final numericOnly = durationStr.replaceAll('s', '');
                final seconds = int.tryParse(numericOnly) ?? 0;
                estTime = (seconds / 60.0).round();
              }
            } else {
              distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
              estTime = (distance * 3.0 + 3).round();
            }
          } else {
            distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
            estTime = (distance * 3.0 + 3).round();
          }
        } else {
          distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
          estTime = (distance * 3.0 + 3).round();
        }
      } catch (e) {
        distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
        estTime = (distance * 3.0 + 3).round();
      }
    }

    final tier = widget.bookingData['applicablePricingTier'] as PricingTierModel?;
    final double baseFare = tier?.baseFare ?? vehicle.baseFare;
    final double perKmRate = tier?.perKmRate ?? vehicle.perKmRate;
    final double distanceFare = (distance * perKmRate).roundToDouble();

    final bool fastDelivery = widget.bookingData['fastDelivery'] == true;
    final double fastDeliveryCharge = widget.bookingData['fastDeliveryCharge'] as double? ?? 0.0;

    double finalFare = baseFare + distanceFare;
    if (fastDelivery) {
      finalFare += fastDeliveryCharge;
    }

    setState(() {
      _stats = _RefundStats(
        distance: distance,
        time: estTime,
        baseFare: baseFare,
        distanceFare: distanceFare,
        finalFare: finalFare,
        encodedPolyline: encodedPolyline,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
            ),
          )
        : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final cardWidget = Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE7E7EB)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Estimated time',
                                        style: TextStyle(fontSize: 14, color: Color(0xFF6C6F79)),
                                      ),
                                      Text(
                                        '${_stats!.time} min',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Estimated distance',
                                        style: TextStyle(fontSize: 14, color: Color(0xFF6C6F79)),
                                      ),
                                      Text(
                                        '${_stats!.distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.bookingData['fastDelivery'] == true) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8EC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                      ),
                                      child: _buildFareRow(
                                        '⚡ Fast Delivery Charge',
                                        widget.bookingData['fastDeliveryCharge'] as double? ?? 0.0,
                                        isHighlighted: true,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7EB)),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total payable',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                      Text(
                                        '₹${_stats!.finalFare.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );

                            if (widget.bookingData['fastDelivery'] == true) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  cardWidget,
                                  Positioned(
                                    top: -8,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(99),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.flash_on_rounded, color: Colors.white, size: 10),
                                          SizedBox(width: 2),
                                          Text(
                                            'Fast Delivery',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return cardWidget;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF121214)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31C2E), // Primary Red/Purple
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                              updatedBookingData['finalFare'] = _stats!.finalFare;
                              updatedBookingData['baseFare'] = _stats!.baseFare;
                              updatedBookingData['estimatedDistanceKm'] = _stats!.distance;
                              updatedBookingData['estimatedTimeMin'] = _stats!.time;
                              updatedBookingData['routePolyline'] = _stats!.encodedPolyline;

                              widget.onNext(updatedBookingData);
                            },
                            child: const Text(
                              'Proceed to Book',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
  }

  Widget _buildFareRow(String label, double amount, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? const Color(0xFFE67E22) : const Color(0xFF6C6F79),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? const Color(0xFFE67E22) : const Color(0xFF121214),
          ),
        ),
      ],
    );
  }
}
