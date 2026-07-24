import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/features/admin/rider_verification/rider_verification_screen.dart';
import 'package:riderzz_app/features/admin/wallets/providers/admin_wallets_provider.dart';

class AdminWalletsScreen extends StatefulWidget {
  const AdminWalletsScreen({super.key});

  @override
  State<AdminWalletsScreen> createState() => _AdminWalletsScreenState();
}

class _AdminWalletsScreenState extends State<AdminWalletsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminWalletsProvider>().fetchApprovedDrivers(isRefresh: true);
    });

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AdminWalletsProvider>();
      if (!provider.isLoading && !provider.isLoadMore && !provider.isLastPage) {
        provider.fetchApprovedDrivers();
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _showDriverDetailsBottomSheet(AdminDriverModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverDetailsBottomSheet(driver: driver),
    );
  }

  void _showDriverOperationsBottomSheet(AdminDriverModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverOperationsBottomSheet(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Stack(
        children: [
          // Underlying Wallets Screen Content
          Column(
            children: [
          // Header & Search Bar matching admin_mobile_screen.html
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FINANCE',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFD90429),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wallet Operations',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF121214),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Wallet Hero Card matching admin_mobile_screen.html
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF121214), Color(0xFF2B2C31)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF121214).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Platform Revenue',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹8,42,650.00',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD90429),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bank settlement initiated successfully')),
                            );
                          },
                          child: Text(
                            'Settle to Bank',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search bar input-wrap style
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE1E1E6)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search by driver name or phone...',
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFFA2A5AE), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA2A5AE), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFFA2A5AE), size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content list
          Expanded(
            child: Consumer<AdminWalletsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.approvedDrivers.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.approvedDrivers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD90429)),
                            onPressed: () => provider.fetchApprovedDrivers(isRefresh: true),
                            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter drivers locally by search query
                final query = _searchQuery.toLowerCase().trim();
                final List<AdminDriverModel> filteredDrivers = provider.approvedDrivers.where((d) {
                  return d.name.toLowerCase().contains(query) || d.phone.contains(query);
                }).toList();

                if (filteredDrivers.isEmpty) {
                  return ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEDF0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 44, color: Color(0xFFD90429)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching drivers found'
                                  : 'No approved drivers found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchApprovedDrivers(isRefresh: true),
                  color: const Color(0xFFD90429),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: filteredDrivers.length + (provider.isLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredDrivers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                              ),
                            ),
                          ),
                        );
                      }

                      final driver = filteredDrivers[index];
                      return _buildDriverWalletCard(driver);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Blurred Overlay with "Under Progress" Message
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: const Color(0xFF121214).withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEDF0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.construction_rounded,
                            size: 40,
                            color: Color(0xFFD90429),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD90429),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'UNDER PROGRESS',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Feature Under Development',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wallet operations and driver payout features are currently being built and will be available soon.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF6C6F79),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverWalletCard(AdminDriverModel driver) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E1E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121214).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Driver Name + Online Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF121214),
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+91 ${driver.phone} · ${driver.rating.toStringAsFixed(1)} ★ · ${driver.totalTrips} Trips',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6C6F79),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: driver.isOnline ? const Color(0xFFE7F7EF) : const Color(0xFFF1F1F4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: driver.isOnline ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driver.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: GoogleFonts.outfit(
                        color: driver.isOnline ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (driver.vehicle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE1E1E6)),
              ),
              child: Text(
                'Vehicle: ${driver.vehicle!.make} ${driver.vehicle!.model} (${driver.vehicleNumber})',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF16171C),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons row (btn btn-outline btn-sm btn-block style)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDriverDetailsBottomSheet(driver),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFE1E1E6), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF121214),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showDriverOperationsBottomSheet(driver),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Operations & Payout',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// DRIVER OPERATIONS AND WALLET MANAGEMENT BOTTOM SHEET (PREMIUM DESIGN)
class DriverOperationsBottomSheet extends StatefulWidget {
  final AdminDriverModel driver;

  const DriverOperationsBottomSheet({super.key, required this.driver});

  @override
  State<DriverOperationsBottomSheet> createState() => _DriverOperationsBottomSheetState();
}

