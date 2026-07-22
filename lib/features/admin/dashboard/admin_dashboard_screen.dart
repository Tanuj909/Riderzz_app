import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/screens/admin_vehicles_screen.dart';
import 'package:riderzz_app/features/admin/vehicles/screens/admin_vehicles_list_screen.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_list_provider.dart';
import 'package:riderzz_app/features/admin/rider_verification/rider_verification_screen.dart';
import 'package:riderzz_app/features/admin/rider_verification/providers/rider_verification_provider.dart';
import 'package:riderzz_app/features/admin/wallets/screens/admin_wallets_screen.dart';
import 'package:riderzz_app/features/admin/commission/screens/admin_commission_screen.dart';
import 'package:riderzz_app/features/admin/commission/screens/admin_pricing_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RiderVerificationProvider>();
      if (provider.currentStatusFilter != 'PENDING') {
        provider.setStatusFilter('PENDING');
      } else {
        provider.fetchDrivers(isRefresh: true);
      }
    });
  }

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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: const Color(0xFFE31C2E),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Admin Reusable Header App Bar Layout (Shared across tabs)
            Container(
              color: const Color(0xFFE31C2E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminUser?.name ?? 'Administrator',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
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
                          Text(
                            'SYSTEM ACTIVE',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    onSelected: (value) {
                      if (value == 'logout') {
                        _handleLogout(context, authProvider);
                      }
                    },
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                                adminUser?.name ?? 'Administrator',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                              if (adminUser?.phone != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF6C6F79)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+91 ${adminUser!.phone}',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Color(0xFF6C6F79)),
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
                          color: Color(0xFFE7E7EB),
                          thickness: 0.5,
                        ),
                      ),
                      // Logout
                      PopupMenuItem(
                        value: 'logout',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Logout Portal',
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                        color: Color(0xFF1C9A5B),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(adminUser?.name),
                        style: GoogleFonts.outfit(
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
          if (index == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final provider = context.read<RiderVerificationProvider>();
              if (provider.currentStatusFilter != 'PENDING') {
                provider.setStatusFilter('PENDING');
              } else {
                provider.fetchDrivers(isRefresh: true);
              }
            });
          } else if (index == 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AdminVehiclesListProvider>().fetchVehicles(isRefresh: true);
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE31C2E),
        unselectedItemColor: const Color(0xFFB0B8C4),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
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
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping_rounded),
            label: 'Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airport_shuttle_outlined),
            activeIcon: Icon(Icons.airport_shuttle_rounded),
            label: 'Vehicle Types',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallets',
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
        return const AdminVehiclesListScreen();
      case 3:
        return const AdminVehiclesScreen();
      case 4:
        return const AdminWalletsScreen();
      default:
        return _buildDashboardTab();
    }
  }

  // TAB 0: DASHBOARD OPERATIONAL OVERVIEW
  Widget _buildDashboardTab() {
    final verificationProvider = Provider.of<RiderVerificationProvider>(context);

    // Automatically self-correct filter and fetch pending count if not set to PENDING
    if (verificationProvider.currentStatusFilter != 'PENDING' && !verificationProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        verificationProvider.setStatusFilter('PENDING');
      });
    }

    final int pendingCount = verificationProvider.drivers.length;
    final String driverSubtitle = verificationProvider.isLoading
        ? 'Loading pending requests...'
        : '$pendingCount pending request${pendingCount == 1 ? '' : 's'} awaiting review';

    return RefreshIndicator(
      onRefresh: () async {
        final provider = context.read<RiderVerificationProvider>();
        if (provider.currentStatusFilter != 'PENDING') {
          await provider.setStatusFilter('PENDING');
        } else {
          await provider.fetchDrivers(isRefresh: true);
        }
      },
      color: const Color(0xFFE31C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            Text(
              'Operational Overview',
              style: GoogleFonts.outfit(
                color: Color(0xFF121214),
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
              childAspectRatio: 1.8,
              children: [
                _buildStatCard(
                  title: 'Active Bookings',
                  value: '42',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFFE31C2E),
                ),
                _buildStatCard(
                  title: 'Total Drivers',
                  value: '18',
                  icon: Icons.sports_motorsports_rounded,
                  color: const Color(0xFF1C9A5B),
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
            */
   
            Text(
              'Administrative Tasks',
              style: GoogleFonts.outfit(
                color: const Color(0xFF121214),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
   
            _buildActionItem(
              title: 'Driver Requests',
              subtitle: driverSubtitle,
              icon: Icons.person_add_rounded,
              iconBgColor: const Color(0xFFFFF0F0),
              iconColor: Colors.redAccent,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  verificationProvider.isLoading
                      ? 'Loading...'
                      : '$pendingCount Pending',
                  style: GoogleFonts.outfit(
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
              title: 'Vehicle Configuration',
              subtitle: 'Manage vehicle types, rates, and limits',
              icon: Icons.airport_shuttle_rounded,
              iconBgColor: const Color(0xFFEBFDF6),
              iconColor: const Color(0xFF1C9A5B),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Transition to Vehicles tab
                });
              },
            ),
            _buildActionItem(
              title: 'Driver Wallets & Operations',
              subtitle: 'Manage balances, view transactions, and force offline status',
              icon: Icons.account_balance_wallet_rounded,
              iconBgColor: const Color(0xFFEBF3FD),
              iconColor: const Color(0xFFE31C2E),
              onTap: () {
                setState(() {
                  _currentIndex = 4; // Correct index for Wallets is 4
                });
              },
            ),
            _buildActionItem(
              title: 'Commission Configurations',
              subtitle: 'Configure vehicle-specific commission percentages',
              icon: Icons.percent_rounded,
              iconBgColor: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFD97706),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCommissionScreen()),
                );
              },
            ),
            _buildActionItem(
              title: 'Pricing Configurations',
              subtitle: 'Configure vehicle-specific pricing tiers and rules',
              icon: Icons.monetization_on_rounded,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPricingScreen()),
                );
              },
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF6C6F79),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF121214),
              fontSize: 18,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF121214),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 12.5,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0B8C4), size: 12),
      ),
    );
  }
}