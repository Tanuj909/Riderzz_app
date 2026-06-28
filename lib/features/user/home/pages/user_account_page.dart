import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';
import 'package:riderzz_app/features/driver/profile/become_driver_screen.dart';
import 'package:riderzz_app/features/user/profile/screens/customer_profile_screen.dart';

class UserAccountPage extends StatelessWidget {
  final VoidCallback onNavigateToHistory;

  const UserAccountPage({
    super.key,
    required this.onNavigateToHistory,
  });

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'RK';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Profile Details Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F9B6E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(user?.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Rahul Kumar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2233))),
                      const SizedBox(height: 4),
                      Text(user?.phone ?? '+91 98765 43210', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu list items
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            color: const Color(0xFFE8F0FB),
            iconColor: const Color(0xFF1A3D6B),
            label: 'View My Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.home_outlined,
            color: const Color(0xFFE6F7F2),
            iconColor: const Color(0xFF0F9B6E),
            label: 'Saved Addresses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddressListScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.directions_outlined,
            color: const Color(0xFFFDF2F8),
            iconColor: const Color(0xFFDB2777),
            label: 'Saved Routes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedRouteListScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFFFF3E8),
            iconColor: const Color(0xFFF97316),
            label: 'Transaction History',
            onTap: onNavigateToHistory,
          ),
          _buildMenuItem(
            icon: Icons.directions_car_filled_outlined,
            color: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            label: 'Become a Driver',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            color: const Color(0xFFF7F8FA),
            iconColor: const Color(0xFF6B7785),
            label: 'Help & Support',
            onTap: () => _showSupportDialog(context),
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            color: const Color(0xFFFEF2F2),
            iconColor: Colors.redAccent,
            label: 'Logout',
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECF0))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8C4)),
        onTap: onTap,
      ),
    );
  }
}
