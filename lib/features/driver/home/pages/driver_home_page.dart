import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_booking_details_screen.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_all_bookings_screen.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchHomeBookings();
    });
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
                        style: TextStyle(
                          color: isOnline ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ready for rides',
                    style: TextStyle(
                      color: Color(0xFF121214),
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
                            title: const Text(
                              'Go Offline?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                            ),
                            content: const Text(
                              'Are you sure you want to go offline? You will stop receiving ride bookings.',
                              style: TextStyle(color: Color(0xFF6C6F79), fontSize: 14, height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C6F79))),
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
                  Container(
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
                      const Text(
                        'Today\'s Earnings',
                        style: TextStyle(
                          color: Color(0xFF6C6F79),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹1,450', // Mock data
                        style: const TextStyle(
                          color: Color(0xFF121214),
                          fontSize: 18,
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
                      const Text(
                        'Trips Completed',
                        style: TextStyle(
                          color: Color(0xFF6C6F79),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalTrips.toString(),
                        style: const TextStyle(
                          color: Color(0xFFD90429),
                          fontSize: 18,
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
                  const Text(
                    'Bookings in your area!',
                    style: TextStyle(
                      color: Color(0xFF6C6F79),
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
                child: const Text(
                  'All Bookings',
                  style: TextStyle(
                    color: Color(0xFFD90429),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Map Overview Placeholder (Live Location Area)
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // light map background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E1E6)),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1C9A5B).withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C9A5B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            color: Color(0xFF6C6F79),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locationProvider.currentAddress ?? (locationProvider.isInitialized ? 'Location not found, tap to retry' : 'Tap to fetch your location'),
                          style: const TextStyle(
                            color: Color(0xFF121214),
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
          const SizedBox(height: 24),

          if (driverProvider.isBookingsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                ),
              ),
            )
          else if (driverProvider.activeBooking != null) ...[
            // Active Ride Card Header
            const Text(
              'Your Active Trip',
              style: TextStyle(
                color: Color(0xFF6C6F79),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
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
                border: Border.all(color: const Color(0xFFE1E1E6).withOpacity(0.8)),
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
                          color: const Color(0xFF1C9A5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          driverProvider.activeBooking!.status,
                          style: const TextStyle(
                            color: Color(0xFF1C9A5B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '₹${driverProvider.activeBooking!.totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF121214),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'BOOKING ID: ${driverProvider.activeBooking!.bookingId}',
                    style: const TextStyle(
                      color: Color(0xFFA2A5AE),
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
                          const SizedBox(height: 4),
                          const Icon(Icons.circle, size: 8, color: Color(0xFF121214)),
                          Container(
                            width: 1.5,
                            height: 38,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFFE1E1E6),
                          ),
                          const Icon(Icons.location_on, size: 12, color: Color(0xFFD90429)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverProvider.activeBooking!.pickupAddressName,
                              style: const TextStyle(
                                color: Color(0xFF121214),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              driverProvider.activeBooking!.dropAddressName,
                              style: const TextStyle(
                                color: Color(0xFF121214),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
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
                        backgroundColor: const Color(0xFF121214),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('View Active Ride Details', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (driverProvider.pendingBookings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.explore_off_outlined, size: 48, color: Color(0xFFA2A5AE)),
                    SizedBox(height: 12),
                    Text(
                      'No bookings in your area',
                      style: TextStyle(
                        color: Color(0xFF121214),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We\'ll notify you when a customer requests a ride nearby.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6C6F79),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...driverProvider.pendingBookings.map((booking) {
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
                              color: const Color(0xFFD90429).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Color(0xFFD90429),
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
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  booking.dropAddressName,
                                  style: const TextStyle(
                                    color: Color(0xFF121214),
                                    fontSize: 13.5,
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
                            'Type: ${booking.parcelType} (${booking.weightKg} kg)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Payment: ${booking.paymentMode}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
              }).toList(),
          ],
        ],
      ),
    ),
  ),
);
}
}
