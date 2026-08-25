import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
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
  int? _selectedVehicleId;
  bool _isLoading = true;
  bool _fastDeliverySelected = false;
  final Map<int, PricingTierModel> _applicablePrices = {};

  @override
  void initState() {
    super.initState();
    _fastDeliverySelected = widget.bookingData['fastDelivery'] == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVehicles().then((_) {
        if (mounted) {
          final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
          final vehicleTypes = vehiclesProvider.vehicleTypes;
          final preSelectedId = widget.bookingData['vehicleId'] as int?;
          if (preSelectedId != null) {
            final idx = vehicleTypes.indexWhere((v) => v.id == preSelectedId);
            if (idx >= 0) {
              setState(() {
                _selectedVehicleId = preSelectedId;
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

  Future<void> _fetchVehicles() async {
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
    if (pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
      distance = _calculateHaversineDistance(pickupLat, pickupLng, dropLat, dropLng);
    }

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

      setState(() {
        _isLoading = false;
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
        final vehicleTypes = vehiclesProvider.vehicleTypes.where((v) => v.isActive).toList();

        if (_isLoading || (vehiclesProvider.isLoading && vehicleTypes.isEmpty)) {
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

        // Sort vehicleTypes: fast delivery enabled first, then others
        final sortedVehicleTypes = List<VehicleTypeModel>.from(vehicleTypes);
        sortedVehicleTypes.sort((a, b) {
          final hasFastA = a.isFastDelivery == true ? 1 : 0;
          final hasFastB = b.isFastDelivery == true ? 1 : 0;
          return hasFastB.compareTo(hasFastA);
        });

        final recommendedIndex = _getRecommendedVehicleIndex(sortedVehicleTypes);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pricing shown is Estimated!',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C6F79),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Estimated Fare',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
                          ),
                          content: Text(
                            'The fare shown on screen is not final, it is estimated. Final fare will be shown on the next screen!',
                            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C6F79), height: 1.4),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFFE31C2E), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.info_outline, color: Color(0xFFE31C2E), size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedVehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = sortedVehicleTypes[index];
                  final isSelected = _selectedVehicleId == vehicle.id;
                  final isRecommended = recommendedIndex == index;
                  final etaString = _getVehicleEta(vehicle.name);

                  double displayBaseFare = _applicablePrices[vehicle.id]?.baseFare ?? vehicle.baseFare;
                  if (isSelected && _fastDeliverySelected && vehicle.isFastDelivery == true) {
                    displayBaseFare += _applicablePrices[vehicle.id]?.fastDeliveryCharge ?? 0.0;
                  }

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
                              '₹${displayBaseFare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121214),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6C6F79)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  Widget childWidget = cardWidget;

                  if (vehicle.isFastDelivery == true) {
                    childWidget = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ShiningContainer(
                          isSelected: isSelected,
                          child: cardWidget,
                        ),
                        Positioned(
                          top: -6,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.flash_on_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 3),
                                Text(
                                  'Fast Delivery',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
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
                        _selectedVehicleId = vehicle.id;
                        if (vehicle.isFastDelivery != true) {
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
                if (_selectedVehicleId == null) return const SizedBox.shrink();
                final vehicle = sortedVehicleTypes.firstWhere((v) => v.id == _selectedVehicleId, orElse: () => sortedVehicleTypes.first);
                if (vehicle.isFastDelivery != true) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    children: [
                      const Text(
                        'This amount will be added to the final fare.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE31C2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                                  'Fast Delivery (+ ₹${_applicablePrices[vehicle.id]?.fastDeliveryCharge?.toStringAsFixed(0) ?? "0"})',
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
                        onPressed: _selectedVehicleId == null
                            ? null
                            : () {
                                final selectedVehicle = sortedVehicleTypes.firstWhere((v) => v.id == _selectedVehicleId);
                                final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                                updatedBookingData['vehicleId'] = selectedVehicle.id;
                                updatedBookingData['vehicleType'] = selectedVehicle;
                                updatedBookingData['fastDelivery'] = _fastDeliverySelected && selectedVehicle.isFastDelivery == true;

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

class ShiningContainer extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const ShiningContainer({
    super.key,
    required this.child,
    required this.isSelected,
  });

  @override
  State<ShiningContainer> createState() => _ShiningContainerState();
}

class _ShiningContainerState extends State<ShiningContainer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.transparent,
                Colors.white10,
                Colors.white54,
                Colors.white10,
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.45, 0.5, 0.55, 0.65, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}
