import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_booking_details_screen.dart';

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
        return status == 'PENDING' || status == 'ACCEPTED' || status == 'DRIVER_ASSIGNED' || status == 'OTP_VERIFIED' || status == 'GOODS_PICKED_UP' || status == 'IN_TRANSIT';
      }
      return true;
    }).toList();
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, ${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return dateStr;
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
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
                              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14, fontFamily: 'Outfit'),
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
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 20.0),
                            child: Text(
                              'Rides History',
                              style: TextStyle(
                                color: Color(0xFF121214),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Plus Jakarta Sans',
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
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: isActive ? const Color(0xFF121214) : const Color(0xFFE1E1E6),
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color: isActive ? Colors.white : const Color(0xFF6C6F79),
                                        fontSize: 13,
                                        fontFamily: 'Outfit',
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
                              child: const Text(
                                'No rides found in this category.',
                                style: TextStyle(color: Color(0xFF6C6F79), fontSize: 13, fontFamily: 'Outfit'),
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

                                final statusColor = isCompleted
                                    ? const Color(0xFF1C9A5B)
                                    : (isCancelled ? const Color(0xFFD90429) : const Color(0xFFB9700A));

                                final statusBg = isCompleted
                                    ? const Color(0xFFE7F7EF)
                                    : (isCancelled ? const Color(0xFFFDEBEC) : const Color(0xFFFCF0DC));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE1E1E6)),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x02121214), blurRadius: 6, offset: Offset(0, 1)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top row: ID and Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            booking.bookingId,
                                            style: const TextStyle(
                                              color: Color(0xFF6C6F79),
                                              fontSize: 11.5,
                                              fontFamily: 'Outfit',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  booking.status,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 9.5,
                                                    fontFamily: 'Outfit',
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // Pickup Location Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 12,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.circle, color: Color(0xFF1C9A5B), size: 8),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              booking.pickupAddressName,
                                              style: const TextStyle(
                                                color: Color(0xFF121214),
                                                fontSize: 13.5,
                                                fontFamily: 'Outfit',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Aligned connecting line
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5.0),
                                        child: Container(
                                          width: 1,
                                          height: 8,
                                          color: const Color(0xFFE1E1E6),
                                        ),
                                      ),
                                      // Drop Location Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 12,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.location_on, color: Color(0xFFD90429), size: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              booking.dropAddressName,
                                              style: const TextStyle(
                                                color: Color(0xFF121214),
                                                fontSize: 13.5,
                                                fontFamily: 'Outfit',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // Date & Earnings
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDate(booking.createdAt),
                                            style: const TextStyle(
                                              color: Color(0xFF6C6F79),
                                              fontSize: 12,
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                          Text(
                                            '₹${booking.totalFare.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF121214),
                                              fontSize: 14,
                                              fontFamily: 'IBM Plex Mono',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Action Buttons
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DriverBookingDetailsScreen(booking: booking),
                                            ),
                                          ).then((_) => _fetchHistory());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF121214),
                                          side: const BorderSide(color: Color(0xFFE1E1E6)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          minimumSize: const Size(double.infinity, 38),
                                          elevation: 0,
                                        ),
                                        child: const Text('Details', style: TextStyle(fontFamily: 'Outfit', fontSize: 13)),
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
