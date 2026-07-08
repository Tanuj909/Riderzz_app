import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/pages/finding_driver_screen.dart';
import 'package:riderzz_app/features/user/home/widgets/booking_details_bottom_sheet.dart';


class UserBookingsPage extends StatefulWidget {
  const UserBookingsPage({super.key});

  @override
  State<UserBookingsPage> createState() => _UserBookingsPageState();
}

class _UserBookingsPageState extends State<UserBookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
          child: Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Consumer<BookingProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.bookings.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                );
              }

              if (provider.errorMessage != null && provider.bookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.black, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                          onPressed: () => provider.fetchBookings(),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.bookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inventory_2_outlined, color: Color(0xFFB0B8C4), size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No Bookings Yet',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214), fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your ride history will appear here once you make a booking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6C6F79), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchBookings(),
                color: Colors.black,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: provider.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = provider.bookings[index];
                    final isCompleted = booking.status == 'COMPLETED';
                    final isCancelled = booking.status == 'CANCELLED';

                    Color statusColor = Colors.black; // PENDING/DEFAULT
                    Color statusBg = const Color(0xFFF0F0F0);
                    if (isCompleted) {
                      statusColor = const Color(0xFF1C9A5B);
                      statusBg = const Color(0xFFE7F7EF);
                    } else if (isCancelled) {
                      statusColor = Colors.redAccent;
                      statusBg = const Color(0xFFFDEBEC);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 5,
                                color: statusColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ID: ${booking.bookingId}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              booking.status,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        booking.createdAt.isNotEmpty
                                            ? booking.createdAt.split('T')[0]
                                            : 'Recent Booking',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF9EABB8)),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF1C9A5B), shape: BoxShape.circle)),
                                              Container(width: 1.5, height: 20, color: const Color(0xFFE7E7EB)),
                                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFB9700A), shape: BoxShape.circle)),
                                            ],
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  booking.pickupAddressName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  booking.dropAddressName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(height: 1, color: Color(0xFFE7E7EB)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '₹${booking.totalFare.toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF121214),
                                                ),
                                              ),
                                              Text(
                                                'Type: ${booking.parcelType}',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF6C6F79)),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => showBookingDetailsBottomSheet(context, booking),
                                                icon: const Icon(Icons.info_outline_rounded, size: 14, color: Colors.black),
                                                label: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  backgroundColor: const Color(0xFFF0F0F0),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              if (booking.status.toUpperCase() != 'CANCELLED' &&
                                                  booking.status.toUpperCase() != 'DELIVERED' &&
                                                  booking.status.toUpperCase() != 'COMPLETED') ...[
                                                const SizedBox(width: 8),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    String vehicleName = 'Vehicle';
                                                    try {
                                                      final vehiclesProvider = context.read<AdminVehiclesProvider>();
                                                      final matchingVehicle = vehiclesProvider.vehicleTypes.firstWhere(
                                                        (v) => v.id == booking.vehicleTypeId,
                                                      );
                                                      vehicleName = matchingVehicle.name;
                                                    } catch (_) {}

                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => FindingDriverScreen(
                                                          booking: booking,
                                                          vehicleName: vehicleName,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.my_location_rounded, size: 12, color: Colors.white),
                                                  label: const Text('Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    backgroundColor: Colors.black,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
