import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_home_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_history_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
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
      await provider.fetchDriverProfile();
      if (mounted) {
        final profile = provider.profile;
        if (profile != null && !profile.isOnline) {
          _showGoOnlineDialog(context, provider);
        }
      }
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'D';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: Color(0xFF1A3D6B)),
            SizedBox(width: 8),
            Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'For any booking queries or partner support, please email us at partner-support@cargoswift.com or call our toll-free 24/7 support line at +91 1800-123-4567.',
          style: TextStyle(color: Color(0xFF4A5568), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF1A3D6B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGoOnlineDialog(BuildContext context, DriverHomeProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.wifi_off_rounded, color: Color(0xFFF97316)),
            SizedBox(width: 8),
            Text(
              'You are Offline',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
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
            child: const Text('Stay Offline', style: TextStyle(color: Color(0xFF6B7785))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9B6E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.setOnlineStatus(true);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are now Online! 🟢'),
                    backgroundColor: Color(0xFF0F9B6E),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                    backgroundColor: const Color(0xFF1A3D6B),
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

    final driverName = profile?.name ?? user?.name ?? 'Partner';
    final approvalStatus = profile?.approvalStatus ?? 'UNDER_REVIEW';
    final isOnline = profile?.isOnline ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: const Color(0xFF1A3D6B),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar Header (Navy Background)
            Container(
              color: const Color(0xFF1A3D6B),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: approvalStatus == 'APPROVED' ? Colors.greenAccent : Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            approvalStatus == 'APPROVED' ? 'PARTNER ACTIVE' : 'UNDER REVIEW',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                                ),
                                content: const Text(
                                  'Are you sure you want to go offline? You will stop receiving ride bookings.',
                                  style: TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785))),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
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
                          }

                          final success = await driverProvider.toggleOnlineOffline();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(driverProvider.errorMessage ?? 'Failed to update status'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } else if (success && context.mounted) {
                            final newStatus = driverProvider.profile?.isOnline ?? false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(newStatus ? 'You are now Online! 🟢' : 'You are now Offline! 🔴'),
                                backgroundColor: newStatus ? const Color(0xFF0F9B6E) : const Color(0xFFF97316),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFFE6F7F2)
                                : const Color(0xFFFFF3E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOnline 
                                  ? const Color(0xFF0F9B6E) 
                                  : const Color(0xFFF97316),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            isOnline ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: isOnline 
                                  ? const Color(0xFF0F9B6E) 
                                  : const Color(0xFFF97316),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        onSelected: (value) async {
                          if (value == 'support') {
                            _showSupportDialog(context);
                          } else if (value == 'logout') {
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          }
                        },
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          // Profile Header
                          PopupMenuItem(
                            enabled: false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1A2233),
                                    ),
                                  ),
                                  if (profile?.phone != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF6B7785)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+91 ${profile!.phone}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            enabled: false,
                            height: 1,
                            child: Divider(
                              height: 1,
                              color: Color(0xFFE2E8F0),
                              thickness: 0.5,
                            ),
                          ),
                          // Vehicle Info
                          if (profile?.vehicleNumber != null)
                            PopupMenuItem(
                              enabled: false,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF1A3D6B)),
                                    const SizedBox(width: 8),
                                    Text(
                                      profile!.vehicleNumber,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A2233),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Help & Support
                          PopupMenuItem(
                            value: 'support',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: const [
                                  Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF4A5568)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Help & Support',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF1A2233), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Logout
                          PopupMenuItem(
                            value: 'logout',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: const [
                                  Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Logout',
                                    style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F9B6E),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _getInitials(driverName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Reusable Layout Body for Page Selection
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A3D6B),
        unselectedItemColor: const Color(0xFFB0B8C4),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Trips',
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
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return const DriverHomePage();
      case 1:
        return const DriverHistoryPage();
      case 2:
        return const DriverWalletPage();
      case 3:
        return const DriverProfilePage();
      default:
        return const DriverHomePage();
    }
  }
}
