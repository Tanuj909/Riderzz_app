import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/pages/fare_estimate_screen.dart';

class ChooseVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const ChooseVehicleScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<ChooseVehicleScreen> createState() => _ChooseVehicleScreenState();
}

class _ChooseVehicleScreenState extends State<ChooseVehicleScreen> {
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
          'Choose Vehicle',
          style: TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Consumer<AdminVehiclesProvider>(
        builder: (context, vehiclesProvider, child) {
          final vehicleTypes = vehiclesProvider.vehicleTypes;

          if (vehiclesProvider.isLoading && vehicleTypes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
              ),
            );
          }

          if (vehicleTypes.isEmpty) {
            return const Center(
              child: Text(
                'No available vehicle types',
                style: TextStyle(color: Color(0xFF6B7785), fontSize: 14),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F0FB) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
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
                                        color: Color(0xFF1A3D6B),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.local_shipping_rounded,
                                      size: 28,
                                      color: Color(0xFF1A3D6B),
                                    ),
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
                                      color: Color(0xFF1A2233),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'Max ${vehicle.maxWeightKg} KG',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF6B7785), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$estTime min',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2233),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+₹${vehicle.perKmRate.toStringAsFixed(0)}/km',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 14),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A3D6B),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3D6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                      updatedBookingData['vehicleType'] = selectedType;
                      updatedBookingData['estTime'] = _getEstTime(_selectedVehicleIndex);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FareEstimateScreen(
                            bookingData: updatedBookingData,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Continue with ${selectedType.name}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
