import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE31C2E)));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('Could not fetch vehicle details.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Close'),
                  ),
                ],
              );
            }
            final vehicle = snapshot.data!;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Vehicle Details',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
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
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Close'),
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF6C6F79)),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(color: Color(0xFF121214)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF1C9A5B);
      case 'PENDING':
        return Colors.amber;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return const Color(0xFF6C6F79);
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
      backgroundColor: const Color(0xFFF6F6F8),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchVehicles(isRefresh: true),
        color: const Color(0xFFE31C2E),
        child: Column(
          children: [
            // Custom Title Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: Color(0xFFE31C2E)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered Vehicles',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121214),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.vehicles.isEmpty
                            ? 'No vehicles listed'
                            : '${provider.vehicles.length} vehicles registered in system',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Color(0xFF6C6F79),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31C2E)))
                  : provider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.errorMessage!,
                                style: GoogleFonts.outfit(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31C2E),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => provider.fetchVehicles(isRefresh: true),
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : provider.vehicles.isEmpty
                          ? Center(
                              child: Text(
                                'No registered vehicles found.',
                                style: GoogleFonts.outfit(color: Color(0xFF6C6F79)),
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
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Color(0xFFE7E7EB)),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () => _showVehicleDetails(context, vehicle.id),
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFFDEBEC),
                                      child: Icon(Icons.local_shipping_rounded, color: Color(0xFFE31C2E)),
                                    ),
                                    title: Text(
                                      vehicle.vehicleTypeName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF121214),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        vehicle.driverName != null && vehicle.driverName!.isNotEmpty
                                            ? 'Driver: ${vehicle.driverName}'
                                            : 'Driver: Not assigned',
                                        style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 13),
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
                                        style: GoogleFonts.outfit(
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