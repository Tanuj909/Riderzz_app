import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/user/home/pages/confirm_booking_screen.dart';

class FareEstimateScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const FareEstimateScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _RefundStats {
  final double distance;
  final int time;
  final double baseFare;
  final double distanceFare;
  final double finalFare;

  _RefundStats({
    required this.distance,
    required this.time,
    required this.baseFare,
    required this.distanceFare,
    required this.finalFare,
  });
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
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

    double distance = 8.4;
    int estTime = 28;

    if (pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
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

    final double baseFare = vehicle.baseFare;
    final double perKmRate = vehicle.perKmRate;
    final double distanceFare = (distance * perKmRate).roundToDouble();
    final double finalFare = baseFare + distanceFare;

    setState(() {
      _stats = _RefundStats(
        distance: distance,
        time: estTime,
        baseFare: baseFare,
        distanceFare: distanceFare,
        finalFare: finalFare,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2233), size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        title: const Text(
          'Fare Estimate',
          style: TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                        // Selected Vehicle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE9ECF0)),
                                ),
                                alignment: Alignment.center,
                                child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                                    ? Image.network(
                                        vehicle.iconUrl!,
                                        width: 36,
                                        height: 36,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 28,
                                          color: Color(0xFF1A3D6B),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.local_shipping_rounded,
                                        size: 28,
                                        color: Color(0xFF1A3D6B),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2233),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vehicle.description.isEmpty
                                          ? 'Reliable transport for your goods'
                                          : vehicle.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7785),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Distance & Est Time Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildStatItem(
                                icon: Icons.directions_rounded,
                                iconColor: const Color(0xFF0F9B6E),
                                value: '${_stats!.distance.toStringAsFixed(2)} km',
                                label: 'Distance',
                              ),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              _buildStatItem(
                                icon: Icons.access_time_filled_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                value: '~${_stats!.time} min',
                                label: 'Est. Time',
                              ),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              _buildStatItem(
                                icon: Icons.scale_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                                value: '${vehicle.maxWeightKg} KG',
                                label: 'Max Load',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price Breakdown Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildBreakdownRow('Base Fare', _stats!.baseFare),
                              _buildDivider(),
                              _buildBreakdownRow(
                                'Distance (${_stats!.distance.toStringAsFixed(2)}km × ₹${vehicle.perKmRate.toStringAsFixed(0)})',
                                _stats!.distanceFare,
                              ),
                              
                              // Total Row with sleek background
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Estimated Fare',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2233),
                                      ),
                                    ),
                                    Text(
                                      '₹${_stats!.finalFare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A3D6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D6B), // Primary Blue
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

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmBookingScreen(
                              bookingData: updatedBookingData,
                            ),
                          ),
                        );
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
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2233),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2233),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0));
  }
}
