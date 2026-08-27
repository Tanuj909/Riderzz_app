import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';

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
  final double timeBasedExtraCharge;
  final String? encodedPolyline;
  final PricingTierModel? tier;
  final Map<String, dynamic>? timeBasedPricing;
  final bool tollExists;

  _RefundStats({
    required this.distance,
    required this.time,
    required this.baseFare,
    required this.distanceFare,
    required this.timeBasedExtraCharge,
    this.encodedPolyline,
    this.tier,
    this.timeBasedPricing,
    this.tollExists = false,
  });
}

class _FareEstimateViewState extends State<FareEstimateView> {
  _RefundStats? _stats;
  bool _isLoading = true;
  bool _fastDeliverySelected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fastDeliverySelected = widget.bookingData['fastDelivery'] == true;
    _fetchRouteAndCalculateFare();
  }

  String _getTravelMode(VehicleTypeModel vehicle) {
    final cat = vehicle.category?.toUpperCase() ?? '';
    if (cat == 'TWO_WHEELER') {
      return 'TWO_WHEELER';
    } else if (cat == 'TRUCK') {
      return 'TRUCK';
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

    final currentTravelMode = _getTravelMode(vehicle);
    final fetchedTravelMode = widget.bookingData['fetchedTravelMode'] as String?;
    final fetchedPickupLat = widget.bookingData['fetchedPickupLat'] as double?;
    final fetchedDropLat = widget.bookingData['fetchedDropLat'] as double?;

    debugPrint('FareEstimate: Pickup ($pickupLat, $pickupLng) → Drop ($dropLat, $dropLng)');

    double distance = widget.bookingData['estimatedDistanceKm'] as double? ?? 8.4;
    int estTime = widget.bookingData['estimatedDurationMin'] as int? ?? widget.bookingData['estimatedTimeMin'] as int? ?? 28;
    String? encodedPolyline = widget.bookingData['routePolyline'] as String?;

    bool fetchedTollExists = false;
    bool shouldFetchRoute = true;
    if (encodedPolyline != null && 
        fetchedTravelMode == currentTravelMode && 
        fetchedPickupLat == pickupLat && 
        fetchedDropLat == dropLat) {
      shouldFetchRoute = false;
      fetchedTollExists = widget.bookingData['tollExists'] ?? false;
      debugPrint('FareEstimate: Using cached Google Route API response for $currentTravelMode');
    }

    if (shouldFetchRoute && pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
      try {
        final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
        if (googleApiKey.isNotEmpty) {
          final isTollEnabled = vehicle.tollEnabled == true;
          final requestData = {
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
            "travelMode": _getTravelMode(vehicle),
            "routingPreference": "TRAFFIC_AWARE"
          };
          
          if (isTollEnabled) {
            requestData['extraComputations'] = ['TOLLS'];
          }

          final dio = Dio();
          final response = await dio.post(
            'https://routes.googleapis.com/directions/v2:computeRoutes',
            data: requestData,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': googleApiKey,
                'X-Goog-FieldMask': isTollEnabled 
                    ? 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.travelAdvisory.tollInfo'
                    : 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
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
              
              if (vehicle.tollEnabled == true) {
                final travelAdvisory = route['travelAdvisory'];
                if (travelAdvisory != null && travelAdvisory is Map) {
                  final tollInfo = travelAdvisory['tollInfo'];
                  if (tollInfo != null && tollInfo is Map) {
                    fetchedTollExists = true;
                  }
                }
              }
            } else {
              if (vehicle.tollEnabled == true) {
                setState(() {
                  _errorMessage = 'Unable to calculate tolls for this route. Please try again.';
                  _isLoading = false;
                });
                return;
              }
              distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
              estTime = (distance * 3.0 + 3).round();
            }
          } else {
            if (vehicle.tollEnabled == true) {
              setState(() {
                _errorMessage = 'Unable to calculate tolls for this route. Please try again.';
                _isLoading = false;
              });
              return;
            }
            distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
            estTime = (distance * 3.0 + 3).round();
          }
        } else {
          if (vehicle.tollEnabled == true) {
            setState(() {
              _errorMessage = 'Unable to calculate tolls for this route. Please try again.';
              _isLoading = false;
            });
            return;
          }
          distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
          estTime = (distance * 3.0 + 3).round();
        }
      } catch (e) {
        debugPrint('Error fetching exact route: $e');
        if (vehicle.tollEnabled == true) {
          setState(() {
            _errorMessage = 'Unable to calculate tolls for this route. Please try again.';
            _isLoading = false;
          });
          return;
        }
        distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
        estTime = (distance * 3.0 + 3).round();
      }
    }

    if (!mounted) return;

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    PricingTierModel? tier;
    try {
      tier = await bookingProvider.getApplicablePricingTier(vehicle.id, distance);
    } catch (e) {
      debugPrint('Error fetching tier in fare estimate: $e');
    }

    Map<String, dynamic>? timeBasedPricing;
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    try {
      final tbp = await bookingProvider.getTimeBasedPricing(vehicle.id, timeString);
      if (tbp != null && tbp['enabled'] == true) {
        timeBasedPricing = tbp;
      }
    } catch (e) {
      debugPrint('Error fetching time based pricing: $e');
    }

    final double baseFare = tier?.baseFare ?? vehicle.baseFare;
    final double perKmRate = tier?.perKmRate ?? vehicle.perKmRate;
    final double distanceFare = (distance * perKmRate).roundToDouble();
    final double timeBasedExtraCharge = (timeBasedPricing?['extraCharge'] as num?)?.toDouble() ?? 0.0;

    setState(() {
      _stats = _RefundStats(
        distance: distance,
        time: estTime,
        baseFare: baseFare,
        distanceFare: distanceFare,
        timeBasedExtraCharge: timeBasedExtraCharge,
        encodedPolyline: encodedPolyline,
        tier: tier,
        timeBasedPricing: timeBasedPricing,
        tollExists: fetchedTollExists,
      );
      
      if (tier?.fastDeliveryEnabled != true) {
        _fastDeliverySelected = false;
      }
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final tier = _stats?.tier;
    
    // Toll logic
    final bool isTollEnabled = vehicle.tollEnabled == true;
    final bool tollExists = _stats?.tollExists ?? false;
    final double tollAmount = tollExists ? (vehicle.defaultTollAmount ?? 0.0) : 0.0;
    
    // Fast delivery logic
    final bool canFastDelivery = tier?.fastDeliveryEnabled == true;
    final double fastDeliveryCharge = tier?.fastDeliveryCharge ?? 0.0;
    
    final double commissionAmount = tier?.commission ?? 0.0;

    double finalFare = 0.0;
    if (_stats != null) {
      finalFare = _stats!.baseFare + _stats!.distanceFare + _stats!.timeBasedExtraCharge + commissionAmount;
      if (tollAmount > 0) finalFare += tollAmount;
      if (_fastDeliverySelected && canFastDelivery) finalFare += fastDeliveryCharge;
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31C2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      );
    }

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
                                  if (_stats!.timeBasedExtraCharge > 0 || (_fastDeliverySelected && canFastDelivery) || (isTollEnabled && tollAmount > 0)) ...[
                                    const SizedBox(height: 16),
                                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F4)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Surcharges & Add-ons',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA2A5AE)),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_stats!.timeBasedExtraCharge > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFFE31C2E)),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Price Surge',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF121214),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '₹${_stats!.timeBasedExtraCharge.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121214),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    if (isTollEnabled && tollAmount > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.toll_rounded, size: 16, color: Colors.blue),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Toll Charge',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF121214),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '₹${tollAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121214),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_fastDeliverySelected && canFastDelivery)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.flash_on_rounded, size: 16, color: Colors.orange),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Fast Delivery',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF121214),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '₹${fastDeliveryCharge.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121214),
                                              ),
                                            ),
                                          ],
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
                                        '₹${finalFare.toStringAsFixed(2)}',
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

                            if (_fastDeliverySelected && canFastDelivery) {
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
                if (canFastDelivery)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Column(
                      children: [
                        Text(
                          _fastDeliverySelected 
                              ? 'Fast Delivery amount added to the final fare!' 
                              : 'Choose Fast Delivery!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE31C2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          decoration: BoxDecoration(
                            color: _fastDeliverySelected ? const Color(0xFFFFF2DC) : const Color(0xFFFFF8EC),
                            borderRadius: BorderRadius.circular(100),
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
                                    'Fast Delivery (+ ₹${fastDeliveryCharge.toStringAsFixed(0)})',
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
                      ],
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
                              updatedBookingData['finalFare'] = finalFare;
                              updatedBookingData['baseFare'] = _stats!.baseFare;
                              updatedBookingData['estimatedDistanceKm'] = _stats!.distance;
                              updatedBookingData['estimatedTimeMin'] = _stats!.time;
                              updatedBookingData['routePolyline'] = _stats!.encodedPolyline;
                              
                              updatedBookingData['fetchedTravelMode'] = _getTravelMode(vehicle);
                              updatedBookingData['fetchedPickupLat'] = widget.bookingData['pickupLatitude'];
                              updatedBookingData['fetchedDropLat'] = widget.bookingData['dropLatitude'];
                              
                              // Pass the updated fast delivery choice
                              updatedBookingData['fastDelivery'] = _fastDeliverySelected && canFastDelivery;
                              updatedBookingData['fastDeliveryCharge'] = (_fastDeliverySelected && canFastDelivery) ? fastDeliveryCharge : null;
                              
                              // Pass the updated pricing items
                              updatedBookingData['applicablePricingTier'] = _stats?.tier;
                              updatedBookingData['timeBasedPricing'] = _stats?.timeBasedPricing;
                              updatedBookingData['timeBasedExtraCharge'] = _stats?.timeBasedExtraCharge;

                              // Toll logic
                              updatedBookingData['tollExists'] = _stats?.tollExists ?? false;
                              if (tollAmount > 0) {
                                updatedBookingData['tollCharge'] = tollAmount;
                              } else {
                                updatedBookingData.remove('tollCharge');
                              }

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
