import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';

class ChooseVehicleView extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const ChooseVehicleView({
    super.key,
    required this.bookingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ChooseVehicleView> createState() => _ChooseVehicleViewState();
}

class _ChooseVehicleViewState extends State<ChooseVehicleView> {
  int _selectedVehicleIndex = 0;
  bool _isRouteAndPricingLoading = true;
  double? _distanceKm;
  int? _durationMin;
  String? _encodedPolyline;
  final Map<int, PricingTierModel> _applicablePrices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRouteAndPricing();
    });
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

  Future<void> _fetchRouteAndPricing() async {
    try {
      final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
      if (vehiclesProvider.vehicleTypes.isEmpty) {
        await vehiclesProvider.fetchVehicleTypes();
      }
    } catch (e) {
      debugPrint('Error fetching vehicle types: $e');
    }

    final pickupLat = widget.bookingData['pickupLatitude'] as double?;
    final pickupLng = widget.bookingData['pickupLongitude'] as double?;
    final dropLat = widget.bookingData['dropLatitude'] as double?;
    final dropLng = widget.bookingData['dropLongitude'] as double?;

    double distance = 8.4;
    int estTime = 28;
    String? encodedPolyline;

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
              "travelMode": "DRIVE",
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
                distance = (distanceMeters / 1000.0 * 100.0).round() / 100.0;
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
        debugPrint('Error fetching google route: $e');
        distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
        estTime = (distance * 3.0 + 3).round();
      }
    }

    _distanceKm = distance;
    _durationMin = estTime;
    _encodedPolyline = encodedPolyline;

    if (mounted) {
      final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      final futures = vehiclesProvider.vehicleTypes.map((vehicle) async {
        try {
          final tier = await bookingProvider.getApplicablePricingTier(vehicle.id, distance);
          if (tier != null) {
            _applicablePrices[vehicle.id] = tier;
          }
        } catch (e) {
          debugPrint('Error fetching applicable pricing tier for vehicle ${vehicle.id}: $e');
        }
      }).toList();

      await Future.wait(futures);
    }

    if (mounted) {
      setState(() {
        _isRouteAndPricingLoading = false;
      });
    }
  }

  int _getEstTime(int index) {
    switch (index) {
      case 0:
        return 5;
      case 1:
        return 8;
      case 2:
        return 12;
      case 3:
        return 20;
      default:
        return 5 + index * 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminVehiclesProvider>(
      builder: (context, vehiclesProvider, child) {
        final vehicleTypes = vehiclesProvider.vehicleTypes;

        if (_isRouteAndPricingLoading || (vehiclesProvider.isLoading && vehicleTypes.isEmpty)) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
            ),
          );
        }

        if (vehicleTypes.isEmpty) {
          return const Center(
            child: Text(
              'No available vehicle types',
              style: TextStyle(color: Color(0xFF6C6F79), fontSize: 14),
            ),
          );
        }

        if (_selectedVehicleIndex >= vehicleTypes.length) {
          _selectedVehicleIndex = 0;
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicleTypes[index];
                  final isSelected = _selectedVehicleIndex == index;
                  final estTime = _getEstTime(index);
                  final tier = _applicablePrices[vehicle.id];
                  final displayBaseFare = tier?.baseFare ?? vehicle.baseFare;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicleIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFDEBEC) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            alignment: Alignment.center,
                            child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                                ? Image.network(
                                    vehicle.iconUrl!,
                                    width: 34,
                                    height: 34,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.local_shipping_rounded,
                                      size: 28,
                                      color: Color(0xFFE31C2E),
                                    ),
                                  )
                                : const Icon(Icons.local_shipping_rounded, size: 28, color: Color(0xFFE31C2E)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Up to ${vehicle.maxWeightKg} kg',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79)),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('·', style: TextStyle(fontSize: 12, color: Color(0xFF6C6F79))),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$estTime min away',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${displayBaseFare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'est.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF6C6F79)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          backgroundColor: const Color(0xFFE31C2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final selectedVehicle = vehicleTypes[_selectedVehicleIndex];
                          final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                          updatedBookingData['vehicleId'] = selectedVehicle.id;
                          updatedBookingData['vehicleType'] = selectedVehicle;
                          updatedBookingData['estimatedDistanceKm'] = _distanceKm;
                          updatedBookingData['estimatedDurationMin'] = _durationMin;
                          updatedBookingData['routePolyline'] = _encodedPolyline;
                          updatedBookingData['applicablePricingTier'] = _applicablePrices[selectedVehicle.id];

                          widget.onNext(updatedBookingData);
                        },
                        child: const Text(
                          'Continue',
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
      },
    );
  }
}
