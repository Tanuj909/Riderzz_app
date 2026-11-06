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
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
import 'package:riderzz_app/features/user/coupons/providers/customer_coupon_provider.dart';
import 'package:riderzz_app/features/user/coupons/widgets/customer_coupons_bottom_sheet.dart';
import 'package:riderzz_app/features/driver/home/widgets/timed_swipe_to_accept_button.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  Timer? _searchTimer;
  bool _isManualSearching = false;
  int _searchCountdown = 30;
  bool _isContactDropdownExpanded = false;
  bool _isVerifyingOtp = false;
  String? _selectedPaymentMethod;
  final Map<int, DateTime> _bookingArrivalTimes = {};

  void _showLowBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEBEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFE31C2E),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wallet Balance is Low',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF121214),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your current wallet balance is below the minimum required amount to accept bookings. Please recharge to continue.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6C6F79),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62E42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      final homeState = context.findAncestorStateOfType<DriverHomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(2);
                      }
                    },
                    child: Text(
                      'Go to Wallet',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showGoOfflineDialog(BuildContext context) {
    bool isGoingOffline = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE8EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: Color(0xFFD90429),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Go Offline?',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121214),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Are you sure you want to go offline? You will stop receiving ride bookings.',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Line 1: Red Swipe Slider to Go Offline
                  _GoOfflineSlider(
                    isLoading: isGoingOffline,
                    onSwipeComplete: () async {
                      setDialogState(() {
                        isGoingOffline = true;
                      });
                      if (context.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                      return true;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Line 2: Stay Online button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        foregroundColor: const Color(0xFF64748B),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(
                        'Stay Online',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
      context.read<DriverHomeProvider>().fetchDriverWallet();
      context.read<CustomerCouponProvider>().fetchCoupons();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Widget _buildContactRow({
    required String role,
    required String name,
    required String phone,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA2A5AE),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF121214),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  phone,
                  style: GoogleFonts.ibmPlexMono(
                    color: const Color(0xFF6C6F79),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (phone.isNotEmpty)
          IconButton(
            onPressed: () async {
              final Uri url = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(
              Icons.phone_rounded,
              color: Color(0xFF1C9A5B),
              size: 18,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1C9A5B).withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          )
        else
          const Icon(
            Icons.phone_disabled_rounded,
            color: Colors.grey,
            size: 18,
          ),
      ],
    );
  }

  String _getSliderText(String status) {
    switch (status.toUpperCase()) {
      case 'DRIVER_ASSIGNED':
        return 'Swipe: Arrived at Pickup';
      case 'OTP_VERIFIED':
        return 'Swipe: Pick Up Goods';
      case 'GOODS_PICKED_UP':
        return 'Swipe: Start Ride';
      case 'IN_TRANSIT':
        return 'Swipe: Arrived at Drop';
      case 'DRIVER_ARRIVED_DROP':
        return 'Swipe: Complete Delivery';
      default:
        return 'Swipe to Proceed';
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'DRIVER_ASSIGNED':
        return 'DRIVER_ARRIVED';
      case 'OTP_VERIFIED':
        return 'GOODS_PICKED_UP';
      case 'GOODS_PICKED_UP':
        return 'IN_TRANSIT';
      case 'IN_TRANSIT':
        return 'DRIVER_ARRIVED_DROP';
      case 'DRIVER_ARRIVED_DROP':
        return 'DELIVERED';
      default:
        return 'DELIVERED';
    }
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
          await driverProvider.fetchDriverWallet(force: true);
          await locationProvider.initialize();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header row: Wallet Balance (Left), Online/Offline Toggle with embedded text (Middle), Coupon + Profile Avatar (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Wallet Balance (Far Left Corner)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverWalletPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: Color(0xFFCC2D3B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Consumer<DriverHomeProvider>(
                        builder: (context, provider, _) {
                          final balance = provider.wallet?.balance ?? 0.0;
                          final formatted = balance.truncateToDouble() == balance
                              ? balance.toInt().toString()
                              : balance.toStringAsFixed(2);
                          return Text(
                            '₹$formatted',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
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

              // 2. Online / Offline Toggle (Middle, text embedded inside toggle button)
              GestureDetector(
                onTap: () async {
                  if (isOnline) {
                    final bool? confirm = await _showGoOfflineDialog(context);
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
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 96,
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? const Color(0xFF16A34A) : const Color(0xFF475569)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Text inside the toggle: ONLINE or OFFLINE
                      Align(
                        alignment: isOnline ? const Alignment(-0.65, 0.0) : const Alignment(0.65, 0.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isOnline ? 'ONLINE' : 'OFFLINE',
                            key: ValueKey<bool>(isOnline),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                      // Sliding circular knob
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Right: Coupons Button + Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coupon Button (with available count badge)
                  Consumer<CustomerCouponProvider>(
                    builder: (context, couponProvider, _) {
                      final count = couponProvider.availableCoupons.length;
                      return GestureDetector(
                        onTap: () {
                          couponProvider.fetchCoupons(force: true);
                          showCustomerCouponsBottomSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 18,
                                  color: Color(0xFFE31C2E),
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC62E42),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Profile Avatar Button
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
                      width: 38,
                      height: 38,
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
                          fontSize: 13,
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
            child: Column(
              children: [
                Row(
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
                if (driverProvider.isWalletNotCreated) ...[
                  const Divider(color: Color(0xFFE1E1E6), height: 24, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        final homeState = context.findAncestorStateOfType<DriverHomeScreenState>();
                        if (homeState != null) {
                          homeState.setIndex(2);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF5F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFFE31C2E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activate your wallet and earn ₹50 bonus!',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFE31C2E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Click here to claim your exclusive sign-in reward.',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6C6F79),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFE31C2E),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (driverProvider.profile != null &&
              (driverProvider.profile!.upiId == null ||
                  driverProvider.profile!.upiId!.trim().isEmpty)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFEAD2)),
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
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEAD2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE2A03F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI ID Not Set',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Configure UPI ID to receive payments directly using QR Code.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => UpdateDriverProfileDialog(
                          profile: driverProvider.profile!,
                        ),
                      ).then((updated) {
                        if (!context.mounted) return;
                        if (updated == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile details updated successfully!'),
                              backgroundColor: Color(0xFF1C9A5B),
                            ),
                          );
                          context.read<DriverHomeProvider>().fetchDriverProfile();
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE2A03F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (itemCtx, index) {
                  final booking = driverProvider.pendingBookings[index];
                  final firstSeen = _bookingArrivalTimes.putIfAbsent(
                    booking.id,
                    () => DateTime.now(),
                  );
                  return _PendingBookingCard(
                    key: ValueKey('pending_card_${booking.id}'),
                    booking: booking,
                    firstSeenTime: firstSeen,
                    onGoToWallet: () {
                      final homeState = this.context.findAncestorStateOfType<DriverHomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(2);
                      }
                    },
                    onAccept: () async {
                      final messenger = ScaffoldMessenger.of(this.context);
                      final driverProvider = this.context.read<DriverHomeProvider>();
                      final success = await driverProvider.acceptBookingForDriver(booking.id);
                      _bookingArrivalTimes.remove(booking.id);

                      if (success) {
                        if (mounted) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Booking accepted successfully!'),
                              backgroundColor: Color(0xFF1C9A5B),
                            ),
                          );
                        }
                        return true;
                      } else {
                        final errorMsg = driverProvider.bookingsError?.trim() ?? '';
                        final isLowBalance = errorMsg.toLowerCase().contains('wallet') ||
                            errorMsg.toLowerCase().contains('balance') ||
                            errorMsg.toLowerCase().contains('insufficient');
                        if (isLowBalance) {
                          if (mounted) {
                            _showLowBalanceDialog(this.context);
                          }
                        } else {
                          final displayMsg = errorMsg.isNotEmpty
                              ? errorMsg
                              : 'Booking is no longer available';
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                displayMsg,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(
                                seconds: 4,
                              ),
                            ),
                          );
                          await driverProvider.fetchHomeBookings();
                        }
                        return false;
                      }
                    },
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
            // Active Ride Card wrapped in Stack to place the Fast Booking badge on top right border
            Stack(
              clipBehavior: Clip.none,
              children: [
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${driverProvider.activeBooking!.totalFare.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF121214),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (driverProvider.activeBooking!.fastDelivery &&
                                  driverProvider.activeBooking!.fastDeliveryCharge != null &&
                                  driverProvider.activeBooking!.fastDeliveryCharge! > 0)
                                Text(
                                  '+ ₹${driverProvider.activeBooking!.fastDeliveryCharge!.toStringAsFixed(2)} Fast Charge',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFCC2D3B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
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
                      if (driverProvider.activeBooking!.commissionAmount != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEAD2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEAD2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFFE2A03F),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Commission Deducted',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF4A4B50),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '- ₹${driverProvider.activeBooking!.commissionAmount!.toStringAsFixed(2)}',
                                          style: GoogleFonts.ibmPlexMono(
                                            color: const Color(0xFFCC2D3B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'This amount will be deducted from your wallet.',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF8E9098),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      
                      // Contact Dropdown Toggle Row
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isContactDropdownExpanded = !_isContactDropdownExpanded;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Text(
                                'CONTACT',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF6C6F79),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE1E1E6),
                                  thickness: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isContactDropdownExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF6C6F79),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Contact Dropdown Content
                      if (_isContactDropdownExpanded) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE1E1E6)),
                          ),
                          child: Column(
                            children: [
                              // Customer Contact
                              _buildContactRow(
                                role: 'Customer',
                                name: driverProvider.activeBooking!.customer?.fullName ?? 'No Name',
                                phone: driverProvider.activeBooking!.customer?.phone ?? '',
                              ),
                              const Divider(color: Color(0xFFE1E1E6), height: 16),
                              
                              // Pickup Contact
                              _buildContactRow(
                                role: 'Pickup Contact',
                                name: (driverProvider.activeBooking!.pickupContactName != null &&
                                        driverProvider.activeBooking!.pickupContactName!.isNotEmpty)
                                    ? driverProvider.activeBooking!.pickupContactName!
                                    : (driverProvider.activeBooking!.customer?.fullName ?? 'No Name'),
                                phone: (driverProvider.activeBooking!.pickupContactPhone != null &&
                                        driverProvider.activeBooking!.pickupContactPhone!.isNotEmpty)
                                    ? driverProvider.activeBooking!.pickupContactPhone!
                                    : (driverProvider.activeBooking!.customer?.phone ?? ''),
                              ),
                              const Divider(color: Color(0xFFE1E1E6), height: 16),
                              
                              // Drop Contact
                              _buildContactRow(
                                role: 'Drop Contact',
                                name: (driverProvider.activeBooking!.dropContactName != null &&
                                        driverProvider.activeBooking!.dropContactName!.isNotEmpty)
                                    ? driverProvider.activeBooking!.dropContactName!
                                    : (driverProvider.activeBooking!.customer?.fullName ?? 'No Name'),
                                phone: (driverProvider.activeBooking!.dropContactPhone != null &&
                                        driverProvider.activeBooking!.dropContactPhone!.isNotEmpty)
                                    ? driverProvider.activeBooking!.dropContactPhone!
                                    : (driverProvider.activeBooking!.customer?.phone ?? ''),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Status / OTP Action Section
                      const SizedBox(height: 14),
                      Builder(
                        builder: (context) {
                          final statusUpper = driverProvider.activeBooking!.status.toUpperCase();
                          if (statusUpper == 'DRIVER_ARRIVED') {
                            return OtpVerificationView(
                              isLoading: _isVerifyingOtp,
                              isSuccess: false,
                              onOtpSubmit: (otp) async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() {
                                  _isVerifyingOtp = true;
                                });
                                final success = await driverProvider.verifyOtpForBooking(
                                  driverProvider.activeBooking!.id,
                                  otp,
                                );
                                setState(() {
                                  _isVerifyingOtp = false;
                                });
                                if (!success && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        driverProvider.bookingsError ?? 'OTP verification failed',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                } else if (success && mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('OTP Verified successfully!'),
                                    ),
                                  );
                                }
                              },
                            );
                          } else if (statusUpper == 'DRIVER_ARRIVED_DROP') {
                            // Arrived at drop payment selection or QR
                            if (_selectedPaymentMethod == null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'COLLECT PAYMENT',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF6C6F79),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedPaymentMethod = 'CASH';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFE1E1E6),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.payments_rounded,
                                                  color: Color(0xFF1C9A5B),
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Cash Payment',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: const Color(0xFF121214),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Collect physical cash',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    color: const Color(0xFF6C6F79),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedPaymentMethod = 'QR';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFE1E1E6),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.qr_code_2_rounded,
                                                  color: Color(0xFFD90429),
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'UPI / QR Code',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: const Color(0xFF121214),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Scan to pay driver',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    color: const Color(0xFF6C6F79),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else if (_selectedPaymentMethod == 'CASH') {
                              return Column(
                                children: [
                                  SwipeSlider(
                                    key: ValueKey('home_complete_cash_${driverProvider.activeBooking!.status}_${driverProvider.activeBooking!.id}'),
                                    text: 'Swipe: Complete Delivery',
                                    isLoading: driverProvider.isBookingsLoading,
                                    onSwipeComplete: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final nextStatus = _getNextStatus(driverProvider.activeBooking!.status);
                                      final success = await driverProvider.updateStatusForBooking(
                                        driverProvider.activeBooking!.id,
                                        nextStatus,
                                      );
                                      if (success && mounted) {
                                        setState(() {
                                          _selectedPaymentMethod = null;
                                        });
                                        return true;
                                      } else if (!success && mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              driverProvider.bookingsError ?? 'Status update failed',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return false;
                                      }
                                      return false;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPaymentMethod = null;
                                      });
                                    },
                                    child: Text(
                                      'Change Payment Method',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFD90429),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else if (_selectedPaymentMethod == 'QR') {
                              final upiId = driverProvider.profile?.upiId;
                              if (upiId == null || upiId.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF5F5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFFD1D1),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFD90429),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'UPI ID is not configured. Please configure it in your profile settings.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFD90429),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedPaymentMethod = 'CASH';
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFD90429),
                                          side: const BorderSide(
                                            color: Color(0xFFD90429),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text('Choose Cash Payment Instead', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final String payeeName = driverProvider.profile?.name ?? 'Partner';
                              final String upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=${driverProvider.activeBooking!.totalFare.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Booking ${driverProvider.activeBooking!.bookingId}")}';
                              final String qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE1E1E6),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'SCAN QR CODE TO PAY',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF6C6F79),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            qrImageUrl,
                                            width: 140,
                                            height: 140,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 140,
                                              height: 140,
                                              color: const Color(0xFFFFF5F5),
                                              child: const Icon(
                                                Icons.qr_code_rounded,
                                                size: 40,
                                                color: Color(0xFFD90429),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '₹${driverProvider.activeBooking!.totalFare.toStringAsFixed(2)}',
                                          style: GoogleFonts.ibmPlexMono(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            color: const Color(0xFF121214),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SwipeSlider(
                                    key: ValueKey('home_complete_qr_${driverProvider.activeBooking!.status}_${driverProvider.activeBooking!.id}'),
                                    text: 'Swipe: Complete Delivery',
                                    isLoading: driverProvider.isBookingsLoading,
                                    onSwipeComplete: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final nextStatus = _getNextStatus(driverProvider.activeBooking!.status);
                                      final success = await driverProvider.updateStatusForBooking(
                                        driverProvider.activeBooking!.id,
                                        nextStatus,
                                      );
                                      if (success && mounted) {
                                        setState(() {
                                          _selectedPaymentMethod = null;
                                        });
                                        return true;
                                      } else if (!success && mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              driverProvider.bookingsError ?? 'Status update failed',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return false;
                                      }
                                      return false;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPaymentMethod = null;
                                      });
                                    },
                                    child: Text(
                                      'Change Payment Method',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFD90429),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          } else if (statusUpper != 'DELIVERED' && 
                                     statusUpper != 'COMPLETED' && 
                                     statusUpper != 'CANCELLED') {
                            return SwipeSlider(
                              key: ValueKey('home_status_${driverProvider.activeBooking!.status}_${driverProvider.activeBooking!.id}'),
                              text: _getSliderText(driverProvider.activeBooking!.status),
                              isLoading: driverProvider.isBookingsLoading,
                              onSwipeComplete: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final nextStatus = _getNextStatus(driverProvider.activeBooking!.status);
                                
                                if (nextStatus == 'IN_TRANSIT') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Text(
                                        'Start Ride',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF121214),
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to start the ride? You cannot cancel the booking once the ride has started.',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF6C6F79),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF6C6F79),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE31C2E),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                          ),
                                          child: Text(
                                            'Start Ride',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return false;
                                }

                                final success = await driverProvider.updateStatusForBooking(
                                  driverProvider.activeBooking!.id,
                                  nextStatus,
                                );
                                if (!success && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        driverProvider.bookingsError ?? 'Status update failed',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return false;
                                }
                                return success;
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      
                      // Bottom Buttons: View Details and Map Side-by-Side
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverBookingDetailsScreen(
                                    booking: driverProvider.activeBooking!,
                                    startExpanded: false,
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
                              backgroundColor: const Color(0xFF121214),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Map',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Fast Booking Badge overlapping the top right border
                if (driverProvider.activeBooking!.fastDelivery)
                  Positioned(
                    top: -10,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC2D3B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33CC2D3B),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'FAST BOOKING',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
              ],
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

class UpdateDriverProfileDialog extends StatefulWidget {
  final DriverProfileModel profile;

  const UpdateDriverProfileDialog({super.key, required this.profile});

  @override
  State<UpdateDriverProfileDialog> createState() => _UpdateDriverProfileDialogState();
}

class _UpdateDriverProfileDialogState extends State<UpdateDriverProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _upiController;
  late final TextEditingController _licenseController;
  late final TextEditingController _dobController;
  late final TextEditingController _bioController;
  String _selectedGender = 'MALE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController(text: widget.profile.upiId ?? '');
    _licenseController = TextEditingController(text: widget.profile.licenseNumber);
    _dobController = TextEditingController(text: widget.profile.dob ?? '');
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedGender = ['MALE', 'FEMALE', 'OTHER'].contains(widget.profile.gender.toUpperCase())
        ? widget.profile.gender.toUpperCase()
        : 'MALE';
  }

  @override
  void dispose() {
    _upiController.dispose();
    _licenseController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD90429),
              onPrimary: Colors.white,
              onSurface: Color(0xFF121214),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD90429),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<DriverHomeProvider>();
    final success = await provider.updateProfile(
      licenseNumber: _licenseController.text.trim(),
      bio: _bioController.text.trim(),
      gender: _selectedGender,
      dob: _dobController.text.trim(),
      upiId: _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: const Color(0xFFD90429),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String? Function(String?) validator,
    int maxLines = 1,
    bool autofocus = false,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF121214)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          autofocus: autofocus,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF1A202C),
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFA0AEC0), fontSize: 12.5),
            filled: true,
            fillColor: isHighlighted ? const Color(0xFFFFF9F3) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            prefixIcon: Icon(icon, color: isHighlighted ? const Color(0xFFE2A03F) : const Color(0xFFA2A5AE), size: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isHighlighted ? const Color(0xFFFFEAD2) : const Color(0xFFE7E7EB),
                width: isHighlighted ? 1.8 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isHighlighted ? const Color(0xFFE2A03F) : const Color(0xFFD90429),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Area
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD90429).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_box_rounded,
                          color: Color(0xFFD90429),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Update Profile Details',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF121214),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: const Color(0xFF6C6F79)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFE7E7EB)),

                  // 1. UPI ID (At the top, highlighted, auto-focused)
                  _buildTextField(
                    label: 'UPI ID (Required for Payouts)',
                    controller: _upiController,
                    icon: Icons.account_balance_wallet_rounded,
                    hintText: 'e.g. name@upi',
                    autofocus: true,
                    isHighlighted: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'UPI ID is required to update';
                      }
                      if (!val.contains('@')) {
                        return 'Please enter a valid UPI ID (must contain @)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // 2. Date of Birth
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF121214)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1A202C)),
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFFA0AEC0), fontSize: 12.5),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFFA2A5AE), size: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFD90429), width: 2.0),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Date of birth is required' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 3. Gender Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF121214)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1A202C)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.people_rounded, color: Color(0xFFA2A5AE), size: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFD90429), width: 2.0),
                          ),
                        ),
                        items: ['MALE', 'FEMALE', 'OTHER'].map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g[0] + g.substring(1).toLowerCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGender = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 4. License Number
                  _buildTextField(
                    label: 'License Number',
                    controller: _licenseController,
                    icon: Icons.badge_rounded,
                    hintText: 'Enter your driving license number',
                    validator: (val) => val == null || val.trim().isEmpty ? 'License number is required' : null,
                  ),
                  const SizedBox(height: 22),

                  // 5. Bio
                  _buildTextField(
                    label: 'Bio',
                    controller: _bioController,
                    icon: Icons.info_outline_rounded,
                    hintText: 'Briefly describe your driving experience...',
                    maxLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Bio cannot be empty' : null,
                  ),
                  const SizedBox(height: 28),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Color(0xFFE7E7EB)),
                          ),
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD90429),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Update',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingBookingCard extends StatefulWidget {
  final BookingModel booking;
  final DateTime firstSeenTime;
  final VoidCallback onGoToWallet;
  final Future<bool> Function() onAccept;

  const _PendingBookingCard({
    super.key,
    required this.booking,
    required this.firstSeenTime,
    required this.onGoToWallet,
    required this.onAccept,
  });

  @override
  State<_PendingBookingCard> createState() => _PendingBookingCardState();
}

