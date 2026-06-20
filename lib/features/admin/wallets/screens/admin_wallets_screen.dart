import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // Search & Header Title Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Approved Drivers & Wallets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2233),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by driver name or phone...',
                    hintStyle: const TextStyle(color: Color(0xFF90A3BF), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF90A3BF), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF90A3BF), size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE9ECF0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1A3D6B)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3D6B)),
                            onPressed: () => provider.fetchApprovedDrivers(isRefresh: true),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
                                color: Color(0xFFE8F0FB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 44, color: Color(0xFF1A3D6B)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching drivers found'
                                  : 'No approved drivers found',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2233),
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
                  color: const Color(0xFF1A3D6B),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
    );
  }

  Widget _buildDriverWalletCard(AdminDriverModel driver) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+91 ${driver.phone}',
                        style: const TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: driver.isOnline ? const Color(0xFFEBFDF6) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: driver.isOnline ? const Color(0xFF0F9B6E) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driver.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: driver.isOnline ? const Color(0xFF0F9B6E) : const Color(0xFF64748B),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Color(0xFFE9ECF0)),
            ),

            // Performance/Trips/Rating info row
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                const SizedBox(width: 4),
                Text(
                  driver.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF1A2233),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.local_shipping_rounded, color: Color(0xFF1A3D6B), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${driver.totalTrips} Trips',
                  style: const TextStyle(
                    color: Color(0xFF1A2233),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.directions_car_rounded, color: Color(0xFF0F9B6E), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    driver.vehicle != null
                        ? '${driver.vehicle!.make} (${driver.vehicleNumber})'
                        : 'No vehicle',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A2233),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Button actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDriverDetailsBottomSheet(driver),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A3D6B), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF1A3D6B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDriverOperationsBottomSheet(driver),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3D6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Operations',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          backgroundColor: success ? const Color(0xFF0F9B6E) : Colors.redAccent,
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
          backgroundColor: success ? const Color(0xFF0F9B6E) : Colors.redAccent,
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
                color: const Color(0xFFE2E8F0),
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2233), size: 18),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2233),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.driver.name} • +91 ${widget.driver.phone}',
                        style: const TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE9ECF0)),

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
          iconColor: const Color(0xFF1A3D6B),
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
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9ECF0)),
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
                        const Text(
                          'Forced Offline Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDriverOnline ? 'Status: ONLINE' : 'Status: OFFLINE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDriverOnline ? const Color(0xFF0F9B6E) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1, color: Color(0xFFE9ECF0)),
              ),
              Text(
                isDriverOnline
                    ? 'Forcing the driver offline will stop them from receiving new ride bookings immediately. You should only use this if there is an issue with the driver or if they are in violation of platform rules.'
                    : 'The driver is currently offline. No action is required.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785), height: 1.4),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  'Error: ${provider.walletErrorMessage}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => provider.fetchDriverWallet(widget.driver.id),
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
                  label: const Text('Retry Fetch', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }

        final wallet = provider.selectedDriverWallet;
        if (wallet == null) {
          return const Center(child: Text('No wallet data available.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7785))));
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
                  colors: [Color(0xFF1A3D6B), Color(0xFF0F2D54)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A3D6B).withValues(alpha: 0.15),
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
                    children: const [
                      Text(
                        'CURRENT BALANCE',
                        style: TextStyle(
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
                    style: const TextStyle(
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
                          const Text(
                            'MIN REQUIRED',
                            style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${wallet.minBalanceRequired.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'LAST UPDATED',
                            style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            wallet.lastUpdated.isNotEmpty
                                ? _formatDate(wallet.lastUpdated)
                                : 'Never',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
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
                  border: Border.all(color: const Color(0xFFE9ECF0)),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedType == 'RECHARGE' ? const Color(0xFFEBFDF6) : const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == 'RECHARGE' ? const Color(0xFF0F9B6E) : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: _selectedType == 'RECHARGE' ? const Color(0xFF0F9B6E) : const Color(0xFF6B7785),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RECHARGE',
                                    style: TextStyle(
                                      color: _selectedType == 'RECHARGE' ? const Color(0xFF0F9B6E) : const Color(0xFF6B7785),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedType == 'DEBIT' ? const Color(0xFFFFECEC) : const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFF6B7785),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DEBIT',
                                    style: TextStyle(
                                      color: _selectedType == 'DEBIT' ? Colors.redAccent : const Color(0xFF6B7785),
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
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Adjustment Amount (₹)',
                        labelStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
                        hintText: 'Enter amount (e.g., 500)',
                        hintStyle: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 13),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFF1A3D6B)),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Reason / Description',
                        labelStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
                        hintText: 'Describe why balance is being adjusted',
                        hintStyle: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 13),
                        prefixIcon: const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF1A3D6B)),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'RECHARGE' ? const Color(0xFF0F9B6E) : Colors.redAccent,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 1,
                          shadowColor: (_selectedType == 'RECHARGE' ? const Color(0xFF0F9B6E) : Colors.redAccent).withValues(alpha: 0.2),
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
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECF0)),
                ),
                child: const Center(
                  child: Text(
                    'No transactions recorded yet.',
                    style: TextStyle(color: Color(0xFF6B7785), fontSize: 12),
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
                  final typeColor = isRecharge ? const Color(0xFF0F9B6E) : Colors.redAccent;
                  final typeBg = isRecharge ? const Color(0xFFEBFDF6) : const Color(0xFFFFECEC);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECF0)),
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
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${isRecharge ? '+' : '-'} ₹${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
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
                                style: const TextStyle(
                                  color: Color(0xFF1A2233),
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
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Closing: ₹${tx.closingBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7785),
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
      style: const TextStyle(
        color: Color(0xFF1A2233),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 10, color: const Color(0xFFE2E8F0)),
              Container(width: 20, height: 20, color: const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: 140, height: 24, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 60, height: 12, color: const Color(0xFFE2E8F0)),
              Container(width: 80, height: 12, color: const Color(0xFFE2E8F0)),
            ],
          ),
        ],
      ),
    );
  }
}
