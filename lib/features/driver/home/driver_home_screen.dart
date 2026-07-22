import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_home_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_history_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_bank_accounts_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_profile_page.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DriverHomeProvider>();
      final trackingService = context.read<LocationTrackingService>();

      await provider.fetchDriverProfile();
      if (mounted) {
        final profile = provider.profile;
        if (profile != null && profile.isOnline) {
          // Driver is already online — start tracking immediately
          trackingService.start();
        } else if (profile != null && !profile.isOnline) {
          _showGoOnlineDialog(context, provider, trackingService);
        }
      }
    });
  }

  @override
  void dispose() {
    // Stop tracking when the driver leaves this screen
    context.read<LocationTrackingService>().stop();
    super.dispose();
  }

  void _showGoOnlineDialog(
    BuildContext context,
    DriverHomeProvider provider,
    LocationTrackingService trackingService,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.wifi_off_rounded, color: Color(0xFFB9700A)),
            SizedBox(width: 8),
            Text(
              'You are Offline',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
            ),
          ],
        ),
        content: const Text(
          'Make yourself online to receive Bookings.',
          style: TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay Offline', style: TextStyle(color: Color(0xFF6C6F79))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C9A5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.setOnlineStatus(true);
              if (success && context.mounted) {
                // Driver went online — start location tracking
                trackingService.start();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are now Online! 🟢'),
                    backgroundColor: Color(0xFF1C9A5B),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to go online'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Go Online'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    if (driverProvider.isLoading && profile == null) {
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
        children: const [
          DriverHomePage(),
          DriverHistoryPage(),
          DriverWalletPage(),
          DriverProfilePage(),
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
              });
              if (index == 0) {
                context.read<DriverHomeProvider>().fetchHomeBookings();
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Rides',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
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
