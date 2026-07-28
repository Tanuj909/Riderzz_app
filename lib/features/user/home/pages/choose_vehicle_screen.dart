import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';

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
  int? _selectedVehicleIndex;
  bool _isRouteAndPricingLoading = true;
  double? _distanceKm;
  int? _durationMin;
  String? _encodedPolyline;
  final Map<int, PricingTierModel> _applicablePrices = {};
  bool _fastDeliverySelected = false;

  @override
  void initState() {
    super.initState();
    _fastDeliverySelected = widget.bookingData['fastDelivery'] == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRouteAndPricing().then((_) {
        if (mounted) {
          final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
          final vehicleTypes = vehiclesProvider.vehicleTypes;
          final preSelectedId = widget.bookingData['vehicleId'] as int?;
          if (preSelectedId != null) {
            final idx = vehicleTypes.indexWhere((v) => v.id == preSelectedId);
            if (idx >= 0) {
              setState(() {
                _selectedVehicleIndex = idx;
              });
            }
          }
        }
      });
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

  String _getVehicleEta(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('two') || nameLower.contains('bike') || nameLower.contains('scoot') || nameLower.contains('cycle')) {
      return '2 min away';
    }
    if (nameLower.contains('three') || nameLower.contains('auto') || nameLower.contains('tempo')) {
      return '5 min away';
    }
    if (nameLower.contains('four') || nameLower.contains('car') || nameLower.contains('cab') || nameLower.contains('truck') || nameLower.contains('lcv')) {
      return '10 min away';
    }
    return '15 min away';
  }

  double _parseWeightKg(dynamic weightData) {
    if (weightData == null) return 0.0;
    if (weightData is num) return weightData.toDouble();
    
    final weightStr = weightData.toString().toLowerCase().trim();
    if (weightStr.contains('0-5')) return 5.0;
    if (weightStr.contains('5-10')) return 10.0;
    if (weightStr.contains('10-50')) return 50.0;
    if (weightStr.contains('50-200')) return 200.0;
    if (weightStr.contains('200-500')) return 500.0;
    if (weightStr.contains('500+')) return 1000.0;

    final directParsed = double.tryParse(weightStr);
    if (directParsed != null) return directParsed;

    final regExp = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final match = regExp.firstMatch(weightStr);
    if (match != null) {
      return double.tryParse(match.group(0) ?? '0.0') ?? 0.0;
    }
    return 0.0;
  }

  int? _getRecommendedVehicleIndex(List<VehicleTypeModel> vehicles) {
    if (vehicles.isEmpty) return null;
    final weightStr = widget.bookingData['weightKg'];
    final weight = _parseWeightKg(weightStr);
    
    final sortedVehicles = List<VehicleTypeModel>.from(vehicles)
      ..sort((a, b) => a.maxWeightKg.compareTo(b.maxWeightKg));
    
    VehicleTypeModel? recommended;
    for (final v in sortedVehicles) {
      if (v.maxWeightKg >= weight) {
        recommended = v;
        break;
      }
    }
    recommended ??= sortedVehicles.last;
    
    final idx = vehicles.indexOf(recommended);
    return idx >= 0 ? idx : null;
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

        final recommendedIndex = _getRecommendedVehicleIndex(vehicleTypes);

        if (_selectedVehicleIndex != null && _selectedVehicleIndex! >= vehicleTypes.length) {
          _selectedVehicleIndex = null;
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
                  final isRecommended = recommendedIndex == index;
                  final etaString = _getVehicleEta(vehicle.name);
                  final tier = _applicablePrices[vehicle.id];
                  final displayBaseFare = tier?.baseFare ?? vehicle.baseFare;

                  final cardWidget = Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 4),
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
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    vehicle.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF121214),
                                    ),
                                  ),
                                  if (isRecommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C9A5B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Recommended',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
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
                                    etaString,
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
                              '₹${(isSelected && _fastDeliverySelected && tier?.fastDeliveryEnabled == true ? displayBaseFare + (tier?.fastDeliveryCharge ?? 0.0) : displayBaseFare).toStringAsFixed(0)}',
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
                  );

                  Widget childWidget = cardWidget;
                  if (tier?.fastDeliveryEnabled == true) {
                    childWidget = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        cardWidget,
                        Positioned(
                          top: -1,
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

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicleIndex = index;
                        final tier = _applicablePrices[vehicle.id];
                        if (tier?.fastDeliveryEnabled != true) {
                          _fastDeliverySelected = false;
                        }
                      });
                    },
                    child: childWidget,
                  );
                },
              ),
            ),
            // Fast Delivery Toggle Selector
            Builder(
              builder: (context) {
                if (_selectedVehicleIndex == null) return const SizedBox.shrink();
                final vehicle = vehicleTypes[_selectedVehicleIndex!];
                final tier = _applicablePrices[vehicle.id];
                if (tier?.fastDeliveryEnabled != true) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _fastDeliverySelected ? const Color(0xFFFFF2DC) : const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _fastDeliverySelected ? Colors.orange : Colors.orange.withOpacity(0.3),
                        width: _fastDeliverySelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Fast Delivery (+ ₹${tier!.fastDeliveryCharge!.toStringAsFixed(0)})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _fastDeliverySelected,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.orange,
                          inactiveThumbColor: const Color(0xFFA2A5AE),
                          inactiveTrackColor: const Color(0xFFF1F1F4),
                          onChanged: (val) {
                            setState(() {
                              _fastDeliverySelected = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                          disabledBackgroundColor: const Color(0xFFF1F1F4),
                          disabledForegroundColor: const Color(0xFFA2A5AE),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _selectedVehicleIndex == null
                            ? null
                            : () {
                                final selectedVehicle = vehicleTypes[_selectedVehicleIndex!];
                                final tier = _applicablePrices[selectedVehicle.id];
                                final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                                updatedBookingData['vehicleId'] = selectedVehicle.id;
                                updatedBookingData['vehicleType'] = selectedVehicle;
                                updatedBookingData['estimatedDistanceKm'] = _distanceKm;
                                updatedBookingData['estimatedDurationMin'] = _durationMin;
                                updatedBookingData['routePolyline'] = _encodedPolyline;
                                updatedBookingData['applicablePricingTier'] = tier;
                                updatedBookingData['fastDelivery'] = _fastDeliverySelected && tier?.fastDeliveryEnabled == true;
                                updatedBookingData['fastDeliveryCharge'] = tier?.fastDeliveryEnabled == true ? tier?.fastDeliveryCharge : null;

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
