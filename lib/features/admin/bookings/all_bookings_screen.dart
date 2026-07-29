import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';

class AdminAllBookingsScreen extends StatefulWidget {
  const AdminAllBookingsScreen({super.key});

  @override
  State<AdminAllBookingsScreen> createState() => _AdminAllBookingsScreenState();
}

class _AdminAllBookingsScreenState extends State<AdminAllBookingsScreen>
    with SingleTickerProviderStateMixin {
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'ALL';
  late TabController _tabController;

  static const List<String> _filterOptions = [
    'ALL',
    'PENDING',
    'ACTIVE',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _filterOptions[_tabController.index];
          _applyFilter();
        });
      }
    });
    _fetchAllBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (_selectedFilter == 'ALL') {
      _filteredBookings = List.from(_bookings);
    } else if (_selectedFilter == 'ACTIVE') {
      _filteredBookings = _bookings.where((b) {
        final s = b.status.toUpperCase();
        return s != 'CANCELLED' && s != 'DELIVERED' && s != 'COMPLETED' && s != 'PENDING';
      }).toList();
    } else if (_selectedFilter == 'DELIVERED') {
      _filteredBookings = _bookings.where((b) {
        final s = b.status.toUpperCase();
        return s == 'DELIVERED' || s == 'COMPLETED';
      }).toList();
    } else {
      _filteredBookings = _bookings
          .where((b) => b.status.toUpperCase() == _selectedFilter)
          .toList();
    }
  }

  Future<void> _fetchAllBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<DriverRepository>();
      final data = await repo.getAllBookings(page: 0, size: 100);
      if (mounted) {
        setState(() {
          _bookings = data;
          _applyFilter();
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
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, $hour:${dt.minute.toString().padLeft(2, '0')} $period';
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
      case 'EN_ROUTE':
      case 'DRIVER_ARRIVED_DROP':
        return const Color(0xFF1C9A5B);
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF0369A1);
      case 'CANCELLED':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFF6C6F79);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'DRIVER_ASSIGNED':
      case 'ACCEPTED':
      case 'EN_ROUTE':
        return Icons.person_pin_circle_rounded;
      case 'DRIVER_ARRIVED':
        return Icons.location_on_rounded;
      case 'IN_TRANSIT':
      case 'GOODS_PICKED_UP':
        return Icons.local_shipping_rounded;
      case 'DELIVERED':
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Bookings',
          style: GoogleFonts.outfit(
            color: const Color(0xFF121214),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFFD90429),
              unselectedLabelColor: const Color(0xFFA2A5AE),
              labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
              indicatorColor: const Color(0xFFD90429),
              indicatorWeight: 2.5,
              tabAlignment: TabAlignment.start,
              tabs: _filterOptions
                  .map((f) => Tab(
                        text: f == 'ALL'
                            ? 'All (${_bookings.length})'
                            : f == 'ACTIVE'
                                ? 'Active'
                                : f == 'DELIVERED'
                                    ? 'Delivered'
                                    : f[0] + f.substring(1).toLowerCase(),
                      ))
                  .toList(),
            ),
          ),
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
                ? _buildErrorState()
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : _buildBookingsList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF121214),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31C2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _fetchAllBookings,
              child: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.assignment_turned_in_outlined, size: 36, color: Color(0xFFA2A5AE)),
              ),
              const SizedBox(height: 20),
              Text(
                'No Bookings Found',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121214),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'ALL'
                    ? 'No bookings have been created yet.'
                    : 'No ${_selectedFilter.toLowerCase()} bookings found.',
                style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        final statusColor = _getStatusColor(booking.status);
        final statusIcon = _getStatusIcon(booking.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x06121214), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status badge + Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${booking.totalFare.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF121214),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Booking ID
              Text(
                booking.bookingId,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA2A5AE),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Pickup & Drop with dynamic connector
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C9A5B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        const Icon(Icons.location_on, size: 12, color: Color(0xFFD90429)),
                        const SizedBox(height: 2),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            booking.pickupAddressName,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Drop',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            booking.dropAddressName,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Customer & Driver info row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Customer:',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.customer?.fullName ?? 'N/A',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          booking.customer?.phone ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (booking.driver != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Driver:',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.driver!.fullName,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (booking.vehicleNumber != null && booking.vehicleNumber!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                booking.vehicleNumber!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Date + Parcel type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(booking.createdAt),
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.parcelType} · ${booking.weightKg} kg',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF6C6F79),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Fast delivery badge
              if (booking.fastDelivery) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Fast Delivery',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
