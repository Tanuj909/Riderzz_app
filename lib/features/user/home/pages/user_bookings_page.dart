import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year • $hour:$min $amPm';
    } catch (_) {
      final parts = isoString.split('T');
      if (parts.length > 1) {
        return parts[0];
      }
      return isoString;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACTIVE':
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_ARRIVED':
      case 'DRIVER_ARRIVED_DROP':
      case 'OTP_VERIFIED':
      case 'GOODS_PICKED_UP':
      case 'IN_TRANSIT':
        return 'Active';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Filter
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 12, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Bookings',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              PopupMenuButton<String>(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedStatusFilter == 'ALL' ? const Color(0xFFF1F5F9) : const Color(0xFFFDF2F4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: _selectedStatusFilter == 'ALL' ? const Color(0xFF64748B) : const Color(0xFFC62E42),
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  setState(() {
                    _selectedStatusFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'ALL',
                    child: Text(
                      'All Bookings',
                      style: GoogleFonts.outfit(
                        fontWeight: _selectedStatusFilter == 'ALL' ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedStatusFilter == 'ALL' ? const Color(0xFFC62E42) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'PENDING',
                    child: Text(
                      'Pending',
                      style: GoogleFonts.outfit(
                        fontWeight: _selectedStatusFilter == 'PENDING' ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedStatusFilter == 'PENDING' ? const Color(0xFFC62E42) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ACTIVE',
                    child: Text(
                      'Active',
                      style: GoogleFonts.outfit(
                        fontWeight: _selectedStatusFilter == 'ACTIVE' ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedStatusFilter == 'ACTIVE' ? const Color(0xFFC62E42) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'DELIVERED',
                    child: Text(
                      'Delivered',
                      style: GoogleFonts.outfit(
                        fontWeight: _selectedStatusFilter == 'DELIVERED' ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedStatusFilter == 'DELIVERED' ? const Color(0xFFC62E42) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'CANCELLED',
                    child: Text(
                      'Cancelled',
                      style: GoogleFonts.outfit(
                        fontWeight: _selectedStatusFilter == 'CANCELLED' ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedStatusFilter == 'CANCELLED' ? const Color(0xFFC62E42) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Active Filter Info chip
        if (_selectedStatusFilter != 'ALL')
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Chip(
              label: Text(
                'Status: ${_getStatusLabel(_selectedStatusFilter)}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC62E42)),
              ),
              backgroundColor: const Color(0xFFFDF2F4),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFC62E42)),
              onDeleted: () {
                setState(() {
                  _selectedStatusFilter = 'ALL';
                });
              },
            ),
          ),

        Expanded(
          child: Consumer<BookingProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.bookings.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC62E42)),
                  ),
                );
              }

              if (provider.errorMessage != null && provider.bookings.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => provider.fetchBookings(page: 0),
                  color: const Color(0xFFC62E42),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62E42), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62E42)),
                            onPressed: () => provider.fetchBookings(page: 0),
                            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Apply status filter locally
              final filteredBookings = _selectedStatusFilter == 'ALL'
                  ? provider.bookings
                  : _selectedStatusFilter == 'ACTIVE'
                      ? provider.bookings.where((b) {
                          final s = b.status.toUpperCase();
                          return s == 'DRIVER_ASSIGNED' ||
                              s == 'DRIVER_ARRIVED' ||
                              s == 'DRIVER_ARRIVED_DROP' ||
                              s == 'OTP_VERIFIED' ||
                              s == 'GOODS_PICKED_UP' ||
                              s == 'IN_TRANSIT';
                        }).toList()
                      : provider.bookings.where((b) => b.status.toUpperCase() == _selectedStatusFilter).toList();

              if (filteredBookings.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => provider.fetchBookings(page: 0),
                  color: const Color(0xFFC62E42),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _selectedStatusFilter == 'ALL' ? 'No Bookings Yet' : 'No matching bookings',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedStatusFilter == 'ALL'
                                ? 'Your ride history will appear here once you make a booking.'
                                : 'No bookings found with the selected status filter.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => provider.fetchBookings(page: 0),
                      color: const Color(0xFFC62E42),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                    final isCompleted = booking.status.toUpperCase() == 'DELIVERED' || booking.status.toUpperCase() == 'COMPLETED';
                    final isCancelled = booking.status.toUpperCase() == 'CANCELLED';

                    Color statusColor = const Color(0xFF2563EB); // Blue/Transit/Assigned
                    Color statusBg = const Color(0xFFEFF6FF);
                    if (isCompleted) {
                      statusColor = const Color(0xFF16A34A);
                      statusBg = const Color(0xFFF0FDF4);
                    } else if (isCancelled) {
                      statusColor = const Color(0xFFDC2626);
                      statusBg = const Color(0xFFFEF2F2);
                    } else if (booking.status.toUpperCase() == 'PENDING') {
                      statusColor = const Color(0xFFD97706);
                      statusBg = const Color(0xFFFEF3C7);
                    }

                    final showTrackButton = booking.status.toUpperCase() != 'CANCELLED' &&
                        booking.status.toUpperCase() != 'DELIVERED' &&
                        booking.status.toUpperCase() != 'COMPLETED';

                    final cardWidget = Container(
                      margin: const EdgeInsets.only(bottom: 16, top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: ID and Status badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                booking.bookingId,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  _getStatusLabel(booking.status),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Pickup & Drop visual connect bar and texts (perfectly aligned)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 5), // aligned with first line of text
                                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                                  Container(width: 1.5, height: 20, color: const Color(0xFFE2E8F0)),
                                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.pickupAddressName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      booking.dropAddressName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Info Row: Date & Time and Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDateTime(booking.createdAt),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${booking.totalFare.toStringAsFixed(1)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          
                          // Actions Bottom buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => showBookingDetailsBottomSheet(context, booking),
                                  icon: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF475569)),
                                  label: Text(
                                    'View Details',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              if (showTrackButton) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton.icon(
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
                                      ).then((_) {
                                        if (context.mounted) {
                                          Provider.of<BookingProvider>(context, listen: false).fetchBookings(page: 0);
                                          Provider.of<BookingProvider>(context, listen: false).fetchCurrentBookings();
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.my_location_rounded, size: 14, color: Colors.white),
                                    label: Text(
                                      'Track Ride',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: const Color(0xFFC62E42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );

                    if (booking.fastDelivery) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          cardWidget,
                          Positioned(
                            top: -8,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
              ),
            ),
            // Pagination Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.currentPage > 0
                          ? () {
                              provider.fetchBookings(page: provider.currentPage - 1);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF475569),
                        disabledBackgroundColor: const Color(0xFFF8FAFC),
                        disabledForegroundColor: const Color(0xFFCBD5E1),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Page ${provider.currentPage + 1}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121214),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: provider.hasMore
                          ? () {
                              provider.fetchBookings(page: provider.currentPage + 1);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62E42),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                        disabledForegroundColor: const Color(0xFFCBD5E1),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
            },
          ),
        ),
      ],
    );
  }
}
