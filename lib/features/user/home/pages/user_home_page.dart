import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
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
import 'package:riderzz_app/features/user/profile/screens/customer_profile_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/driver/profile/become_driver_screen.dart';
import 'package:riderzz_app/features/driver/profile/widgets/driver_terms_popup.dart';
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
  final Map<int, bool> _fastDeliveryAvailability = {};
  bool _isFastDeliveryLoading = false;
  bool _isRecentBookingsExpanded = true;

  String _formatBookingDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _checkFastDeliveryAvailability() async {
    if (mounted) {
      setState(() {
        _isFastDeliveryLoading = true;
      });
    }
    try {
      final vehiclesProvider = Provider.of<AdminVehiclesProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      if (vehiclesProvider.vehicleTypes.isEmpty) {
        await vehiclesProvider.fetchVehicleTypes();
      }

      final futures = vehiclesProvider.vehicleTypes.map((vehicle) async {
        try {
          final tier = await bookingProvider.getApplicablePricingTier(vehicle.id, 5.0);
          if (tier != null) {
            _fastDeliveryAvailability[vehicle.id] = tier.fastDeliveryEnabled;
          } else {
            _fastDeliveryAvailability[vehicle.id] = false;
          }
        } catch (e) {
          _fastDeliveryAvailability[vehicle.id] = false;
        }
      }).toList();

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error checking fast delivery availability: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFastDeliveryLoading = false;
        });
      }
    }
  }

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
      _checkFastDeliveryAvailability();
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
              PopupMenuButton<String>(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                    );
                  } else if (value == 'logout') {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        content: const Text('Are you sure you want to log out of your account?', style: TextStyle(fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCC2D3B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              context.read<DriverHomeProvider>().clearData();
                              final auth = context.read<AuthProvider>();
                              await auth.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: Color(0xFF121214), size: 20),
                        SizedBox(width: 12),
                        Text('My Profile', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFE31C2E), size: 20),
                        SizedBox(width: 12),
                        Text('Log Out', style: TextStyle(color: Color(0xFFE31C2E), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                child: Container(
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

          /*
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
                        if (val == 'create_route') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SavedRouteListScreen()),
                          );
                          return;
                        }
                        setState(() {
                          _selectedRoute = savedRouteProvider.savedRoutes.firstWhere(
                            (r) => (r['id']?.toString() ?? r['routeName']?.toString()) == val
                          );
                        });
                      },
                      itemBuilder: (context) {
                        if (savedRouteProvider.savedRoutes.isEmpty) {
                          return [
                            PopupMenuItem<String>(
                              value: 'create_route',
                              height: 38,
                              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add_rounded, color: Color(0xFFE31C2E), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create Route',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE31C2E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ];
                        }
                        return savedRouteProvider.savedRoutes.map((route) {
                          return PopupMenuItem<String>(
                            value: route['id']?.toString() ?? route['routeName']?.toString(),
                            height: 38,
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                                  _selectedRoute?['routeName']?.toString() ?? 'Saved routes',
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
              onTap: () => _showNewBookingModal(route: _selectedRoute),
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
          */

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
                      final cardWidget = Container(
                        margin: const EdgeInsets.only(bottom: 22, top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08121214),
                              offset: Offset(0, 8),
                              blurRadius: 24,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeBooking.bookingId,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (activeBooking.createdAt.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Placed: ${_formatBookingDate(activeBooking.createdAt)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C9A5B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1C9A5B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        activeBooking.status.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1C9A5B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 14),
                            // Pickup & Drop locations with labeled headers
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
                                          activeBooking.pickupAddressName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 1),
                              child: Text(
                                activeBooking.dropAddressName,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (activeBooking.driver != null) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          activeBooking.driver!.fullName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '(${activeBooking.driver!.phone})',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.5,
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                  const SizedBox(width: 3),
                                  Text(
                                    activeBooking.driver!.rating.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              if (activeBooking.vehicleNumber != null && activeBooking.vehicleNumber!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF475569)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Vehicle: ${activeBooking.vehicleNumber}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => showBookingDetailsBottomSheet(context, activeBooking),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                      foregroundColor: const Color(0xFF1E293B),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'View Details',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final vName = vehiclesProvider.vehicleTypes
                                          .where((v) => v.id == activeBooking.vehicleTypeId)
                                          .map((v) => v.name)
                                          .firstWhere((name) => true, orElse: () => 'Vehicle');
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
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      backgroundColor: const Color(0xFFC62E42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Track',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );

                      Widget childWidget = cardWidget;
                      if (activeBooking.fastDelivery) {
                        childWidget = Stack(
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

                      return GestureDetector(
                        onTap: () {
                          showBookingDetailsBottomSheet(context, activeBooking);
                        },
                        child: childWidget,
                      );
                    }).toList(),
                  ],

                  // Recent Bookings was moved below AVAILABLE VEHICLES
                  
                  // Vehicle Cards
                  const SizedBox(height: 22),
                  Text(
                    'AVAILABLE VEHICLES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFFA2A5AE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (vehiclesProvider.isLoading && vehiclesProvider.vehicleTypes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                        ),
                      ),
                    )
                  else if (vehiclesProvider.vehicleTypes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No vehicles available at the moment',
                          style: TextStyle(color: Color(0xFF6C6F79), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final sortedVehicles = List<VehicleTypeModel>.from(vehiclesProvider.vehicleTypes)
                          ..sort((a, b) {
                            final aFast = _fastDeliveryAvailability[a.id] == true;
                            final bFast = _fastDeliveryAvailability[b.id] == true;
                            if (aFast && !bFast) return -1;
                            if (!aFast && bFast) return 1;
                            return 0;
                          });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: sortedVehicles.length,
                              itemBuilder: (context, idx) {
                                final vehicle = sortedVehicles[idx];
                                final isFastAvailable = _fastDeliveryAvailability[vehicle.id] == true;
                                
                                return GestureDetector(
                                  onTap: () {
                                    if (isFastAvailable) {
                                      _showDeliveryOptionDialog(vehicle);
                                    } else {
                                      _showNewBookingModal(
                                        preSelectedVehicleTypeId: vehicle.id,
                                        preSelectedFastDelivery: false,
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE7E7EB)),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x08121214),
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned.fill(
                                          child: isFastAvailable
                                              ? ShiningContainer(
                                                  isSelected: false,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        const Spacer(),
                                                        Container(
                                                          width: 44,
                                                          height: 44,
                                                          alignment: Alignment.center,
                                                          child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                                                              ? Image.network(
                                                                  vehicle.iconUrl!,
                                                                  width: 40,
                                                                  height: 40,
                                                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                                                    Icons.local_shipping_rounded,
                                                                    size: 36,
                                                                    color: Color(0xFFE31C2E),
                                                                  ),
                                                                )
                                                              : const Icon(Icons.local_shipping_rounded, size: 36, color: Color(0xFFE31C2E)),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          vehicle.name,
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFF121214),
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      const Spacer(),
                                                      Container(
                                                        width: 44,
                                                        height: 44,
                                                        alignment: Alignment.center,
                                                        child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                                                            ? Image.network(
                                                                vehicle.iconUrl!,
                                                                width: 40,
                                                                height: 40,
                                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                                  Icons.local_shipping_rounded,
                                                                  size: 36,
                                                                  color: Color(0xFFE31C2E),
                                                                ),
                                                              )
                                                            : const Icon(Icons.local_shipping_rounded, size: 36, color: Color(0xFFE31C2E)),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        vehicle.name,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF121214),
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const Spacer(),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                        if (isFastAvailable)
                                          const Positioned(
                                            top: -8,
                                            right: 16,
                                            child: _FastDeliveryTickerBadge(),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Recent Bookings Section (moved below AVAILABLE VEHICLES)
                            _buildRecentBookingsDropdown(bookingProvider, vehiclesProvider),
                            // What's New News Section
                            const SizedBox(height: 28),
                            Text(
                              "WHAT'S NEW",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: const Color(0xFFA2A5AE),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 110,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // Card 1: Become a Partner Promotion
                                  GestureDetector(
                                    onTap: () {
                                      showDriverTermsAndConditionsPopup(context, () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
                                        );
                                      });
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      margin: const EdgeInsets.only(right: 14),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFDF2F4), Color(0xFFFCE7EB)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFC62E42).withOpacity(0.2), width: 1.2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x04C62E42),
                                            offset: Offset(0, 4),
                                            blurRadius: 12,
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Become a Partner',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF881337),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Register as a driver and start earning on your own schedule.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF9F1239),
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFC62E42).withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: const Icon(Icons.stars_rounded, color: Color(0xFFC62E42), size: 24),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Card 2: Fast Delivery Promotion
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade50,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 22),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Fast Delivery Mode',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF1E293B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Experience ultra-fast deliveries with our new Fast Delivery option! When enabled, your bookings are prioritized by nearby drivers for lightning-quick pickups.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    color: const Color(0xFF475569),
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFE31C2E),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    elevation: 0,
                                                  ),
                                                  child: Text(
                                                    'Got it',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      margin: const EdgeInsets.only(right: 14),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFFF7ED), Color(0xFFFFF2E2)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x04D97706),
                                            offset: Offset(0, 4),
                                            blurRadius: 12,
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Introducing Fast Delivery',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF7C2D12),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Get your parcels priority-matched and delivered at lightning speed.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF9A3412),
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 24),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  }

  void _showDeliveryOptionDialog(VehicleTypeModel vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Delivery Speed',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121214),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select delivery type for your ${vehicle.name}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6C6F79),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Normal Delivery Option Card
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showNewBookingModal(
                    preSelectedVehicleTypeId: vehicle.id,
                    preSelectedFastDelivery: false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                            ? Image.network(
                                vehicle.iconUrl!,
                                width: 26,
                                height: 26,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 22),
                              )
                            : const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Normal Delivery',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Standard delivery at regular rates',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF6C6F79),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFA2A5AE)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Fast Delivery Option Card
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showNewBookingModal(
                    preSelectedVehicleTypeId: vehicle.id,
                    preSelectedFastDelivery: true,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF2DC),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                            ? Image.network(
                                vehicle.iconUrl!,
                                width: 26,
                                height: 26,
                                color: Colors.orange.shade700,
                                colorBlendMode: BlendMode.srcIn,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 22),
                              )
                            : const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '⚡ Fast Delivery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD35400),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'RECOMMENDED',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Priority dispatch & faster route delivery',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFFE67E22),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewBookingModal({
    Map<String, dynamic>? route,
    int? preSelectedVehicleTypeId,
    bool? preSelectedFastDelivery,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingFlowBottomSheet(
        onBookingConfirmed: widget.onBookingConfirmed,
        initialRoute: route,
        preSelectedVehicleTypeId: preSelectedVehicleTypeId,
        preSelectedFastDelivery: preSelectedFastDelivery,
      ),
    );
  }

  Widget _buildRecentBookingsDropdown(
    BookingProvider bookingProvider,
    AdminVehiclesProvider vehiclesProvider,
  ) {
    if (bookingProvider.bookings.isEmpty) return const SizedBox.shrink();

    final recentBookings = bookingProvider.bookings
        .where((b) =>
            b.status.toUpperCase() == 'DELIVERED' ||
            b.status.toUpperCase() == 'COMPLETED')
        .take(2)
        .toList();

    if (recentBookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        InkWell(
          onTap: () {
            setState(() {
              _isRecentBookingsExpanded = !_isRecentBookingsExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'RECENT BOOKINGS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: const Color(0xFFA2A5AE),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE7E7EB),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isRecentBookingsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFA2A5AE),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D121214),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                )
              ],
            ),
            child: Column(
              children: recentBookings.asMap().entries.map((entry) {
                final index = entry.key;
                final booking = entry.value;
                final vehicleName = vehiclesProvider.vehicleTypes
                    .where((v) => v.id == booking.vehicleTypeId)
                    .map((v) => v.name)
                    .firstWhere((name) => true, orElse: () => 'Vehicle');

                String dateStr = '';
                try {
                  if (booking.createdAt.isNotEmpty) {
                    final dt = DateTime.parse(booking.createdAt).toLocal();
                    const months = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                    ];
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
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFFE31C2E),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.pickupAddressName.split(',').first} → ${booking.dropAddressName.split(',').first}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF121214),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateStr · $vehicleName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C6F79),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${booking.totalFare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'IBM Plex Mono',
                                  color: Color(0xFF121214),
                                ),
                              ),
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
                                  _showNewBookingModal(route: route);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFE31C2E),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Repeat',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (index < recentBookings.length - 1)
                      const Divider(
                          color: Color(0xFFE7E7EB), height: 1, thickness: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isRecentBookingsExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
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

class _FastDeliveryTickerBadge extends StatefulWidget {
  const _FastDeliveryTickerBadge({super.key});

  @override
  State<_FastDeliveryTickerBadge> createState() => _FastDeliveryTickerBadgeState();
}

class _FastDeliveryTickerBadgeState extends State<_FastDeliveryTickerBadge> {
  Timer? _timer;
  bool _showAvailable = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _showAvailable = !_showAvailable;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 12),
          const SizedBox(width: 3),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showAvailable ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Text(
              'FAST Available',
              style: GoogleFonts.outfit(
                color: Colors.orange.shade700,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            secondChild: Text(
              'FAST Delivery',
              style: GoogleFonts.outfit(
                color: Colors.orange.shade700,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShiningContainer extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const ShiningContainer({
    super.key,
    required this.child,
    required this.isSelected,
  });

  @override
  State<ShiningContainer> createState() => _ShiningContainerState();
}

class _ShiningContainerState extends State<ShiningContainer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.transparent,
                Colors.white10,
                Colors.white54,
                Colors.white10,
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.45, 0.5, 0.55, 0.65, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}
