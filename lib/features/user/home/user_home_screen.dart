import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/home/pages/user_home_page.dart';
import 'package:riderzz_app/features/user/home/pages/user_bookings_page.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/pages/user_account_page.dart';
import 'package:riderzz_app/features/user/wallet/screens/customer_wallet_screen.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final List<bool> _visitedTabs = [true, false, false, false, false];


  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
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
            Icon(Icons.help_outline_rounded, color: Color(0xFFE31C2E)),
            SizedBox(width: 8),
            Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'For any booking queries or support, please email us at support@cargoswift.com or call our toll-free 24/7 support line at +91 1800-123-4567.',
          style: TextStyle(color: Color(0xFF4A5568), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFFE31C2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Layout Body containing currently active subpage view
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  UserHomePage(
                    onBookingConfirmed: () {
                      // Intentionally empty. No background API calls or tab switches.
                    },
                  ),
                  _visitedTabs[1] ? const UserBookingsPage() : const SizedBox.shrink(),
                  _visitedTabs[2] ? const CustomerWalletScreen(showBackButton: false) : const SizedBox.shrink(),
                  _visitedTabs[3] ? const AddressListScreen(showBackButton: false) : const SizedBox.shrink(),
                  _visitedTabs[4]
                      ? UserAccountPage(
                          onNavigateToHistory: () {
                            setState(() {
                              _currentIndex = 1;
                              _visitedTabs[1] = true;
                            });
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // 30% reduction from bottom space (keeping 70% of original space)
    final double bottomPadding = bottomInset > 0 ? (bottomInset * 0.70) : 10.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F1F4), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: bottomPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Bookings',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.location_on_outlined,
            activeIcon: Icons.location_on_rounded,
            label: 'Address',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFE31C2E) : const Color(0xFFA2A5AE);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
            _visitedTabs[index] = true;
          });
          if (index == 0) {
            context.read<BookingProvider>().fetchCurrentBookings();
          } else if (index == 1) {
            context.read<BookingProvider>().fetchBookings(page: 0);
          } else if (index == 2) {
            context.read<CustomerWalletProvider>().fetchCustomerWallet();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