class _PendingBookingCardState extends State<_PendingBookingCard> {
  bool _canShowDetails = false;
  Timer? _detailsTimer;

  @override
  void initState() {
    super.initState();
    _checkDetailsAvailability();
  }

  void _checkDetailsAvailability() {
    final elapsedMs = DateTime.now().difference(widget.firstSeenTime).inMilliseconds;
    if (elapsedMs >= 5000) {
      _canShowDetails = true;
    } else {
      _canShowDetails = false;
      _detailsTimer?.cancel();
      _detailsTimer = Timer(Duration(milliseconds: 5000 - elapsedMs), () {
        if (mounted) {
          setState(() {
            _canShowDetails = true;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _PendingBookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.firstSeenTime != widget.firstSeenTime) {
      _checkDetailsAvailability();
    }
  }

  @override
  void dispose() {
    _detailsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
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

          // 2. Price, distance and details action button (Details button visible only after 5s)
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
              // Details Button: Hidden during the first 5 seconds, fades in smoothly after 5s
              AnimatedOpacity(
                opacity: _canShowDetails ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_canShowDetails,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => DriverBookingDetailsScreen(
                            booking: booking,
                          ),
                        ),
                      );
                      if (result == 'go_to_wallet' && mounted) {
                        widget.onGoToWallet();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Pickup and Drop Location Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Column(
              children: [
                // Pickup Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C9A5B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA2A5AE),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            booking.pickupAddressName.isNotEmpty
                                ? booking.pickupAddressName
                                : 'Pickup Location',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF121214),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Connecting Line
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 1.5,
                      height: 14,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),

                // Drop Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFFD90429),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DROP',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA2A5AE),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            booking.dropAddressName.isNotEmpty
                                ? booking.dropAddressName
                                : 'Drop Location',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF121214),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Swipe to Accept Button with 5s Progress Bar Timer
          TimedSwipeToAcceptButton(
            key: ValueKey('swipe_accept_${booking.id}'),
            bookingId: booking.id,
            firstSeenTime: widget.firstSeenTime,
            onAccept: widget.onAccept,
          ),
        ],
      ),
    );
  }
}

class _GoOfflineSlider extends StatefulWidget {
  final Future<bool> Function() onSwipeComplete;
  final bool isLoading;

