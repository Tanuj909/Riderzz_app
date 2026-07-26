import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_booking_details_screen.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_all_bookings_screen.dart';
import 'package:riderzz_app/features/driver/profile/driver_profile_screen.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  Timer? _refreshTimer;
  Timer? _searchTimer;
  bool _isManualSearching = false;
  int _searchCountdown = 30;

  void _handleSearchBookings() {
    if (_isManualSearching) return;

    setState(() {
      _isManualSearching = true;
      _searchCountdown = 30;
    });

    // Trigger immediate API fetch
    context.read<DriverHomeProvider>().fetchHomeBookings();

    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final driverProvider = context.read<DriverHomeProvider>();
      // If a booking arrives during search, exit searching mode early
      if (driverProvider.pendingBookings.isNotEmpty) {
        timer.cancel();
        setState(() {
          _isManualSearching = false;
        });
        return;
      }

      if (_searchCountdown > 1) {
        setState(() {
          _searchCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isManualSearching = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchHomeBookings();
      context.read<DriverHomeProvider>().fetchDriverEarnings();
    });

    // Auto refresh pending bookings every 10 seconds (only for drivers with no active booking)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        final driverProvider = context.read<DriverHomeProvider>();
        if (driverProvider.activeBooking == null) {
          driverProvider.fetchHomeBookings(silent: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    final driverName = profile?.name ?? user?.name ?? 'Partner';
    final vehicleDetails = profile?.vehicle != null 
        ? '${profile!.vehicle!.make} ${profile.vehicle!.model}'
        : 'No vehicle details';
    final vehiclePlate = profile?.vehicleNumber ?? 'N/A';
    final isOnline = profile?.isOnline ?? false;
    final rating = profile?.rating ?? 5.0;
    final totalTrips = profile?.totalTrips ?? 0;

    String _getInitials(String? name) {
      if (name == null || name.trim().isEmpty) return 'D';
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await driverProvider.fetchDriverProfile();
          await driverProvider.fetchHomeBookings();
          await driverProvider.fetchDriverEarnings();
          await locationProvider.initialize();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header row: Status, Title, Toggle, Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF1C9A5B) : const Color(0xFFB0B8C4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.outfit(
                          color: isOnline ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ready for rides',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF121214),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Toggle Switch
                  GestureDetector(
                    onTap: () async {
                      if (isOnline) {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Go Offline?',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
                            ),
                            content: Text(
                              'Are you sure you want to go offline? You will stop receiving ride bookings.',
                              style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 14, height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD90429),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Go Offline'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      } else {
                        if (profile?.approvalStatus != 'APPROVED') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your account is still under review.'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }
                      }

                      final success = await driverProvider.toggleOnlineOffline();
                      if (success && context.mounted) {
                        final trackingService = context.read<LocationTrackingService>();
                        if (driverProvider.profile?.isOnline == true) {
                          trackingService.start();
                        } else {
                          trackingService.stop();
                        }
                      }
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(driverProvider.errorMessage ?? 'Failed to update status'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 48,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF1C9A5B) : const Color(0xFFE7E7EB),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            top: 3,
                            left: isOnline ? 25 : 3,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar Profile Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD90429), Color(0xFF900018)], // --red to --red-dark
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD90429).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(driverName),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Compact Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E1E6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05121214),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Today\'s Earnings',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C6F79),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${driverProvider.earnings?.todayEarnings.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: const Color(0xFFE1E1E6),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Earnings',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C6F79),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${driverProvider.earnings?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: const Color(0xFFE1E1E6),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Trips Completed',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C6F79),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${driverProvider.earnings?.totalCompletedTrips ?? 0}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFD90429),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bookings in your area! Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Bookings in your area!',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6C6F79),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD90429),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x4DD90429), blurRadius: 4, spreadRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverAllBookingsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'All Bookings',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFD90429),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Bookings in your area! Content Section ──
          if (driverProvider.activeBooking == null) ...[
            if (driverProvider.isBookingsLoading || _isManualSearching)
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                ),
                child: const Center(
                  child: RadarPulseAnimation(),
                ),
              )
            else if (driverProvider.pendingBookings.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: driverProvider.pendingBookings.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final booking = driverProvider.pendingBookings[index];
                    final fullCardWidth = MediaQuery.of(context).size.width - 40;
                    return Container(
                      width: fullCardWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE1E1E6)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x08121214), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD90429).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'NEW BOOKING',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFD90429),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (booking.expiresInSeconds != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${booking.expiresInSeconds}s left',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFE65100),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${booking.totalFare.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF121214),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showBookingModal(context, booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD90429),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Text(
                              'View',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_off_outlined, size: 40, color: Color(0xFFA2A5AE)),
                    const SizedBox(height: 10),
                    Text(
                      'No bookings in your area',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF121214),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No new bookings arrived in your radius recently.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6C6F79),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _handleSearchBookings,
                      icon: const Icon(Icons.radar_rounded, size: 18),
                      label: Text(
                        'Search Bookings',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF121214),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          if (driverProvider.activeBooking != null) ...[
            // Active Ride Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFCFCFD)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE1E1E6).withValues(alpha: 0.8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F121214),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C9A5B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          driverProvider.activeBooking!.status,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1C9A5B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '₹${driverProvider.activeBooking!.totalFare.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'BOOKING ID: ${driverProvider.activeBooking!.bookingId}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA2A5AE),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 5),
                          const Icon(Icons.circle, size: 8, color: Color(0xFF121214)),
                          Container(
                            width: 1.5,
                            height: 30,
                            color: const Color(0xFFE1E1E6),
                          ),
                          const Icon(Icons.location_on, size: 14, color: Color(0xFFD90429)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverProvider.activeBooking!.pickupAddressName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              driverProvider.activeBooking!.dropAddressName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverBookingDetailsScreen(
                              booking: driverProvider.activeBooking!,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC2D3B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text('View Active Ride Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Current Location Empty Section
          GestureDetector(
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fetching location...'), duration: Duration(seconds: 1)),
              );
              await locationProvider.initialize();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E1E6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05121214),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                    ),
                    child: const Icon(Icons.my_location, size: 16, color: Color(0xFF121214)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6C6F79),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locationProvider.currentAddress ?? (locationProvider.isInitialized ? 'Location not found, tap to retry' : 'Tap to fetch your location'),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
}

  void _showBookingModal(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E1E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD90429).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW BOOKING REQUEST',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFD90429),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (booking.expiresInSeconds != null)
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(
                          'Expires: ${booking.expiresInSeconds}s',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFE65100),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '₹${booking.totalFare.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF121214),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      const Icon(Icons.circle_outlined, size: 14, color: Color(0xFF1C9A5B)),
                      Container(
                        width: 2,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: const Color(0xFFE1E1E6),
                      ),
                      const Icon(Icons.location_on, size: 16, color: Color(0xFFD90429)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PICKUP',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6C6F79),
                          ),
                        ),
                        Text(
                          booking.pickupAddressName,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DROP OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6C6F79),
                          ),
                        ),
                        Text(
                          booking.dropAddressName,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (booking.estimatedDistanceKm != null)
                    Text(
                      'Distance: ${booking.estimatedDistanceKm!.toStringAsFixed(1)} km',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    'Payment: ${booking.paymentMode}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF6C6F79),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverBookingDetailsScreen(
                          booking: booking,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RadarPulseAnimation extends StatefulWidget {
  const RadarPulseAnimation({super.key});

  @override
  State<RadarPulseAnimation> createState() => _RadarPulseAnimationState();
}

class _RadarPulseAnimationState extends State<RadarPulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100 * _animation.value,
              height: 100 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C9A5B).withValues(alpha: (1.0 - _animation.value) * 0.4),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C9A5B).withValues(alpha: 0.15),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1C9A5B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x401C9A5B), blurRadius: 6, spreadRadius: 2),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
