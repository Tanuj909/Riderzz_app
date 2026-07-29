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
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/driver/profile/driver_profile_screen.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
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

  }

  @override
  void dispose() {
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
          await driverProvider.fetchDriverProfile(force: true);
          await driverProvider.fetchHomeBookings();
          await driverProvider.fetchDriverEarnings(force: true);
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: driverProvider.pendingBookings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = driverProvider.pendingBookings[index];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A121214), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD90429).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NEW REQUEST',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFD90429),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (booking.fastDelivery) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.flash_on_rounded,
                                      size: 11,
                                      color: Color(0xFFE65100),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Fast Delivery',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFE65100),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (booking.expiresInSeconds != null) ...[
                              const Icon(
                                  Icons.timer_outlined,
                                size: 13,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${booking.expiresInSeconds}s left',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFE65100),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE1E1E6)),
                        const SizedBox(height: 12),
 
                        // 2. Price, distance and details action button
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DISTANCE',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFA2A5AE),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.estimatedDistanceKm != null
                                      ? '${booking.estimatedDistanceKm!.toStringAsFixed(1)} km'
                                      : 'N/A',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF121214),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EST. FARE',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFA2A5AE),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${booking.totalFare.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1C9A5B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverBookingDetailsScreen(
                                      booking: booking,
                                    ),
                                  ),
                                );
                                if (result == 'go_to_wallet' && context.mounted) {
                                  final homeState = context.findAncestorStateOfType<DriverHomeScreenState>();
                                  if (homeState != null) {
                                    homeState.setIndex(2);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD90429),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: Text(
                                'View Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 10),
                  Text(
                    'BOOKING ID: ${driverProvider.activeBooking!.bookingId}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA2A5AE),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.circle, size: 8, color: Color(0xFF121214)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              driverProvider.activeBooking!.pickupAddressName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.location_on, size: 12, color: Color(0xFFD90429)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              driverProvider.activeBooking!.dropAddressName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverBookingDetailsScreen(
                              booking: driverProvider.activeBooking!,
                            ),
                          ),
                        );
                        if (result == 'go_to_wallet' && context.mounted) {
                          final homeState = context.findAncestorStateOfType<DriverHomeScreenState>();
                          if (homeState != null) {
                            homeState.setIndex(2);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC2D3B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Active Ride Details',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
