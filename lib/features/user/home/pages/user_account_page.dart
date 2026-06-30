import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';
import 'package:riderzz_app/features/driver/profile/become_driver_screen.dart';
import 'package:riderzz_app/features/user/profile/screens/customer_profile_screen.dart';

class UserAccountPage extends StatefulWidget {
  final VoidCallback onNavigateToHistory;

  const UserAccountPage({
    super.key,
    required this.onNavigateToHistory,
  });

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchCustomerProfile();
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'RK';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: Color(0xFF1A3D6B)),
            SizedBox(width: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
            ),
          ],
        ),
        content: Text(
          '$featureName feature is under development and will be available in the next release. Stay tuned!',
          style: const TextStyle(color: Color(0xFF4A5568), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay', style: TextStyle(color: Color(0xFF1A3D6B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Confirm Logout',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Color(0xFF4A5568), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await authProvider.logout();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final customerProfile = authProvider.customerProfile;
    final profileImage = customerProfile?.profileImage ?? user?.profileImage;
    final bio = customerProfile?.bio;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A3D6B).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9B6E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: (profileImage != null && profileImage.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (profileImage == null || profileImage.isEmpty)
                      ? Text(
                          _getInitials(user?.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Rahul Kumar',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2233),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.phone ?? '+91 98765 43210',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7785),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bio != null && bio.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            bio,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PROFILE SETTINGS SECTION
          _buildSectionHeader('PROFILE SETTINGS'),
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            color: const Color(0xFFE8F0FB),
            iconColor: const Color(0xFF1A3D6B),
            label: 'View My Profile',
            onTap: () {
              final auth = context.read<AuthProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
              ).then((_) {
                auth.fetchCustomerProfile();
              });
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

          const SizedBox(height: 18),

          // SERVICES & APP
          _buildSectionHeader('SERVICES & APP'),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFFFF3E8),
            iconColor: const Color(0xFFF97316),
            label: 'Transaction History',
            onTap: () => _showComingSoonDialog(context, 'Transaction History'),
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
            color: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF475569),
            label: 'Help & Support',
            onTap: () => _showComingSoonDialog(context, 'Help & Support'),
          ),

          const SizedBox(height: 18),

          // ACCOUNT ACTIONS
          _buildSectionHeader('ACCOUNT'),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            color: const Color(0xFFFEF2F2),
            iconColor: Colors.redAccent,
            label: 'Logout',
            onTap: () => _showLogoutDialog(context, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
        onTap: onTap,
      ),
    );
  }
}
