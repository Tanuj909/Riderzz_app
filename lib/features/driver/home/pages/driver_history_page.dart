import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_booking_details_screen.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Upcoming'];
  
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<DriverRepository>();
      final data = await repo.getDriverBookings(page: 0, size: 50);
      if (mounted) {
        setState(() {
          _bookings = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<BookingModel> get _filteredBookings {
    if (_selectedFilter == 'All') return _bookings;
    return _bookings.where((booking) {
      final status = booking.status.toUpperCase();
      if (_selectedFilter == 'Completed') {
        return status == 'DELIVERED' || status == 'COMPLETED';
      } else if (_selectedFilter == 'Cancelled') {
        return status == 'CANCELLED';
      } else if (_selectedFilter == 'Upcoming') {
        return status != 'DELIVERED' && status != 'COMPLETED' && status != 'CANCELLED';
      }
      return true;
    }).toList();
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year • $hour:$min $amPm';
    } catch (_) {
      final parts = dateStr.split('T');
      if (parts.length > 1) {
        return parts[0];
      }
      return dateStr;
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
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          color: const Color(0xFFD90429),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                  ),
                )
              : _error != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 100),
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF4A5568),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                            child: Text(
                              'Rides History',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          
                          // Chips Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            child: Row(
                              children: _filters.map((filter) {
                                final isActive = _selectedFilter == filter;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF121214) : Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isActive ? const Color(0xFF121214) : const Color(0xFFE1E1E6),
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: GoogleFonts.outfit(
                                        color: isActive ? Colors.white : const Color(0xFF6C6F79),
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Trip Cards
                          if (_filteredBookings.isEmpty)
                            Container(
                              height: 200,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE1E1E6)),
                              ),
                              child: Text(
                                'No rides found in this category.',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF6C6F79),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = _filteredBookings[index];
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

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                                _formatDate(booking.createdAt),
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
                                      
                                      // Actions Bottom Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DriverBookingDetailsScreen(booking: booking),
                                              ),
                                            );
                                            if (result == 'go_to_wallet' && context.mounted) {
                                              final homeState = context.findAncestorStateOfType<DriverHomeScreenState>();
                                              if (homeState != null) {
                                                homeState.setIndex(2);
                                              }
                                            }
                                          },
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
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
