import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/pages/finding_driver_screen.dart';


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
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.bookings.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3D6B)),
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233), fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your ride history will appear here once you make a booking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7785), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchBookings(),
          color: const Color(0xFF1A3D6B),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: provider.bookings.length,
            itemBuilder: (context, index) {
              final booking = provider.bookings[index];
              final isCompleted = booking.status == 'COMPLETED';
              final isCancelled = booking.status == 'CANCELLED';

              Color statusColor = const Color(0xFF1A3D6B); // PENDING/DEFAULT
              Color statusBg = const Color(0xFFE8F0FB);
              if (isCompleted) {
                statusColor = const Color(0xFF0F9B6E);
                statusBg = const Color(0xFFE6F7F2);
              } else if (isCancelled) {
                statusColor = Colors.redAccent;
                statusBg = const Color(0xFFFEF2F2);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9ECF0)),
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
                                        color: Color(0xFF1A3D6B),
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
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0F9B6E), shape: BoxShape.circle)),
                                        Container(width: 1.5, height: 20, color: const Color(0xFFE9ECF0)),
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
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
                                const Divider(height: 1, color: Color(0xFFE9ECF0)),
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
                                            color: Color(0xFF1A2233),
                                          ),
                                        ),
                                        Text(
                                          'Type: ${booking.parcelType}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7785)),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showBookingDetailsBottomSheet(context, booking),
                                          icon: const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1A3D6B)),
                                          label: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3D6B))),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            backgroundColor: const Color(0xFFE8F0FB),
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
                                              backgroundColor: const Color(0xFF1A3D6B),
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
    );
  }

  void _showBookingDetailsBottomSheet(BuildContext context, BookingModel initialBooking) async {
    final bookingFuture = context.read<BookingProvider>().fetchBookingById(initialBooking.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return FutureBuilder<BookingModel?>(
          future: bookingFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final booking = snapshot.data ?? initialBooking;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9ECF0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Details',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2233)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${booking.bookingId}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: booking.status == 'COMPLETED'
                                ? const Color(0xFFE6F7F2)
                                : booking.status == 'CANCELLED'
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFE8F0FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(
                              color: booking.status == 'COMPLETED'
                                  ? const Color(0xFF0F9B6E)
                                  : booking.status == 'CANCELLED'
                                      ? Colors.redAccent
                                      : const Color(0xFF1A3D6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE9ECF0)),
                    const SizedBox(height: 16),
                    const Text('ROUTE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7785))),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0F9B6E), shape: BoxShape.circle)),
                            Container(width: 1.5, height: 44, color: const Color(0xFFE9ECF0)),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP', style: TextStyle(fontSize: 9, color: Color(0xFF6B7785), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(booking.pickupAddressName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A2233))),
                              const SizedBox(height: 14),
                              const Text('DROP', style: TextStyle(fontSize: 9, color: Color(0xFF6B7785), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(booking.dropAddressName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A2233))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE9ECF0)),
                    const SizedBox(height: 16),
                    const Text('SHIPMENT & PARCEL INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7785))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile('Parcel Type', booking.parcelType, Icons.inventory_2_outlined),
                        ),
                        Expanded(
                          child: _buildDetailTile('Weight', '${booking.weightKg.toStringAsFixed(1)} KG', Icons.scale_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailTile(
                      'Goods Description',
                      booking.goodsDescription.isNotEmpty ? booking.goodsDescription : 'No description provided',
                      Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE9ECF0)),
                    const SizedBox(height: 16),
                    const Text('PAYMENT & FARE BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7785))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile('Payment Mode', booking.paymentMode, Icons.payment_rounded),
                        ),
                        Expanded(
                          child: _buildDetailTile('Estimated Fare', '₹${booking.totalFare.toStringAsFixed(2)}', Icons.calculate_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Charged Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A2233))),
                          Text(
                            '₹${booking.totalFare.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A3D6B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7785)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7785))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A2233))),
            ],
          ),
        ),
      ],
    );
  }
}
