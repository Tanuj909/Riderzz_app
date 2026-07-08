import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminVehiclesProvider>(context, listen: false).fetchVehicleTypes();
    });
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

          if (vehiclesProvider.isLoading && vehicleTypes.isEmpty) {
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

          final VehicleTypeModel selectedType = vehicleTypes[_selectedVehicleIndex];

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
                                  '₹${vehicle.baseFare.toStringAsFixed(0)}',
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