class _DriverOperationsBottomSheetState extends State<DriverOperationsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Navigation View State: MENU, AVAILABILITY, WALLET
  String _currentView = 'MENU';
  
  String _selectedType = 'RECHARGE';
  bool _isForceOfflineLoading = false;
  bool _isAdjusting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminWalletsProvider>().fetchDriverWallet(widget.driver.id);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final year = dt.year;
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final hourNum = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hourNum:$minute $ampm';
    } catch (e) {
      return isoString;
    }
  }

  void _handleForceOffline() async {
    setState(() {
      _isForceOfflineLoading = true;
    });

    final success = await context.read<AdminWalletsProvider>().forceDriverOffline(widget.driver.id);

    if (mounted) {
      setState(() {
        _isForceOfflineLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Driver forced offline successfully' : 'Failed to force driver offline',
          ),
          backgroundColor: success ? const Color(0xFF1C9A5B) : Colors.redAccent,
        ),
      );

      if (success) {
        Navigator.pop(context); // Close operations sheet to refresh statuses
      }
    }
  }

  void _handleWalletAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than zero'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isAdjusting = true;
    });

    final success = await context.read<AdminWalletsProvider>().adjustDriverWallet(
          driverId: widget.driver.id,
          type: _selectedType,
          amount: amt,
          description: _descriptionController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isAdjusting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Wallet adjusted successfully' : 'Failed to adjust wallet',
          ),
          backgroundColor: success ? const Color(0xFF1C9A5B) : Colors.redAccent,
        ),
      );

      if (success) {
        _amountController.clear();
        _descriptionController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriverOnline = widget.driver.isOnline;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                if (_currentView != 'MENU')
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 18),
                    onPressed: () {
                      setState(() {
                        _currentView = 'MENU';
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_currentView != 'MENU') const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentView == 'MENU'
                            ? 'Driver Operations'
                            : (_currentView == 'AVAILABILITY' ? 'Availability Control' : 'Manage Wallet'),
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121214),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.driver.name} • +91 ${widget.driver.phone}',
                        style: GoogleFonts.outfit(
                          color: Color(0xFF6C6F79),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE7E7EB)),

          // Content Area (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _buildCurrentViewContent(isDriverOnline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewContent(bool isDriverOnline) {
    switch (_currentView) {
      case 'MENU':
        return _buildMenuView();
      case 'AVAILABILITY':
        return _buildAvailabilityView(isDriverOnline);
      case 'WALLET':
        return _buildWalletView();
      default:
        return _buildMenuView();
    }
  }

  Widget _buildMenuView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuOption(
          title: 'Availability Control',
          subtitle: 'Force driver offline',
          icon: Icons.power_settings_new_rounded,
          iconBgColor: const Color(0xFFFFECEC),
          iconColor: Colors.redAccent,
          onTap: () {
            setState(() {
              _currentView = 'AVAILABILITY';
            });
          },
        ),
        const SizedBox(height: 12),
        _buildMenuOption(
          title: 'Manage Wallet',
          subtitle: 'Recharge, debit, or view transactions',
          icon: Icons.account_balance_wallet_rounded,
          iconBgColor: const Color(0xFFEBF3FD),
          iconColor: const Color(0xFFE31C2E),
          onTap: () {
            setState(() {
              _currentView = 'WALLET';
            });
          },
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E7EB)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Color(0xFF121214),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: Color(0xFF6C6F79),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8C4)),
      ),
    );
  }

  Widget _buildAvailabilityView(bool isDriverOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forced Offline Status',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDriverOnline ? 'Status: ONLINE' : 'Status: OFFLINE',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDriverOnline ? const Color(0xFF1C9A5B) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1, color: Color(0xFFE7E7EB)),
              ),
              Text(
                isDriverOnline
                    ? 'Forcing the driver offline will stop them from receiving new ride bookings immediately. You should only use this if there is an issue with the driver or if they are in violation of platform rules.'
                    : 'The driver is currently offline. No action is required.',
                style: GoogleFonts.outfit(fontSize: 12, color: Color(0xFF6C6F79), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isDriverOnline && !_isForceOfflineLoading) ? _handleForceOffline : null,
                  icon: _isForceOfflineLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.power_settings_new_rounded, size: 16),
                  label: Text(
                    isDriverOnline ? 'Force Driver Offline' : 'Driver Already Offline',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: const Color(0xFFE7E7EB),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletView() {
    return Consumer<AdminWalletsProvider>(
      builder: (context, provider, child) {
        if (provider.isWalletLoading) {
          return _buildShimmerWalletLoader();
        }

        if (provider.walletErrorMessage != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  'Error: ${provider.walletErrorMessage}',
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => provider.fetchDriverWallet(widget.driver.id),
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
                  label: Text('Retry Fetch', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }

        final wallet = provider.selectedDriverWallet;
        if (wallet == null) {
          return Center(child: Text('No wallet data available.', style: GoogleFonts.outfit(fontSize: 12, color: Color(0xFF6C6F79))));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Display card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE31C2E), Color(0xFF0F2D54)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE31C2E).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT BALANCE',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.white54, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${wallet.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MIN REQUIRED',
                            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${wallet.minBalanceRequired.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LAST UPDATED',
                            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            wallet.lastUpdated.isNotEmpty
                                ? _formatDate(wallet.lastUpdated)
                                : 'Never',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Balance Adjustment Form
            _buildSectionTitle('Adjust Wallet Balance'),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Custom Toggle Buttons (replacing old choice chips)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = 'RECHARGE'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedType == 'RECHARGE' ? const Color(0xFFEBFDF6) : const Color(0xFFF6F6F8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedType == 'RECHARGE' ? const Color(0xFF1C9A5B) : const Color(0xFFE7E7EB),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: _selectedType == 'RECHARGE' ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RECHARGE',
                                    style: GoogleFonts.outfit(
                                      color: _selectedType == 'RECHARGE' ? const Color(0xFF1C9A5B) : const Color(0xFF6C6F79),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = 'DEBIT'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedType == 'DEBIT' ? const Color(0xFFFFECEC) : const Color(0xFFF6F6F8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFFE7E7EB),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFF6C6F79),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DEBIT',
                                    style: GoogleFonts.outfit(
                                      color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFF6C6F79),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount Input field (premium input decoration)
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Adjustment Amount (₹)',
                        labelStyle: GoogleFonts.outfit(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
                        hintText: 'Enter amount (e.g., 500)',
                        hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFFE31C2E)),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFE7E7EB), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description input field (premium input decoration)
                    TextFormField(
                      controller: _descriptionController,
                      style: GoogleFonts.outfit(color: Color(0xFF121214), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Reason / Description',
                        labelStyle: GoogleFonts.outfit(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
                        hintText: 'Describe why balance is being adjusted',
                        hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
                        prefixIcon: const Icon(Icons.notes_rounded, size: 16, color: Color(0xFFE31C2E)),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFE7E7EB), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Submit button with elevated shadow
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAdjusting ? null : _handleWalletAdjustment,
                        icon: _isAdjusting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                _selectedType == 'RECHARGE'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.remove_circle_outline_rounded,
                                size: 16,
                              ),
                        label: Text(
                          _selectedType == 'RECHARGE'
                              ? 'Apply Recharge Balance'
                              : 'Debit Penalty Balance',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'RECHARGE' ? const Color(0xFF1C9A5B) : Colors.redAccent,
                          disabledBackgroundColor: const Color(0xFFE7E7EB),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 1,
                          shadowColor: (_selectedType == 'RECHARGE' ? const Color(0xFF1C9A5B) : Colors.redAccent).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Transactions History List
            _buildSectionTitle('Transaction History'),
            const SizedBox(height: 8),
            if (wallet.transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E7EB)),
                ),
                child: Center(
                  child: Text(
                    'No transactions recorded yet.',
                    style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 12),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wallet.transactions.length,
                itemBuilder: (context, index) {
                  // Access transactions in reverse chronological order to show the latest first
                  final tx = wallet.transactions[wallet.transactions.length - 1 - index];
                  final isRecharge = tx.type == 'RECHARGE' || tx.type == 'CREDIT';
                  final typeColor = isRecharge ? const Color(0xFF1C9A5B) : Colors.redAccent;
                  final typeBg = isRecharge ? const Color(0xFFEBFDF6) : const Color(0xFFFFECEC);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicator Icon Circle
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: typeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRecharge ? Icons.add_rounded : Icons.remove_rounded,
                            color: typeColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx.type,
                                      style: GoogleFonts.outfit(
                                        color: typeColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${isRecharge ? '+' : '-'} ₹${tx.amount.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tx.description,
                                style: GoogleFonts.outfit(
                                  color: Color(0xFF121214),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(tx.createdAt),
                                    style: GoogleFonts.outfit(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Closing: ₹${tx.closingBalance.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      color: Color(0xFF6C6F79),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Color(0xFF121214),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildShimmerWalletLoader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 10, color: const Color(0xFFE7E7EB)),
              Container(width: 20, height: 20, color: const Color(0xFFE7E7EB)),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: 140, height: 24, color: const Color(0xFFE7E7EB)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 60, height: 12, color: const Color(0xFFE7E7EB)),
              Container(width: 80, height: 12, color: const Color(0xFFE7E7EB)),
            ],
          ),
        ],
      ),
    );
  }
}