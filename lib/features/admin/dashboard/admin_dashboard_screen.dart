import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/screens/admin_vehicles_screen.dart';
import 'package:riderzz_app/features/admin/rider_verification/rider_verification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminUser = authProvider.currentUser;

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
            // Admin Reusable Header App Bar Layout (Shared across tabs)
            Container(
              color: const Color(0xFF1A3D6B),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riderzz Admin Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        adminUser?.name ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'SYSTEM ACTIVE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _handleLogout(context, authProvider);
                      }
                    },
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      if (adminUser?.phone != null) ...[
                        PopupMenuItem(
                          enabled: false,
                          child: Row(
                            children: [
                              const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF1A2233)),
                              const SizedBox(width: 8),
                              Text('+91 ${adminUser!.phone}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: const [
                            Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Logout Portal', style: TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F9B6E),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(adminUser?.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Tab Page Body
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_rounded),
            label: 'Pending Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airport_shuttle_outlined),
            activeIcon: Icon(Icons.airport_shuttle_rounded),
            label: 'Vehicles',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return const RiderVerificationScreen();
      case 2:
        return const AdminVehiclesScreen();
      default:
        return _buildDashboardTab();
    }
  }

  // TAB 0: DASHBOARD OPERATIONAL OVERVIEW
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Overview',
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Grid of Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                title: 'Active Bookings',
                value: '42',
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF1A3D6B),
              ),
              _buildStatCard(
                title: 'Total Drivers',
                value: '18',
                icon: Icons.sports_motorsports_rounded,
                color: const Color(0xFF0F9B6E),
              ),
              _buildStatCard(
                title: 'Total Customers',
                value: '124',
                icon: Icons.people_rounded,
                color: const Color(0xFFE28743),
              ),
              _buildStatCard(
                title: 'Today Revenue',
                value: '₹14,250',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.pinkAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Administrative Tasks',
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionItem(
            title: 'Driver Registration Approvals',
            subtitle: '6 pending drivers awaiting review',
            icon: Icons.verified_user_rounded,
            iconBgColor: const Color(0xFFFFF0F0),
            iconColor: Colors.redAccent,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Action Required',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _currentIndex = 1; // Transition to Pending Requests tab
              });
            },
          ),
          _buildActionItem(
            title: 'Ride Dispatch Center',
            subtitle: 'Monitor maps and live tracking',
            icon: Icons.map_rounded,
            iconBgColor: const Color(0xFFE8F0FB),
            iconColor: const Color(0xFF1A3D6B),
          ),
          _buildActionItem(
            title: 'Pricing & Configurations',
            subtitle: 'Update slab configurations and settings',
            icon: Icons.settings_suggest_rounded,
            iconBgColor: const Color(0xFFEBFDF6),
            iconColor: const Color(0xFF0F9B6E),
            onTap: () {
              setState(() {
                _currentIndex = 2; // Transition to Vehicles tab
              });
            },
          ),
        ],
      ),
    );
  }

  // TAB 1: PENDING REQUESTS TAB (now handled by RiderVerificationScreen)

  // UTILITY HELPER CARD BUILDERS
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7785),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7785),
            fontSize: 12,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0B8C4), size: 12),
      ),
    );
  }
}
