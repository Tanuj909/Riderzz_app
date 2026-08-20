import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/home/pages/user_home_page.dart';
import 'package:riderzz_app/features/user/home/pages/user_bookings_page.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/pages/user_account_page.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';

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
                  _visitedTabs[2] ? const AddressListScreen(showBackButton: false) : const SizedBox.shrink(),
                  _visitedTabs[3] ? const SavedRouteListScreen(showBackButton: false) : const SizedBox.shrink(),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedTabs[index] = true;
          });
          if (index == 0) {
            context.read<BookingProvider>().fetchCurrentBookings();
          } else if (index == 1) {
            context.read<BookingProvider>().fetchBookings(page: 0);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE31C2E), // var(--red)
        unselectedItemColor: const Color(0xFFA2A5AE), // var(--ink-faint)
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
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on_rounded),
            label: 'Address',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route_rounded),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
