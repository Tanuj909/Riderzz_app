import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/core/models/admin_registered_vehicle_model.dart';
import 'package:riderzz_app/features/admin/vehicles/widgets/registered_vehicle_form_bottom_sheet.dart';

class AdminRegisteredVehiclesScreen extends StatefulWidget {
  const AdminRegisteredVehiclesScreen({super.key});

  @override
  State<AdminRegisteredVehiclesScreen> createState() => _AdminRegisteredVehiclesScreenState();
}

class _AdminRegisteredVehiclesScreenState extends State<AdminRegisteredVehiclesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminVehiclesProvider>();
      if (provider.registeredVehicles.isEmpty) {
        provider.fetchRegisteredVehicles(isRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AdminVehiclesProvider>();
      if (provider.regVehiclesHasMore && !provider.isLoadingRegVehicles) {
        provider.fetchRegisteredVehicles();
      }
    }
  }

  void _showUpdateStatusBottomSheet(BuildContext context, Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return RegisteredVehicleFormBottomSheet(vehicle: vehicle);
      },
    );
  }

  Widget _buildStatusChip(String label, String value, AdminVehiclesProvider provider) {
    final isSelected = provider.regVehiclesStatusFilter == value;
    return GestureDetector(
      onTap: () => provider.setRegVehiclesStatusFilter(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFF6F6F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : const Color(0xFF6C6F79),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF1C9A5B);
      case 'PENDING':
        return const Color(0xFFF2994A);
      case 'REJECTED':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFF6C6F79);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminVehiclesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Registered Vehicles',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF121214),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE1E1E6))),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatusChip('All', 'ALL', provider),
                    _buildStatusChip('Pending', 'PENDING', provider),
                    _buildStatusChip('Approved', 'APPROVED', provider),
                    _buildStatusChip('Rejected', 'REJECTED', provider),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchRegisteredVehicles(isRefresh: true),
            color: const Color(0xFFD90429),
            child: provider.registeredVehicles.isEmpty
                ? (provider.isLoadingRegVehicles
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFD90429)))
                    : ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Text(
                              'No registered vehicles found',
                              style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 14),
                            ),
                          ),
                        ],
                      ))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.registeredVehicles.length + (provider.regVehiclesHasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == provider.registeredVehicles.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Color(0xFFD90429)),
                          ),
                        );
                      }

                      final vehicle = provider.registeredVehicles[index];
                      final AdminRegisteredVehicleModel model = AdminRegisteredVehicleModel.fromJson(Map<String, dynamic>.from(vehicle));
                      final statusColor = _getStatusColor(model.status);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE1E1E6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID: #${model.id}',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA2A5AE),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        model.vehicleTypeName ?? 'Unknown Type',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF121214),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    model.status,
                                    style: GoogleFonts.outfit(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFFD90429)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Driver Name',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF6C6F79),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          model.driverName ?? 'N/A',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF121214),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showUpdateStatusBottomSheet(context, vehicle),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: Color(0xFFE1E1E6), width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        'Edit Status',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF121214),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Delete feature coming soon')),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDEBEC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFE31C2E).withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE31C2E), size: 18),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
