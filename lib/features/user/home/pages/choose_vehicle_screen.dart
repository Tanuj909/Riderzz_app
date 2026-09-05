import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
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
  int? _selectedVehicleId;
  bool _isLoading = true;
  // bool _fastDeliverySelected = false;

  @override
  void initState() {
    super.initState();
    // _fastDeliverySelected = widget.bookingData['fastDelivery'] == true;
    _selectedVehicleId = widget.bookingData['vehicleId'] as int?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVehicles().then((_) {
        if (mounted) {
          final preSelectedId = widget.bookingData['vehicleId'] as int?;
          if (preSelectedId != null) {
            setState(() {
              _selectedVehicleId = preSelectedId;
            });
          }
        }
      });
    });
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
      if (vehiclesProvider.vehicleTypes.isEmpty) {
        await vehiclesProvider.fetchVehicleTypes();
      }
    } catch (e) {
      debugPrint('Error fetching vehicle types: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  String _normalizeCategory(String? category) {
    if (category == null || category.isEmpty) return 'OTHER';
    return category.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
  }

  String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'TWO_WHEELER':
        return '2 Wheeler';
      case 'THREE_WHEELER':
        return '3 Wheeler';
      case 'FOUR_WHEELER':
        return '4 Wheeler';
      case 'TRUCK':
        return 'Truck';
      default:
        return categoryKey
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
            .join(' ');
    }
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 2, right: 2),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFFE31C2E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121214),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleTypeModel vehicle, {bool isRecommended = false}) {
    final isSelected = _selectedVehicleId == vehicle.id;
    final etaString = _getVehicleEta(vehicle.name);

    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFDEBEC) : Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
          width: isSelected ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(width: 13),
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
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF121214),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Up to ${vehicle.maxWeightKg} kg',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79)),
                    ),
                    const SizedBox(width: 4),
                    const Text('·', style: TextStyle(fontSize: 12, color: Color(0xFF6C6F79))),
                    const SizedBox(width: 4),
                    Text(
                      etaString,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFF7F8FA),
              border: Border.all(
                color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFDCDCE0),
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                  Icon(Icons.flash_on_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Fast Delivery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
        });
      },
      child: childWidget,
    );
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

        final preSelectedId = widget.bookingData['vehicleId'] as int?;

        // Group Vehicles by Category
        final categoryOrder = ['TWO_WHEELER', 'THREE_WHEELER', 'FOUR_WHEELER', 'TRUCK'];

        VehicleTypeModel? preSelectedVehicle;
        if (preSelectedId != null) {
          for (final v in vehicleTypes) {
            if (v.id == preSelectedId) {
              preSelectedVehicle = v;
              break;
            }
          }
        }

        final preSelectedCategoryKey = preSelectedVehicle != null ? _normalizeCategory(preSelectedVehicle.category) : null;

        final Map<String, List<VehicleTypeModel>> vehiclesByCategory = {};
        for (final v in vehicleTypes) {
          final catKey = _normalizeCategory(v.category);
          vehiclesByCategory.putIfAbsent(catKey, () => []).add(v);
        }

        // Sort vehicles inside each category:
        // Preselected vehicle first, then fast delivery, then max weight
        for (final list in vehiclesByCategory.values) {
          list.sort((a, b) {
            if (preSelectedId != null) {
              if (a.id == preSelectedId) return -1;
              if (b.id == preSelectedId) return 1;
            }
            final hasFastA = a.isFastDelivery == true ? 1 : 0;
            final hasFastB = b.isFastDelivery == true ? 1 : 0;
            if (hasFastA != hasFastB) return hasFastB.compareTo(hasFastA);
            return a.maxWeightKg.compareTo(b.maxWeightKg);
          });
        }

        // Ordered Category keys (pre-selected vehicle's category at top)
        final orderedCategoryKeys = <String>[];
        if (preSelectedCategoryKey != null && vehiclesByCategory.containsKey(preSelectedCategoryKey)) {
          orderedCategoryKeys.add(preSelectedCategoryKey);
        }
        for (final cat in categoryOrder) {
          if (!orderedCategoryKeys.contains(cat) && vehiclesByCategory.containsKey(cat)) {
            orderedCategoryKeys.add(cat);
          }
        }
        for (final cat in vehiclesByCategory.keys) {
          if (!orderedCategoryKeys.contains(cat)) {
            orderedCategoryKeys.add(cat);
          }
        }

        final recommendedIndex = _getRecommendedVehicleIndex(vehicleTypes);
        final recommendedVehicle = (recommendedIndex != null && recommendedIndex >= 0 && recommendedIndex < vehicleTypes.length)
            ? vehicleTypes[recommendedIndex]
            : null;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (final catKey in orderedCategoryKeys) ...[
                    _buildCategoryHeader(_getCategoryDisplayName(catKey)),
                    for (final vehicle in vehiclesByCategory[catKey]!)
                      _buildVehicleCard(
                        vehicle,
                        isRecommended: recommendedVehicle?.id == vehicle.id,
                      ),
                  ],
                ],
              ),
            ),
            // Fast Delivery Toggle Selector (Commented out - moved to fare estimate screen)
            Builder(
              builder: (context) {
                return const SizedBox.shrink();
                /*
                if (_selectedVehicleId == null) return const SizedBox.shrink();
                final vehicle = vehicleTypes.firstWhere(
                  (v) => v.id == _selectedVehicleId,
                  orElse: () => vehicleTypes.first,
                );
                if (vehicle.isFastDelivery != true) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    children: [
                      Text(
                        _fastDeliverySelected 
                            ? 'Fast Delivery Charges will be added!' 
                            : 'Choose Fast Delivery!',
                        style: const TextStyle(
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
                            color: _fastDeliverySelected ? Colors.orange : Colors.orange.withValues(alpha: 0.3),
                            width: _fastDeliverySelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Fast Delivery',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _fastDeliverySelected,
                              activeThumbColor: Colors.white,
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
                */
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
                                final selectedVehicle = vehicleTypes.firstWhere((v) => v.id == _selectedVehicleId);
                                final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                                updatedBookingData['vehicleId'] = selectedVehicle.id;
                                updatedBookingData['vehicleType'] = selectedVehicle;
                                updatedBookingData['fastDelivery'] = false;

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
