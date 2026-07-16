import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/pages/choose_vehicle_screen.dart';
import 'package:riderzz_app/features/user/home/pages/booking_flow_bottom_sheet.dart';
import 'package:riderzz_app/features/user/home/pages/finding_driver_screen.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/widgets/booking_details_bottom_sheet.dart';
import 'dart:ui';
import 'dart:math';

class UserHomePage extends StatefulWidget {
  final VoidCallback onBookingConfirmed;

  const UserHomePage({
    super.key,
    required this.onBookingConfirmed,
  });

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Map<String, dynamic>? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavedRouteProvider>(context, listen: false).fetchSavedRoutes();
      Provider.of<BookingProvider>(context, listen: false).fetchBookings();
      Provider.of<BookingProvider>(context, listen: false).fetchCurrentBookings();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          Provider.of<SavedRouteProvider>(context, listen: false).fetchSavedRoutes(),
          Provider.of<BookingProvider>(context, listen: false).fetchBookings(),
          Provider.of<BookingProvider>(context, listen: false).fetchCurrentBookings(),
        ]);
      },
      color: const Color(0xFFE31C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GOOD AFTERNOON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xFFA2A5AE),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Where's it going?",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.18,
                      color: Color(0xFF121214),
                    ),
                  ),
                ],
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE31C2E), Color(0xFFAE1220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(user?.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Map Hero
          GestureDetector(
            onTap: () => _showNewBookingModal(),
            child: Container(
              height: 172,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE7E7EB)),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9F9FA), Color(0xFFE8E8ED)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  // Animated Route and Map Pins
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double t = _animController.value;
                          final double T = t * 12600;
                          
                          double cameraX = 60.0;
                          double cameraY = 70.0;
                          double cameraScale = 1.0;
                          
                          double pickupReveal = 0.0;
                          double dropReveal = 0.0;
                          double drawProgress = 0.0;
                          
                          // Continuous pulse for revealed markers
                          final double pulseT = (T % 2000) / 2000;
                          double pulseScale = 0.5;
                          double pulseOpacity = 0.0;
                          if (pulseT <= 0.7) {
                            final pt = pulseT / 0.7;
                            pulseScale = 0.5 + (2.0 * pt);
                            pulseOpacity = 0.6 * (1.0 - pt);
                          }
                          
                          if (T < 1400) {
                            cameraX = 60; cameraY = 70; cameraScale = 1.6;
                            pickupReveal = T > 400 ? ((T - 400) / 400).clamp(0.0, 1.0) : 0.0;
                            drawProgress = 0.0;
                            dropReveal = 0.0;
                          } else if (T < 4900) {
                            pickupReveal = 1.0;
                            dropReveal = 0.0;
                            final progress = (T - 1400) / 3500;
                            final easeProgress = -(cos(pi * progress) - 1) / 2;
                            drawProgress = easeProgress;
                            cameraX = 60 + (320 - 60) * easeProgress;
                            
                            // Accurately track the HTML bezier Y
                            if (easeProgress < 0.5) {
                              final rt = easeProgress * 2;
                              cameraY = (pow(1 - rt, 2) * 70 + 2 * (1 - rt) * rt * 130 + pow(rt, 2) * 86).toDouble();
                            } else {
                              final rt = (easeProgress - 0.5) * 2;
                              cameraY = (pow(1 - rt, 2) * 86 + 2 * (1 - rt) * rt * 42 + pow(rt, 2) * 60).toDouble();
                            }
                            cameraScale = 1.6;
                          } else if (T < 6100) {
                            drawProgress = 1.0;
                            cameraX = 320; cameraY = 60; cameraScale = 1.6;
                            pickupReveal = 1.0;
                            dropReveal = ((T - 4900) / 400).clamp(0.0, 1.0);
                          } else if (T < 7100) {
                            drawProgress = 1.0;
                            pickupReveal = 1.0;
                            dropReveal = 1.0;
                            final zoomProgress = (T - 6100) / 1000;
                            final easeZoom = sin(zoomProgress * pi / 2);
                            final midX = 190.0;
                            final midY = 65.0; 
                            cameraX = 320 + (midX - 320) * easeZoom;
                            cameraY = 60 + (midY - 60) * easeZoom;
                            cameraScale = 1.6 + (1.0 - 1.6) * easeZoom;
                          } else {
                            drawProgress = 1.0;
                            pickupReveal = 1.0;
                            dropReveal = 1.0;
                            cameraX = 190.0; cameraY = 65.0; cameraScale = 1.0;
                          }
                          
                          final routeFlowValue = drawProgress >= 1.0 ? ((T % 1000) / 1000) : 0.0;
                          
                          final centerX = constraints.maxWidth / 2;
                          // Shift the visual center slightly up (-10) so the deep curve doesn't clip behind the button
                          final centerY = (constraints.maxHeight / 2) - 10; 
                          final transform = Matrix4.identity()
                            ..translate(centerX - cameraX * cameraScale, centerY - cameraY * cameraScale)
                            ..scale(cameraScale);

                          return Transform(
                            transform: transform,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _RoutePainter(
                                      animationValue: routeFlowValue,
                                      drawProgress: drawProgress,
                                    ),
                                  ),
                                ),
                                // Pickup Marker
                                Positioned(
                                  left: 60 - 24, top: 70 - 38,
                                  child: Transform.scale(
                                    scale: pickupReveal,
                                    child: SizedBox(
                                      width: 48, height: 48,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(top: 31, child: Transform.scale(scale: pulseScale, child: Opacity(opacity: pulseOpacity, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFF121214), shape: BoxShape.circle))))),
                                          const Positioned(top: 10, child: Icon(Icons.location_on, color: Color(0xFF121214), size: 28)),
                                          Positioned(bottom: 42, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF121214), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))]), child: const Text('Pickup', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Drop Marker
                                Positioned(
                                  left: 320 - 24, top: 60 - 38,
                                  child: Transform.scale(
                                    scale: dropReveal,
                                    child: SizedBox(
                                      width: 48, height: 48,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(top: 31, child: Transform.scale(scale: pulseScale, child: Opacity(opacity: pulseOpacity, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFE31C2E), shape: BoxShape.circle))))),
                                          const Positioned(top: 10, child: Icon(Icons.location_on, color: Color(0xFFE31C2E), size: 28)),
                                          Positioned(bottom: 42, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE31C2E), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))]), child: const Text('Drop', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                        ],
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
                  ),

                  // New booking button
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2E121214),
                            offset: Offset(0, 10),
                            blurRadius: 26,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New booking',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF121214),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE31C2E),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Saved Location Dropdown
          Consumer<SavedRouteProvider>(
            builder: (context, savedRouteProvider, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: PopupMenuButton<String>(
                      position: PopupMenuPosition.under,
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(0, 6),
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedRoute = savedRouteProvider.savedRoutes.firstWhere(
                            (r) => (r['id']?.toString() ?? r['routeName']?.toString()) == val
                          );
                        });
                      },
                      itemBuilder: (context) {
                        return savedRouteProvider.savedRoutes.map((route) {
                          return PopupMenuItem<String>(
                            value: route['id']?.toString() ?? route['routeName']?.toString(),
                            child: Center(
                              child: Text(
                                route['routeName'] ?? 'Unknown Route',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF121214)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFFA2A5AE), size: 16),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _selectedRoute?['routeName']?.toString() ?? 'Saved locations',
                                  style: TextStyle(
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w600, 
                                    color: _selectedRoute == null ? const Color(0xFF16171C) : const Color(0xFF121214),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA2A5AE), size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
          
          if (_selectedRoute != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showNewBookingModal(_selectedRoute),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31C2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x337E22CE), blurRadius: 10, offset: Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Continue with route',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 22),
          ],

          Consumer2<BookingProvider, AdminVehiclesProvider>(
            builder: (context, bookingProvider, vehiclesProvider, child) {
              if (bookingProvider.isLoading && bookingProvider.currentBookings.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E))),
                ));
              }

              final inactiveStatuses = ['DELIVERED', 'COMPLETED', 'CANCELLED'];
              final activeBookings = bookingProvider.currentBookings.where(
                (b) => !inactiveStatuses.contains(b.status.toUpperCase()),
              ).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeBookings.isNotEmpty) ...[
                    const Text(
                      'ACTIVE SHIPMENTS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFFA2A5AE)),
                    ),
                    const SizedBox(height: 12),
                    ...activeBookings.map((activeBooking) {
                      return GestureDetector(
                        onTap: () {
                          showBookingDetailsBottomSheet(context, activeBooking);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 22),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE7E7EB)),
                            boxShadow: const [BoxShadow(color: Color(0x0D121214), offset: Offset(0, 1), blurRadius: 2)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(colors: [Color(0xFFE31C2E), Color(0xFFAE1220)]),
                                      boxShadow: const [BoxShadow(color: Color(0x667E22CE), offset: Offset(0, 6), blurRadius: 12, spreadRadius: -4)],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 19),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                vehiclesProvider.vehicleTypes.where((v) => v.id == activeBooking.vehicleTypeId).map((v) => v.name).firstWhere((name) => true, orElse: () => 'Vehicle'),
                                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE7F7EF),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF1C9A5B), shape: BoxShape.circle)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    activeBooking.status.toUpperCase(),
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1C9A5B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Booking: ${activeBooking.bookingId}',
                                          style: const TextStyle(fontSize: 11.5, fontFamily: 'IBM Plex Mono', color: Color(0xFF6C6F79)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (activeBooking.driver != null) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Color(0xFFE7E7EB)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 15, color: Color(0xFF6C6F79)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Driver: ${activeBooking.driver!.fullName} (${activeBooking.driver!.phone})',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF121214)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                    const SizedBox(width: 3),
                                    Text(
                                      activeBooking.driver!.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => showBookingDetailsBottomSheet(context, activeBooking),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: const BorderSide(color: Color(0xFFE7E7EB), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                        foregroundColor: const Color(0xFF121214),
                                        elevation: 0,
                                      ),
                                      child: const Text('View details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final vName = vehiclesProvider.vehicleTypes.where((v) => v.id == activeBooking.vehicleTypeId).map((v) => v.name).firstWhere((name) => true, orElse: () => 'Vehicle');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FindingDriverScreen(
                                              booking: activeBooking,
                                              vehicleName: vName,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        backgroundColor: const Color(0xFFE31C2E),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                        elevation: 0,
                                        shadowColor: const Color(0x8C7E22CE),
                                      ),
                                      child: const Text('Track', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  if (bookingProvider.bookings.isNotEmpty) ...[
                    (() {
                      final recentBookings = bookingProvider.bookings
                          .where((b) => b.status.toUpperCase() == 'DELIVERED' || b.status.toUpperCase() == 'COMPLETED')
                          .take(2)
                          .toList();

                      if (recentBookings.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'RECENT BOOKINGS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFFA2A5AE)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE7E7EB)),
                              boxShadow: const [BoxShadow(color: Color(0x0D121214), offset: Offset(0, 1), blurRadius: 2)],
                            ),
                            child: Column(
                              children: recentBookings.asMap().entries.map((entry) {
                                final index = entry.key;
                                final booking = entry.value;
                                final vehicleName = vehiclesProvider.vehicleTypes.where((v) => v.id == booking.vehicleTypeId).map((v) => v.name).firstWhere((name) => true, orElse: () => 'Vehicle');
                                
                                String dateStr = '';
                                try {
                                  if (booking.createdAt.isNotEmpty) {
                                    final dt = DateTime.parse(booking.createdAt).toLocal();
                                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                    dateStr = '${months[dt.month - 1]} ${dt.day}';
                                  }
                                } catch (_) {}

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDEBEC),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.history_rounded, color: Color(0xFFE31C2E), size: 19),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${booking.pickupAddressName.split(',').first} → ${booking.dropAddressName.split(',').first}',
                                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text('$dateStr · $vehicleName', style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79))),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('₹${booking.totalFare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'IBM Plex Mono', color: Color(0xFF121214))),
                                              const SizedBox(height: 6),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final route = {
                                                    'pickupAddress': {
                                                      'address': booking.pickupAddressName,
                                                      'latitude': booking.pickupLatitude,
                                                      'longitude': booking.pickupLongitude,
                                                    },
                                                    'dropAddress': {
                                                      'address': booking.dropAddressName,
                                                      'latitude': booking.dropLatitude,
                                                      'longitude': booking.dropLongitude,
                                                    }
                                                  };
                                                  _showNewBookingModal(route);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  backgroundColor: const Color(0xFFE31C2E),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  elevation: 0,
                                                ),
                                                child: const Text('Repeat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < recentBookings.length - 1) const Divider(color: Color(0xFFE7E7EB), height: 1, thickness: 1),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    })(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  }

  void _showNewBookingModal([Map<String, dynamic>? route]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingFlowBottomSheet(
        onBookingConfirmed: widget.onBookingConfirmed,
        initialRoute: route,
      ),
    );
  }
}


class _RoutePainter extends CustomPainter {
  final double animationValue;
  final double drawProgress;

  _RoutePainter({required this.animationValue, required this.drawProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawProgress <= 0.0) return;

    final paint = Paint()
      ..color = const Color(0xFFE31C2E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // The exact steep S-curve from the original HTML design: M60,70 Q 120,130 200,86 T 320,60
    path.moveTo(60, 70);
    path.quadraticBezierTo(120, 160, 200, 86);
    path.quadraticBezierTo(280, 12, 320, 60);

    final dashWidth = 6.0;
    final dashSpace = 8.0;
    final totalDashLength = dashWidth + dashSpace;
    final offset = animationValue * totalDashLength;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final length = metric.length;
    
    final limit = length * drawProgress;
    
    final dashedPath = Path();
    double distance = offset - totalDashLength; // move dashes forwards
    
    while (distance < limit) {
      if (distance + dashWidth > 0) {
        final start = distance < 0 ? 0.0 : distance;
        final end = (distance + dashWidth) > limit ? limit : distance + dashWidth;
        dashedPath.addPath(metric.extractPath(start, end), Offset.zero);
      }
      distance += dashWidth + dashSpace;
    }
    
    // Optional subtle drop shadow for the line
    final shadowPaint = Paint()
      ..color = const Color(0x4DE31C2E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(dashedPath, shadowPaint);
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.drawProgress != drawProgress;
  }
}
