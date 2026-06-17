import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/home/pages/user_home_page.dart';
import 'package:riderzz_app/features/user/home/pages/user_bookings_page.dart';
import 'package:riderzz_app/features/user/home/pages/user_payments_page.dart';
import 'package:riderzz_app/features/user/home/pages/user_account_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

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
            Icon(Icons.help_outline_rounded, color: Color(0xFF1A3D6B)),
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
            child: const Text('Close', style: TextStyle(color: Color(0xFF1A3D6B), fontWeight: FontWeight.bold)),
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
            // Reusable User Layout App Bar Header
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
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (user?.status != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user?.status == 'ACTIVE' ? Colors.greenAccent : Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user?.status ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
                                user?.name ?? 'Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1A2233),
                                ),
                              ),
                              if (user?.phone != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF6B7785)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+91 ${user!.phone}',
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
                        _getInitials(user?.name),
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
            ),

            // Layout Body containing currently active subpage view
            Expanded(
              child: _buildTabContent(context),
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
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Payments',
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

  Widget _buildTabContent(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return UserHomePage(
          onBookingConfirmed: () {
            setState(() {
              _currentIndex = 1; // Transition to bookings tab on confirmation
            });
          },
        );
      case 1:
        return const UserBookingsPage();
      case 2:
        return const UserPaymentsPage();
      case 3:
        return UserAccountPage(
          onNavigateToHistory: () {
            setState(() {
              _currentIndex = 2; // Transition to payments tab
            });
          },
        );
      default:
        return UserHomePage(
          onBookingConfirmed: () {
            setState(() {
              _currentIndex = 1;
            });
          },
        );
    }
  }
}
