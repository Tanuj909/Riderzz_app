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
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/widgets/booking_details_bottom_sheet.dart';
import 'package:riderzz_app/features/user/profile/screens/customer_profile_screen.dart';
import 'package:riderzz_app/features/user/wallet/screens/customer_wallet_screen.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';
import 'package:riderzz_app/features/user/coupons/providers/customer_coupon_provider.dart';
import 'package:riderzz_app/features/user/coupons/screens/customer_coupons_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/models/driver_registration_check_model.dart';
import 'package:riderzz_app/features/driver/profile/become_driver_screen.dart';
import 'package:riderzz_app/features/driver/profile/widgets/driver_terms_popup.dart';
import 'package:riderzz_app/core/services/broadcast_socket_service.dart';
import 'package:riderzz_app/features/notification/data/models/notification_model.dart';
import 'package:riderzz_app/core/services/shared_location_service.dart';
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

  StreamSubscription<NotificationModel>? _notificationSubscription;
  StreamSubscription<LatLngCoordinates>? _sharedLocationSubscription;
  bool _isFetchingFromWebSocket = false;
  bool _isLocationPickerActive = false;

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



  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12600),
    )..repeat();

    _sharedLocationSubscription =
        SharedLocationService.instance.onLocationStream.listen(_handleIncomingSharedLocation);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<BookingProvider>(context, listen: false).fetchCurrentBookings();
      Provider.of<DriverHomeProvider>(context, listen: false).checkRegistrationStatus();
      Provider.of<CustomerWalletProvider>(context, listen: false).fetchCustomerWallet();
      Provider.of<CustomerCouponProvider>(context, listen: false).fetchCoupons();
      final initialCoords = await SharedLocationService.instance.consumeInitialLocation();
      if (initialCoords != null && mounted) {
        _handleIncomingSharedLocation(initialCoords);
      }
    });

    final socketService = context.read<BroadcastSocketService>();
    socketService.connect();
    _notificationSubscription = socketService.notifications.listen((notification) async {
      if (notification.type == 'BOOKING_STATUS_UPDATED') {
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (isCurrent && !_isFetchingFromWebSocket) {
          _isFetchingFromWebSocket = true;
          try {
            if (mounted) {
              await context.read<BookingProvider>().fetchCurrentBookings();
              
              if (mounted && notification.bookingId != null) {
                final freshBooking = await context.read<BookingProvider>().fetchBookingById(notification.bookingId!);
                if (freshBooking != null) {
                  final statusUpper = freshBooking.status.toUpperCase();
                  if (statusUpper == 'DELIVERED' || statusUpper == 'COMPLETED') {
                    _showRatingDialog(freshBooking);
                  } else if (statusUpper == 'CANCELLED') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking has been cancelled.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            }
          } finally {
            _isFetchingFromWebSocket = false;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _sharedLocationSubscription?.cancel();
    _notificationSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }
  void _showRatingDialog(BookingModel completedBooking) {
    int selectedStars = 5;
    final reviewController = TextEditingController();
    bool isSubmitting = false;
    final bookingProvider = context.read<BookingProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB000),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Rate Your Ride',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF121214),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'How was your delivery partner ${completedBooking.driver?.fullName ?? "Driver"}?',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6C6F79),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Star Rating selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          final isSelected = starValue <= selectedStars;
                          return GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      selectedStars = starValue;
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: isSelected
                                    ? const Color(0xFFFFB000)
                                    : const Color(0xFFE2E8F0),
                                size: 38,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Review Comment box
                      TextField(
                        controller: reviewController,
                        maxLines: 3,
                        enabled: !isSubmitting,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF121214),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your feedback (optional)...',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFA2A5AE),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE31C2E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action buttons
                      Row(
                        children: [
                          // Close option
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6C6F79),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Submit option
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isSubmitting = true;
                                      });

                                      final success = await bookingProvider
                                          .submitRating(
                                            bookingId: completedBooking.id,
                                            ratingType: 'CUSTOMER_TO_DRIVER',
                                            stars: selectedStars,
                                            review:
                                                reviewController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? reviewController.text.trim()
                                                : 'Ride was smooth.',
                                          );

                                      if (success) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Rating submitted successfully',
                                            ),
                                          ),
                                        );
                                        Navigator.pop(dialogContext);
                                      } else {
                                        setDialogState(() {
                                          isSubmitting = false;
                                        });
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              bookingProvider.errorMessage ??
                                                  'Failed to submit rating',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Submit',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    final customerProfile = authProvider.customerProfile;
    final profileImage = customerProfile?.profileImage ?? user?.profileImage;
    final displayName = (customerProfile?.fullName != null && customerProfile!.fullName.trim().isNotEmpty)
        ? customerProfile.fullName.trim()
        : (user?.name != null && user!.name!.trim().isNotEmpty ? user.name!.trim() : '');

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          Provider.of<BookingProvider>(context, listen: false).fetchCurrentBookings(),
          Provider.of<DriverHomeProvider>(context, listen: false).checkRegistrationStatus(force: true),
          Provider.of<CustomerWalletProvider>(context, listen: false).fetchCustomerWallet(force: true),
          Provider.of<CustomerCouponProvider>(context, listen: false).fetchCoupons(force: true),
        ]);
      },
      color: const Color(0xFFE31C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Wallet Pill (Icon + Amount)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerWalletScreen()),
                  ).then((_) {
                    if (mounted) {
                      context.read<CustomerWalletProvider>().fetchCustomerWallet(force: true);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFEBEBEF), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/wallet_icon/wallet.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Consumer<CustomerWalletProvider>(
                        builder: (context, walletProvider, _) {
                          final balance = walletProvider.wallet?.balance ?? 0.0;
                          final formatted = balance.truncateToDouble() == balance
                              ? balance.toInt().toString()
                              : balance.toStringAsFixed(2);
                          return Text(
                            '₹$formatted',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121214),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Right Actions: Coupon Button + Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coupon Button with available count
                  Consumer<CustomerCouponProvider>(
                    builder: (context, couponProvider, _) {
                      final count = couponProvider.availableCouponsCount;
                      return GestureDetector(
                        onTap: () {
                          showCustomerCouponsBottomSheet(context).then((_) {
                            if (mounted) {
                              context.read<CustomerCouponProvider>().fetchCoupons(force: true);
                              context.read<CustomerWalletProvider>().fetchCustomerWallet(force: true);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFEBEBEF), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/coupon.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Coupons',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: count > 0 ? const Color(0xFFC62E42) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: count > 0 ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),

                  // Profile Button
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
                                  final navigator = Navigator.of(context, rootNavigator: true);
                                  Navigator.pop(dialogContext);
                                  context.read<DriverHomeProvider>().clearData();
                                  final auth = context.read<AuthProvider>();
                                  await auth.logout();
                                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE31C2E), Color(0xFFA31E30)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        image: (profileImage != null && profileImage.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(profileImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31C2E).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: (profileImage == null || profileImage.isEmpty)
                          ? Text(
                              _getInitials(displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Map Hero or Driver Application Status Card
          Consumer<DriverHomeProvider>(
            builder: (context, driverProvider, child) {
              final registrationCheck = driverProvider.registrationCheck;
              if (registrationCheck != null &&
                  registrationCheck.formSubmitted &&
                  registrationCheck.status != null &&
                  registrationCheck.status != 'SUSPENDED') {
                return _buildDriverStatusHero(context, registrationCheck);
              }
              return _buildMapHero();
            },
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
                                      final vName = (activeBooking.vehicleNumber != null && activeBooking.vehicleNumber!.isNotEmpty)
                                          ? activeBooking.vehicleNumber!
                                          : 'Vehicle';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FindingDriverScreen(
                                            booking: activeBooking,
                                            vehicleName: vName,
                                          ),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          context.read<BookingProvider>().fetchCurrentBookings();
                                        }
                                      });
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

                  // Vehicle Category Cards
                  const SizedBox(height: 22),
                  Text(
                    'VEHICLE CATEGORIES',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFFA2A5AE),
                    ),
                  ),
                  const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.34,
                      ),
                      itemCount: _kVehicleCategories.length,
                      itemBuilder: (context, idx) {
                        final cat = _kVehicleCategories[idx];
                        return GestureDetector(
                          onTap: () => _showCategoryVehiclesBottomSheet(cat),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE7E7EB)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08121214),
                                  offset: Offset(0, 3),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 72,
                                    width: 72,
                                    child: Image.asset(
                                      cat.assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.local_shipping_rounded,
                                        size: 48,
                                        color: Color(0xFFE31C2E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF121214),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                            // What's New News Section
                            const SizedBox(height: 18),
                            Text(
                              "WHAT'S NEW",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: const Color(0xFFA2A5AE),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 78,
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
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFDF2F4), Color(0xFFFCE7EB)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
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
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF881337),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Register as a driver and start earning on your own schedule.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF9F1239),
                                                    height: 1.25,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFC62E42).withOpacity(0.12),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/icons/business_partner.png',
                                              fit: BoxFit.contain,
                                            ),
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
                                                      width: 38,
                                                      height: 38,
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade50,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Image.asset(
                                                        'assets/icons/fast_delivery.png',
                                                        fit: BoxFit.contain,
                                                      ),
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
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _showNewBookingModal(preSelectedFastDelivery: true);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFE31C2E),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(100),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    elevation: 0,
                                                  ),
                                                  child: Text(
                                                    'Book Now',
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
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFFF7ED), Color(0xFFFFF2E2)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
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
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF7C2D12),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Get your parcels priority-matched and delivered at lightning speed.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF9A3412),
                                                    height: 1.25,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/icons/fast_delivery.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Normal Delivery',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Standard delivery at regular rates',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF6C6F79),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFA2A5AE)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.orange.shade300, width: 1.5),
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '⚡ Fast Delivery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD35400),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'REC',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Priority dispatch & faster route delivery',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFFE67E22),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  void _showCategoryVehiclesBottomSheet(_VehicleCategoryItem category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return _CategoryVehiclesSheetContent(
          category: category,
          onVehicleSelected: (vehicle) {
            Navigator.pop(sheetCtx);
            if (vehicle.isFastDelivery == true) {
              _showDeliveryOptionDialog(vehicle);
            } else {
              _showNewBookingModal(
                preSelectedVehicleTypeId: vehicle.id,
                preSelectedFastDelivery: false,
              );
            }
          },
        );
      },
    );
  }

  Future<void> _handleIncomingSharedLocation(LatLngCoordinates coords) async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.role != 'CUSTOMER') {
      debugPrint('[UserHomePage] Ignored shared location: user role is not CUSTOMER.');
      SharedLocationService.instance.clearPendingLocation();
      return;
    }

    SharedLocationService.instance.clearPendingLocation();

    if (_isLocationPickerActive) return;
    _isLocationPickerActive = true;

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLatitude: coords.latitude,
            initialLongitude: coords.longitude,
            showSaveOption: true,
          ),
        ),
      );

      if (result != null && mounted) {
        final target = await _showChooseLocationAsSheet(result);
        if (target != null && mounted) {
          final addressText = result['address'] ?? result['addressLine1'] ?? '';
          final lat = result['latitude'];
          final lng = result['longitude'];
          final contactName = result['contactPersonName'];
          final contactPhone = result['contactPersonPhone'];

          Map<String, dynamic> route;
          if (target == 'PICKUP') {
            route = {
              'pickupAddress': {
                'address': addressText,
                'latitude': lat,
                'longitude': lng,
                if (contactName != null && contactName.toString().isNotEmpty) 'contactPersonName': contactName,
                if (contactPhone != null && contactPhone.toString().isNotEmpty) 'contactPersonPhone': contactPhone,
              },
            };
          } else {
            route = {
              'dropAddress': {
                'address': addressText,
                'latitude': lat,
                'longitude': lng,
                if (contactName != null && contactName.toString().isNotEmpty) 'contactPersonName': contactName,
                if (contactPhone != null && contactPhone.toString().isNotEmpty) 'contactPersonPhone': contactPhone,
              },
            };
          }

          _showNewBookingModal(route: route);
        }
      }
    } finally {
      _isLocationPickerActive = false;
    }
  }

  Future<String?> _showChooseLocationAsSheet(Map<String, dynamic> locationData) {
    final address = (locationData['address'] ?? locationData['addressLine1'] ?? 'Selected Location').toString();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose Location as',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF121214),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6C6F79),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.pop(sheetCtx, 'PICKUP'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trip_origin_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Set this location where driver will collect the goods',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF6C6F79),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF6C6F79),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.pop(sheetCtx, 'DROP'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEBEC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE31C2E).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31C2E).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Color(0xFFE31C2E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Drop Location',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Set this location where driver will deliver the goods',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF6C6F79),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFE31C2E),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverStatusHero(BuildContext context, DriverRegistrationCheckModel check) {
    final status = check.status?.toUpperCase() ?? 'PENDING';

    final bool isApproved = status == 'APPROVED';
    final bool isRejected = status == 'REJECTED';

    final Color badgeColor = isApproved
        ? const Color(0xFF22C55E)
        : (isRejected ? const Color(0xFFEF4444) : const Color(0xFFE31C2E));

    final String badgeText = isApproved
        ? 'Approved'
        : (isRejected ? 'Rejected' : 'Pending');

    final String subtitleText = isApproved
        ? 'Your registration is approved. You can now switch to Driver Mode.'
        : (isRejected
            ? 'Your application was rejected. Please review details and re-apply.'
            : 'Your registration form and documents are being verified by our team.');

    final String buttonText = isApproved
        ? 'Switch to Driver Mode!'
        : (isRejected ? 'Review Details & Re-apply' : 'View Application Details');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF101014)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF27272A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Application Status Title + Status Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Application Status',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isApproved && !isRejected) ...[
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Icon(
                        isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: badgeColor,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      badgeText,
                      style: GoogleFonts.outfit(
                        color: badgeColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Subtitle (multi-line supported)
          Text(
            subtitleText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFD4D4D8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.38,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Bottom Action Button
          GestureDetector(
            onTap: () async {
              if (isApproved) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.updateUserRole('ROLE_DRIVER');
                if (success && context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/role_redirect', (route) => false);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Failed to switch to Driver Mode.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFE31C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isApproved
                        ? const Color(0xFFE31C2E).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      color: isApproved ? Colors.white : const Color(0xFF121214),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.white : const Color(0xFFE31C2E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isApproved ? const Color(0xFFE31C2E) : Colors.white,
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapHero() {
    return GestureDetector(
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
                      cameraX = 60;
                      cameraY = 70;
                      cameraScale = 1.6;
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
                        cameraY = (pow(1 - rt, 2) * 70 +
                                2 * (1 - rt) * rt * 130 +
                                pow(rt, 2) * 86)
                            .toDouble();
                      } else {
                        final rt = (easeProgress - 0.5) * 2;
                        cameraY = (pow(1 - rt, 2) * 86 +
                                2 * (1 - rt) * rt * 42 +
                                pow(rt, 2) * 60)
                            .toDouble();
                      }
                      cameraScale = 1.6;
                    } else if (T < 6100) {
                      drawProgress = 1.0;
                      cameraX = 320;
                      cameraY = 60;
                      cameraScale = 1.6;
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
                      cameraX = 190.0;
                      cameraY = 65.0;
                      cameraScale = 1.0;
                    }

                    final routeFlowValue =
                        drawProgress >= 1.0 ? ((T % 1000) / 1000) : 0.0;

                    final centerX = constraints.maxWidth / 2;
                    final centerY = (constraints.maxHeight / 2) - 10;
                    final transform = Matrix4.identity()
                      ..translate(
                          centerX - cameraX * cameraScale, centerY - cameraY * cameraScale)
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
                            left: 60 - 24,
                            top: 70 - 38,
                            child: Transform.scale(
                              scale: pickupReveal,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                        top: 31,
                                        child: Transform.scale(
                                            scale: pulseScale,
                                            child: Opacity(
                                                opacity: pulseOpacity,
                                                child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: const BoxDecoration(
                                                        color: Color(0xFF121214),
                                                        shape: BoxShape.circle))))),
                                    const Positioned(
                                        top: 10,
                                        child: Icon(Icons.location_on,
                                            color: Color(0xFF121214), size: 28)),
                                    Positioned(
                                        bottom: 42,
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF121214),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Color(0x26000000),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4))
                                                ]),
                                            child: const Text('Pickup',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Drop Marker
                          Positioned(
                            left: 320 - 24,
                            top: 60 - 38,
                            child: Transform.scale(
                              scale: dropReveal,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                        top: 31,
                                        child: Transform.scale(
                                            scale: pulseScale,
                                            child: Opacity(
                                                opacity: pulseOpacity,
                                                child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: const BoxDecoration(
                                                        color: Color(0xFFE31C2E),
                                                        shape: BoxShape.circle))))),
                                    const Positioned(
                                        top: 10,
                                        child: Icon(Icons.location_on,
                                            color: Color(0xFFE31C2E), size: 28)),
                                    Positioned(
                                        bottom: 42,
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFE31C2E),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Color(0x26000000),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4))
                                                ]),
                                            child: const Text('Drop',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)))),
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
              },
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
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _VehicleCategoryItem {
  final String key;
  final String title;
  final String subtitle;
  final String assetPath;

  const _VehicleCategoryItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

const List<_VehicleCategoryItem> _kVehicleCategories = [
  _VehicleCategoryItem(
    key: 'TWO_WHEELER',
    title: '2 Wheeler',
    subtitle: 'Bike & Scooter',
    assetPath: 'assets/category/two_wheeler.png',
  ),
  _VehicleCategoryItem(
    key: 'THREE_WHEELER',
    title: '3 Wheeler',
    subtitle: 'Auto & 3-Wheeler',
    assetPath: 'assets/category/three_wheeler.png',
  ),
  _VehicleCategoryItem(
    key: 'FOUR_WHEELER',
    title: '4 Wheeler',
    subtitle: 'Cab & Mini Van',
    assetPath: 'assets/category/four_wheeler.png',
  ),
  _VehicleCategoryItem(
    key: 'TRUCK',
    title: 'Truck',
    subtitle: 'Mini & Heavy Truck',
    assetPath: 'assets/category/truck.png',
  ),
];

class _CategoryVehiclesSheetContent extends StatefulWidget {
  final _VehicleCategoryItem category;
  final Function(VehicleTypeModel) onVehicleSelected;

  const _CategoryVehiclesSheetContent({
    required this.category,
    required this.onVehicleSelected,
  });

  @override
  State<_CategoryVehiclesSheetContent> createState() => _CategoryVehiclesSheetContentState();
}

class _CategoryVehiclesSheetContentState extends State<_CategoryVehiclesSheetContent> {
  bool _isLoading = true;
  String? _errorMessage;
  List<VehicleTypeModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    final cached = Provider.of<AdminVehiclesProvider>(context, listen: false)
        .categoryVehiclesCache[widget.category.key];
    if (cached != null && cached.isNotEmpty) {
      _vehicles = cached;
      _isLoading = false;
      // Refresh in background silently
      _fetchCategoryVehicles(silent: true);
    } else {
      _isLoading = true;
      _fetchCategoryVehicles(silent: false);
    }
  }

  Future<void> _fetchCategoryVehicles({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final vehicles = await Provider.of<AdminVehiclesProvider>(context, listen: false)
          .fetchVehiclesByCategory(widget.category.key);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.75;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top pill indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header Row
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EB)),
                  ),
                  child: Image.asset(
                    widget.category.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFFE31C2E),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF121214),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a vehicle to proceed with booking',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6C6F79),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79), size: 22),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEEEF2)),
            const SizedBox(height: 12),

            // Dynamic Content
            Flexible(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.separated(
      key: const ValueKey('loading_skeleton'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return ShiningContainer(
          isSelected: false,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 160,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error_view'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFE31C2E), size: 36),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6C6F79)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _fetchCategoryVehicles(silent: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31C2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        key: const ValueKey('empty_view'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_crash_outlined, size: 32, color: Color(0xFFA2A5AE)),
              ),
              const SizedBox(height: 12),
              Text(
                'No Vehicles Available',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121214),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'There are currently no active vehicles in this category.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF6C6F79),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('vehicles_list'),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _vehicles.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final isFast = vehicle.isFastDelivery == true;

        final cardChild = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFast ? const Color(0xFFFFFDF8) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isFast ? Colors.orange.shade200 : const Color(0xFFE7E7EB),
              width: isFast ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06121214),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEF2)),
                ),
                child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                    ? Image.network(
                        vehicle.iconUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.local_shipping_rounded,
                          size: 30,
                          color: Color(0xFFE31C2E),
                        ),
                      )
                    : const Icon(
                        Icons.local_shipping_rounded,
                        size: 30,
                        color: Color(0xFFE31C2E),
                      ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicle.name,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF121214),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFast) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 10, color: Colors.orange),
                                const SizedBox(width: 2),
                                Text(
                                  'Fast Delivery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Max Capacity: ${vehicle.maxWeightKg} kg',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6C6F79),
                      ),
                    ),
                  ],
                ),
              ),

              // Select button / Arrow
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF6C6F79),
                ),
              ),
            ],
          ),
        );

        return GestureDetector(
          onTap: () => widget.onVehicleSelected(vehicle),
          child: isFast
              ? ShiningContainer(
                  isSelected: false,
                  child: cardChild,
                )
              : cardChild,
        );
      },
    );
  }
}