  const _GoOfflineSlider({
    required this.onSwipeComplete,
    this.isLoading = false,
  });

  @override
  State<_GoOfflineSlider> createState() => _GoOfflineSliderState();
}

class _GoOfflineSliderState extends State<_GoOfflineSlider>
    with SingleTickerProviderStateMixin {
  double _thumbPosition = 0;
  bool _isCompleted = false;

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _slideAnim = Tween<double>(
    begin: 0.0,
    end: 6.0,
  ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDistance = constraints.maxWidth - 46;
        final double currentPosition = widget.isLoading ? maxDistance : _thumbPosition;

        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2B0A0E), // Dark crimson red
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF8B1E28),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Red drag progress track
              if (currentPosition > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: currentPosition + 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

              // Centered text with animated subtle rightward shift
              Center(
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_slideAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Swipe to Go Offline',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Color(0xFFFCA5A5),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Slider Thumb
              Positioned(
                left: currentPosition + 3,
                top: 3,
                bottom: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted || widget.isLoading) return;
                    setState(() {
                      _thumbPosition += details.delta.dx;
                      if (_thumbPosition < 0) _thumbPosition = 0;
                      if (_thumbPosition > maxDistance) _thumbPosition = maxDistance;
                    });
                  },
                  onHorizontalDragEnd: (details) async {
                    if (_isCompleted || widget.isLoading) return;
                    if (_thumbPosition >= maxDistance * 0.75) {
                      setState(() {
                        _thumbPosition = maxDistance;
                        _isCompleted = true;
                      });
                      final success = await widget.onSwipeComplete();
                      if (success != true && mounted) {
                        setState(() {
                          _thumbPosition = 0;
                          _isCompleted = false;
                        });
                      }
                    } else {
                      setState(() {
                        _thumbPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD90429),
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: Color(0xFFD90429),
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
