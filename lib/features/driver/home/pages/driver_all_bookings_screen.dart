import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_booking_details_screen.dart';

class DriverAllBookingsScreen extends StatefulWidget {
  const DriverAllBookingsScreen({super.key});

  @override
  State<DriverAllBookingsScreen> createState() => _DriverAllBookingsScreenState();
}

class _DriverAllBookingsScreenState extends State<DriverAllBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  Future<void> _fetchAllBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<DriverRepository>();
      final data = await repo.getAllBookings(page: 0, size: 50);
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _bookings = data.where((booking) {
            final created = DateTime.tryParse(booking.createdAt);
            if (created == null) return false;
            return created.year == now.year &&
                   created.month == now.month &&
                   created.day == now.day;
          }).toList();
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFB9700A);
      case 'ACCEPTED':
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_ARRIVED':
      case 'OTP_VERIFIED':
      case 'GOODS_PICKED_UP':
      case 'IN_TRANSIT':
      case 'DRIVER_ARRIVED_DROP':
        return const Color(0xFF1C9A5B);
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF1C9A5B);
      case 'CANCELLED':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFF6C6F79);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'All System Bookings',
          style: TextStyle(
            color: Color(0xFF121214),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllBookings,
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
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31C2E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _fetchAllBookings,
                            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  )
                : _bookings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in_outlined, size: 64, color: Color(0xFFA2A5AE)),
                                SizedBox(height: 16),
                                Text(
                                  'No Bookings Found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'There are no bookings in the system.',
                                  style: TextStyle(color: Color(0xFF6C6F79), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final statusColor = _getStatusColor(booking.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE1E1E6)),
                              boxShadow: const [
                                BoxShadow(color: Color(0x05121214), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        booking.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${booking.totalFare.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF121214),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ID: ${booking.bookingId}',
                                  style: const TextStyle(
                                    color: Color(0xFFA2A5AE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        const SizedBox(height: 2),
                                        const Icon(Icons.circle_outlined, size: 12, color: Color(0xFF121214)),
                                        Container(
                                          width: 2,
                                          height: 24,
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          color: const Color(0xFFE1E1E6),
                                        ),
                                        const Icon(Icons.location_on, size: 14, color: Color(0xFFD90429)),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.pickupAddressName,
                                            style: const TextStyle(
                                              color: Color(0xFF121214),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            booking.dropAddressName,
                                            style: const TextStyle(
                                              color: Color(0xFF121214),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(booking.createdAt),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6C6F79)),
                                    ),
                                    Text(
                                      'Type: ${booking.parcelType}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6C6F79), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DriverBookingDetailsScreen(
                                            booking: booking,
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD90429),
                                      side: const BorderSide(color: Color(0xFFD90429)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
