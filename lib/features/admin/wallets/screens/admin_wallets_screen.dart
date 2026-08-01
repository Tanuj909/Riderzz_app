import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/core/models/admin_wallet_model.dart';
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
      final provider = context.read<AdminWalletsProvider>();
      provider.fetchApprovedDrivers(isRefresh: true);
      provider.fetchWalletOverview();
      provider.fetchWallets(isRefresh: true);
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
      if (!provider.isWalletsLoading && !provider.isWalletsLoadMore && !provider.isWalletsLastPage) {
        provider.fetchWallets();
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
                Consumer<AdminWalletsProvider>(
                  builder: (context, provider, child) {
                    final overview = provider.overview;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     Text(
                              //       'TOTAL WALLET BALANCE',
                              //       style: GoogleFonts.outfit(
                              //         color: Colors.white.withValues(alpha: 0.6),
                              //         fontSize: 10,
                              //         fontWeight: FontWeight.w800,
                              //         letterSpacing: 0.5,
                              //       ),
                              //     ),
                              //     const SizedBox(height: 4),
                              //     Text(
                              //       '₹${overview?.totalBalance.toStringAsFixed(2) ?? '0.00'}',
                              //       style: GoogleFonts.outfit(
                              //         color: Colors.white,
                              //         fontSize: 22,
                              //         fontWeight: FontWeight.w800,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     Text(
                              //       'HOLD BALANCE',
                              //       style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                              //     ),
                              //     const SizedBox(height: 2),
                              //     Text(
                              //       '₹${overview?.totalHoldBalance.toStringAsFixed(2) ?? '0.00'}',
                              //       style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                              //     ),
                              //   ],
                              // ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACTIVE WALLETS',
                                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  TextButton.icon(
                                    onPressed: () => provider.fetchWalletOverview(),
                                    icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
                                    label: Text('Retry Fetch', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'PENDING PAYOUTS',
                                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${overview?.pendingWithdrawalCount ?? 0} Requests',
                                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
                  onRefresh: () async {
                    await provider.fetchApprovedDrivers(isRefresh: true);
                    await provider.fetchWalletOverview();
                    await provider.fetchWallets(isRefresh: true);
                  },
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
                      return _buildDriverWalletCard(driver, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

        ],
      ),
    );
  }

  Widget _buildDriverWalletCard(AdminDriverModel driver, AdminWalletsProvider provider) {
    final wallet = provider.wallets.firstWhere(
      (w) => w.walletId == driver.userId || w.walletId == driver.id,
      orElse: () => AdminWalletModel(
        walletId: 0,
        balance: 0.0,
        holdBalance: 0.0,
        availableBalance: 0.0,
        active: false,
        createdAt: '',
        updatedAt: '',
      ),
    );

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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Wallet Balance: ',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6C6F79),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${wallet.balance.toStringAsFixed(2)}',
                          style: GoogleFonts.ibmPlexMono(
                            color: wallet.balance >= 0 ? const Color(0xFF1C9A5B) : Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminWalletsProvider>();
      p.fetchDriverWallet(widget.driver.userId);
      p.fetchDriverTransactions(driverId: widget.driver.userId, isRefresh: true);
    });
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

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout & Transaction History',
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
              child: _buildWalletView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletView() {
    return Consumer<AdminWalletsProvider>(
      builder: (context, provider, child) {
        if (provider.isWalletLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final wallet = provider.selectedDriverWallet;
        if (wallet == null) {
          return Center(child: Text('No wallet data available.', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79))));
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
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white54, size: 20),
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transactions History List
            _buildSectionTitle('Transaction History'),
            const SizedBox(height: 8),
            if (provider.isTxLoading && provider.driverTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                  ),
                ),
              )
            else if (provider.driverTransactions.isEmpty)
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
                    style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 12),
                  ),
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.driverTransactions.length,
                itemBuilder: (context, index) {
                  final tx = provider.driverTransactions[index];
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tx.type,
                                    style: GoogleFonts.outfit(
                                      color: typeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${isRecharge ? '+' : '-'} ₹${tx.amount.abs().toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tx.remarks,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF121214),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(tx.createdAt),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (!provider.isTxLastPage) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => provider.fetchDriverTransactions(driverId: widget.driver.userId),
                    child: provider.isTxLoadMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429))),
                          )
                        : Text('Load More', style: GoogleFonts.outfit(color: const Color(0xFFD90429), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ]
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
}