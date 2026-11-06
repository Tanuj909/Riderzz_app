import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/services/native_overlay_controller.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_home_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_history_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_messages_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_bank_accounts_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_profile_page.dart';
import 'package:riderzz_app/core/services/reward_notification_coordinator.dart';
import 'package:riderzz_app/core/services/campaign_banner_service.dart';
import 'package:google_fonts/google_fonts.dart';


class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  final Set<int> _initializedIndices = {0};
  DriverHomeProvider? _driverHomeProvider;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onDriverHomeProviderChanged() {
    if (!mounted) return;
    final provider = _driverHomeProvider;
    if (provider != null) {
      final trackingService = context.read<LocationTrackingService>();
      trackingService.updateHasActiveBooking(provider.activeBooking != null);
    }
  }

  @override
  void initState() {
    super.initState();
    NativeOverlayController.scheduleDriverPermissionPrompt();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _driverHomeProvider = context.read<DriverHomeProvider>();
      _driverHomeProvider?.addListener(_onDriverHomeProviderChanged);

      final provider = _driverHomeProvider!;
      final trackingService = context.read<LocationTrackingService>();

      await provider.fetchDriverProfile();
      if (mounted) {
        await CampaignBannerService.showCampaignBannerIfNeeded(context);
        if (!mounted) return;

        final profile = provider.profile;
        if (profile != null && profile.isOnline) {
          // Driver is already online — start tracking immediately
          trackingService.start(hasActiveBooking: provider.activeBooking != null);
        } else if (profile != null && !profile.isOnline) {
          _showGoOnlineDialog(context, provider, trackingService);
        }
        RewardNotificationCoordinator.instance.onHomeScreenReady();
      }
    });
  }

  @override
  void dispose() {
    _driverHomeProvider?.removeListener(_onDriverHomeProviderChanged);
    // Stop tracking when the driver leaves this screen
    context.read<LocationTrackingService>().stop();
    super.dispose();
  }

  void _showGoOnlineDialog(
    BuildContext context,
    DriverHomeProvider provider,
    LocationTrackingService trackingService,
  ) {
    bool isGoingOnline = false;

    showDialog(
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
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFFB45309),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'You are Offline',
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
                    'Make yourself online to receive bookings and alerts.',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Line 1: Slider to go online
                  _GoOnlineSlider(
                    isLoading: isGoingOnline,
                    onSwipeComplete: () async {
                      setDialogState(() {
                        isGoingOnline = true;
                      });
                      final success = await provider.setOnlineStatus(true);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        if (success) {
                          trackingService.start(hasActiveBooking: provider.activeBooking != null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are now Online! 🟢'),
                              backgroundColor: Color(0xFF1C9A5B),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.errorMessage ?? 'Failed to go online'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                      return success;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Line 2: Stay Offline button
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Stay Offline',
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    final unreadCount = driverProvider.messages.where((m) => !m.read).length;

    if (profile == null && driverProvider.errorMessage == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
          ),
        ),
      );
    }

    if (driverProvider.errorMessage != null && profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  driverProvider.errorMessage!,
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
                  onPressed: () {
                    context.read<DriverHomeProvider>().fetchDriverProfile();
                  },
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DriverHomePage(),
          _initializedIndices.contains(1) ? const DriverHistoryPage() : const SizedBox.shrink(),
          _initializedIndices.contains(2) ? const DriverWalletPage() : const SizedBox.shrink(),
          _initializedIndices.contains(3) ? const DriverMessagesPage() : const SizedBox.shrink(),
          _initializedIndices.contains(4) ? const DriverProfilePage() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Color(0xFFE1E1E6), width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A121214),
              blurRadius: 24,
              offset: Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _initializedIndices.add(index);
              });
              if (index == 0) {
                context.read<DriverHomeProvider>().fetchHomeBookings();
              } else if (index == 3) {
                context.read<DriverHomeProvider>().fetchDriverMessages(force: true);
                context.read<DriverHomeProvider>().markAllMessagesAsRead();
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFFD90429),
            unselectedItemColor: const Color(0xFFA2A5AE),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Rides',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  backgroundColor: const Color(0xFFD90429),
                  child: const Icon(Icons.mail_outline_rounded),
                ),
                activeIcon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  backgroundColor: const Color(0xFFD90429),
                  child: const Icon(Icons.mail_rounded),
                ),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoOnlineSlider extends StatefulWidget {
  final Future<bool> Function() onSwipeComplete;
  final bool isLoading;

  const _GoOnlineSlider({
    required this.onSwipeComplete,
    this.isLoading = false,
  });

  @override
  State<_GoOnlineSlider> createState() => _GoOnlineSliderState();
}

class _GoOnlineSliderState extends State<_GoOnlineSlider>
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
            color: const Color(0xFF0A291A), // Forest dark green
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF1B6A3D),
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
              // Forest green track on drag
              if (currentPosition > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: currentPosition + 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF15803D), Color(0xFF166534)],
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
                        'Swipe to Go Online',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Color(0xFF86EFAC),
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
                                  Color(0xFF0A291A),
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: Color(0xFF0A291A),
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
