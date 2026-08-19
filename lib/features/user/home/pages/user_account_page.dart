import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/screens/saved_route_list_screen.dart';
import 'package:riderzz_app/features/driver/profile/become_driver_screen.dart';
import 'package:riderzz_app/features/driver/profile/widgets/driver_terms_popup.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/user/profile/screens/customer_profile_screen.dart';
import 'package:riderzz_app/features/support/screens/support_tickets_screen.dart';

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
  // Dark refined red shade for icons
  static const Color _iconColor = Color(0xFF8B1A2B);
  static const Color _iconBgColor = Color(0xFFFDF2F4);
  static const Color _destructiveColor = Color(0xFFCC2D3B);
  static const Color _destructiveBgColor = Color(0xFFFDEBEC);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Coming Soon!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF121214), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '$featureName feature is under development and will be available in the next release. Stay tuned!',
          style: GoogleFonts.outfit(color: const Color(0xFF4A5568), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Okay', style: GoogleFonts.outfit(color: _iconColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _destructiveBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: _destructiveColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Logout',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF121214), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _destructiveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context, rootNavigator: true);
              Navigator.pop(dialogContext); // Close dialog
              context.read<DriverHomeProvider>().clearData();
              await authProvider.logout();
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Profile Header ──
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF0F0F4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC62E42).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
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
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Rahul Kumar',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF121214),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF664200),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            user?.phone ?? '+91 98765 43210',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF6C6F79),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFD5D5DB), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1C9A5B)),
                          const SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF1C9A5B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: () {
                    final auth = context.read<AuthProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                    ).then((_) {
                      auth.fetchCustomerProfile();
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3A3A42)),
                  ),
                ),
              ],
            ),
          ),

          // ── Section: General ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'GENERAL',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9EA3AE),
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildCard(
            children: [
              _buildListItem(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
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
                label: 'Saved Addresses',
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
                showBorder: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavedRouteListScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Become Driver Card ──
          GestureDetector(
            onTap: () {
              showDriverTermsAndConditionsPopup(context, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC62E42).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Become a Driver',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Earn on your own schedule',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Section: Support ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'SUPPORT',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9EA3AE),
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildCard(
            children: [
              _buildListItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportTicketsScreen()),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.security_outlined,
                label: 'Terms & Privacy',
                showBorder: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Logout Button (Separate Rounded Section) ──
          GestureDetector(
            onTap: () => _showLogoutDialog(context, authProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E4F), Color(0xFFCC2D3B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53E4F).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Log Out',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── App Version ──
          Center(
            child: Text(
              'Riderzz v1.0.0',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFFB0B5BF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDestructive ? _destructiveBgColor : _iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? _destructiveColor : _iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? _destructiveColor : const Color(0xFF1A1A1F),
                  ),
                ),
              ),
              if (!isDestructive)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B5BF), size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riderzz App Terms of Service',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: July 29, 2026',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the Riderzz application, you agree to comply with and be bound by these Terms and Conditions. If you do not agree, please do not use the application.',
            ),
            _buildSection(
              '2. User Accounts',
              'You must maintain accurate, complete, and up-to-date information in your Riderzz account. Failure to do so may result in your inability to access and use the services or termination of your account.',
            ),
            _buildSection(
              '3. Services Offered',
              'Riderzz provides a platform linking customers seeking transportation of goods/parcels with independent drivers. Riderzz is a facilitator and does not directly operate shipping logistics or employ drivers.',
            ),
            _buildSection(
              '4. Payment Terms',
              'Fares are calculated dynamically based on distance, demand, and options such as Fast Delivery. You agree to pay all fares, including additional priority charges, in accordance with the payment terms specified in the app.',
            ),
            _buildSection(
              '5. Prohibited Items',
              'Users shall not ship illegal, hazardous, flammable, explosive, toxic, or dangerous materials. Riderzz and independent partners reserve the right to reject packages that violate public safety regulations.',
            ),
            _buildSection(
              '6. Limitation of Liability',
              'Riderzz is not liable for direct, indirect, incidental, or consequential damages resulting from the acts, errors, or omissions of independent drivers or partners.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
