import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/admin/vehicles/data/models/admin_vehicle_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_list_provider.dart';

class AdminVehiclesListScreen extends StatefulWidget {
  const AdminVehiclesListScreen({super.key});

  @override
  State<AdminVehiclesListScreen> createState() => _AdminVehiclesListScreenState();
}

class _AdminVehiclesListScreenState extends State<AdminVehiclesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVehiclesListProvider>().fetchVehicles(isRefresh: true);
    });
  }

  void _showVehicleDetails(BuildContext context, int vehicleId) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return FutureBuilder<AdminVehicleModel?>(
          future: context.read<AdminVehiclesListProvider>().fetchVehicleById(vehicleId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3D6B)));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Could not fetch vehicle details.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            }
            final vehicle = snapshot.data!;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Vehicle Details',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Type', vehicle.vehicleTypeName),
                  const SizedBox(height: 10),
                  _buildDetailRow('Status', vehicle.status),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    'Driver',
                    vehicle.driverName != null && vehicle.driverName!.isNotEmpty
                        ? vehicle.driverName!
                        : 'No Driver Assigned',
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3D6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7785)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF1A2233)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF0F9B6E);
      case 'PENDING':
        return Colors.amber;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return const Color(0xFF6B7785);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFFEBFDF6);
      case 'PENDING':
        return const Color(0xFFFFFBEB);
      case 'REJECTED':
        return const Color(0xFFFFF0F0);
      default:
        return const Color(0xFFF4F5F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminVehiclesListProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchVehicles(isRefresh: true),
        color: const Color(0xFF1A3D6B),
        child: Column(
          children: [
            // Custom Title Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: Color(0xFF1A3D6B)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered Vehicles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2233),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.vehicles.isEmpty
                            ? 'No vehicles listed'
                            : '${provider.vehicles.length} vehicles registered in system',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7785),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3D6B)))
                  : provider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A3D6B),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => provider.fetchVehicles(isRefresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : provider.vehicles.isEmpty
                          ? const Center(
                              child: Text(
                                'No registered vehicles found.',
                                style: TextStyle(color: Color(0xFF6B7785)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.vehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = provider.vehicles[index];
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE9ECF0)),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () => _showVehicleDetails(context, vehicle.id),
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFE8F0FB),
                                      child: Icon(Icons.local_shipping_rounded, color: Color(0xFF1A3D6B)),
                                    ),
                                    title: Text(
                                      vehicle.vehicleTypeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2233),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        vehicle.driverName != null && vehicle.driverName!.isNotEmpty
                                            ? 'Driver: ${vehicle.driverName}'
                                            : 'Driver: Not assigned',
                                        style: const TextStyle(color: Color(0xFF6B7785), fontSize: 13),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(vehicle.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        vehicle.status,
                                        style: TextStyle(
                                          color: _getStatusColor(vehicle.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
