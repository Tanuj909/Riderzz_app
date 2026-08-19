import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/admin/vehicles/screens/admin_vehicles_screen.dart';
import 'package:riderzz_app/features/admin/vehicles/screens/admin_registered_vehicles_screen.dart';
import 'package:riderzz_app/features/admin/rider_verification/rider_verification_screen.dart';
import 'package:riderzz_app/features/admin/rider_verification/providers/rider_verification_provider.dart';
import 'package:riderzz_app/features/admin/wallets/screens/admin_wallets_screen.dart';
import 'package:riderzz_app/features/admin/commission/screens/admin_pricing_screen.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/admin/bookings/all_bookings_screen.dart';
import 'package:riderzz_app/features/support/screens/support_tickets_screen.dart';

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
      provider.fetchOnlineApprovedDriverCount();
      if (provider.currentStatusFilter != 'PENDING') {
        provider.setStatusFilter('PENDING');
      } else {
        provider.fetchDrivers(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(child: _buildTabContent()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE1E1E6), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final provider = context.read<RiderVerificationProvider>();
                provider.fetchOnlineApprovedDriverCount();
                if (provider.currentStatusFilter != 'PENDING') {
                  provider.setStatusFilter('PENDING');
                } else {
                  provider.fetchDrivers(isRefresh: true);
                }
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          iconSize: 22,
          selectedItemColor: const Color(0xFFD90429),
          unselectedItemColor: const Color(0xFFA2A5AE),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Requests',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.commute_outlined),
            //   activeIcon: Icon(Icons.commute_rounded),
            //   label: 'Reg. Vehicles',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded),
              label: 'Vehicle Types',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallets',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return const RiderVerificationScreen();
      // case 2:
      //   return const AdminRegisteredVehiclesScreen();
      case 2: // Was 3
        return const AdminVehiclesScreen();
      case 3: // Was 4
        return const AdminWalletsScreen();
      default:
        return _buildDashboardTab();
    }
  }

  // TAB 0: DASHBOARD OPERATIONAL OVERVIEW
  Widget _buildDashboardTab() {
    final verificationProvider = Provider.of<RiderVerificationProvider>(
      context,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String adminPhone = authProvider.currentUser?.phone ?? '9891004821';

    // Self-correct filter and fetch pending drivers if not set to PENDING
    if (verificationProvider.currentStatusFilter != 'PENDING' &&
        !verificationProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        verificationProvider.setStatusFilter('PENDING');
      });
    }

    final int onlineDriverCount =
        verificationProvider.totalApprovedOnlineDrivers;
    final List<AdminDriverModel> pendingDrivers = verificationProvider.drivers;

    return RefreshIndicator(
      onRefresh: () async {
        final provider = context.read<RiderVerificationProvider>();
        await Future.wait([
          provider.fetchOnlineApprovedDriverCount(),
          provider.currentStatusFilter != 'PENDING'
              ? provider.setStatusFilter('PENDING')
              : provider.fetchDrivers(isRefresh: true),
        ]);
      },
      color: const Color(0xFFD90429),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Dashboard Header matching admin_mobile_screen.html
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIDERZZ ADMIN',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFD90429),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF121214),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  offset: const Offset(0, 48),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD90429), Color(0xFF8D021F)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AD',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          enabled: false,
                          value: 'phone',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_iphone_rounded,
                                size: 18,
                                color: Color(0xFF6C6F79),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                adminPhone,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF121214),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: Color(0xFFD90429),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFD90429),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (String value) async {
                    if (value == 'logout') {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      await authProvider.logout();
                      navigator.pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ONLY Total Drivers Stat Card (matching admin_mobile_screen.html)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E1E6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF121214).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL DRIVERS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA2A5AE),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    verificationProvider.isLoadingApprovedOnlineDrivers
                        ? '...'
                        : onlineDriverCount.toString(),
                    style: GoogleFonts.ibmPlexMono(
                      color: const Color(0xFF121214),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        size: 13,
                        color: Color(0xFF1C9A5B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online & Approved',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1C9A5B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Access Section
            Text(
              'QUICK ACCESS',
              style: GoogleFonts.outfit(
                color: const Color(0xFFA2A5AE),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.tune_rounded,
                    title: 'Vehicle Price\nConfig',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPricingScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Vehicle\nManagement',
                    onTap: () {
                      setState(() {
                        _currentIndex = 3;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet\nOperations',
                    onTap: () {
                      setState(() {
                        _currentIndex = 4;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'All\nBookings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAllBookingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Support\nTickets',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportTicketsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.people_outline_rounded,
                    title: 'All\nUsers',
                    onTap: () {
                      Navigator.pushNamed(context, '/admin_all_users');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pending Driver Requests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PENDING DRIVER REQUESTS',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA2A5AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  child: Text(
                    'View all',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD90429),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E1E6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF121214).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: verificationProvider.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFFD90429),
                        ),
                      ),
                    )
                  : pendingDrivers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No pending requests awaiting review',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C6F79),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Column(
                      children: pendingDrivers.take(3).map((
                        AdminDriverModel driver,
                      ) {
                        final isLast = pendingDrivers.take(3).last == driver;
                        final String createdAtStr = driver.createdAt;
                        final String formattedDate = createdAtStr.length >= 10
                            ? createdAtStr.substring(0, 10)
                            : 'Recent';
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE1E1E6),
                                      width: 0.8,
                                    ),
                                  ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF121214),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${driver.vehicle?.vehicleTypeName ?? driver.vehicleTypeName ?? 'Driver Application'} · $formattedDate',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF6C6F79),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex = 1;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE1E1E6),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Review',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF121214),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E1E6)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF121214).withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFFD90429)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF16171C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: PENDING REQUESTS TAB (now handled by RiderVerificationScreen)
}
