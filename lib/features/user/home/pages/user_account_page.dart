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
            Icon(Icons.info_outline_rounded, color: Color(0xFFE31C2E)),
            SizedBox(width: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
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
            child: const Text('Okay', style: TextStyle(color: Color(0xFFE31C2E), fontWeight: FontWeight.bold)),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
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
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C6F79), fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Row
          Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE31C2E), Color(0xFFB01221)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31C2E).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.name ?? 'Rahul Kumar',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121214),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Color(0xFF664200),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              user?.phone ?? '+91 98765 43210',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6C6F79),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFE7E7EB), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF1C9A5B)),
                            const SizedBox(width: 3),
                            const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1C9A5B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF121214)),
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                      ).then((_) {
                        auth.fetchCustomerProfile();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Card 1
          _buildCard(
            children: [
              _buildListItem(
                icon: Icons.person_outline_rounded,
                label: 'Edit profile',
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
              _buildListItem(
                icon: Icons.home_outlined,
                label: 'Saved addresses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddressListScreen()),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.directions_outlined,
                label: 'Saved Routes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavedRouteListScreen()),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.receipt_long_outlined,
                label: 'Transaction History',
                showBorder: false,
                onTap: () => _showComingSoonDialog(context, 'Transaction History'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Become Driver Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE31C2E), Color(0xFFB01221)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE31C2E).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Become a driver',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEBEC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFFB01221),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Earn on your own schedule',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 3
          _buildCard(
            children: [
              _buildListItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                onTap: () => _showComingSoonDialog(context, 'Help & Support'),
              ),
              _buildListItem(
                icon: Icons.security_outlined,
                label: 'Terms & privacy',
                onTap: () => _showComingSoonDialog(context, 'Terms & Privacy'),
              ),
              _buildListItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                isDestructive: true,
                showBorder: false,
                onTap: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showBorder = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: Color(0xFFE7E7EB), width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFDEBEC) : const Color(0xFFF1F1F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFE31C2E) : const Color(0xFFE31C2E),
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EABB8), size: 16),
          ],
        ),
      ),
    );
  }
}
