import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/features/admin/rider_verification/providers/rider_verification_provider.dart';

class RiderVerificationScreen extends StatefulWidget {
  const RiderVerificationScreen({super.key});

  @override
  State<RiderVerificationScreen> createState() => _RiderVerificationScreenState();
}

class _RiderVerificationScreenState extends State<RiderVerificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
    'SUSPENDED',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderVerificationProvider>().fetchDrivers(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<RiderVerificationProvider>();
      if (!provider.isLoading && !provider.isLoadMore && !provider.isLastPage) {
        provider.fetchDrivers();
      }
    }
  }

  void _showDriverDetailsBottomSheet(AdminDriverModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverDetailsBottomSheet(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Consumer<RiderVerificationProvider>(
        builder: (context, provider, child) {
          final driversList = provider.drivers.where((driver) {
            if (_searchQuery.isEmpty) return true;
            final nameMatch = driver.name.toLowerCase().contains(_searchQuery);
            final phoneMatch = driver.phone.toLowerCase().contains(_searchQuery);
            final idMatch = driver.id.toString().contains(_searchQuery) ||
                driver.userId.toString().contains(_searchQuery);
            final vehicleMatch = (driver.vehicle != null &&
                    '${driver.vehicle!.make} ${driver.vehicle!.model} ${driver.vehicleNumber}'
                        .toLowerCase()
                        .contains(_searchQuery)) ||
                (driver.vehicleTypeName != null &&
                    driver.vehicleTypeName!.toLowerCase().contains(_searchQuery));
            return nameMatch || phoneMatch || idMatch || vehicleMatch;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header Title Layout matching admin_mobile_screen.html
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLEET & ONBOARDING',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFD90429),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drivers Directory',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF121214),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar matching input-wrap design in HTML
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFFA2A5AE), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by name or driver ID...',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFF6C6F79),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79), size: 18),
                        ),
                    ],
                  ),
                ),
              ),

              // Filter Status Chips Row matching chip-row design in HTML
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = provider.currentStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => provider.setStatusFilter(status),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFD90429) : const Color(0xFFF1F1F4),
                            borderRadius: BorderRadius.circular(999),
                            border: isSelected ? null : Border.all(color: const Color(0xFFE1E1E6)),
                          ),
                          child: Text(
                            status == 'ALL' ? 'All Drivers' : status.replaceFirst('_', ' '),
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : const Color(0xFF6C6F79),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Driver List Container
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchDrivers(isRefresh: true),
                  color: const Color(0xFFD90429),
                  child: provider.isLoading && provider.drivers.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                          ),
                        )
                      : provider.errorMessage != null && provider.drivers.isEmpty
                          ? Center(
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
                                      onPressed: () => provider.fetchDrivers(isRefresh: true),
                                      child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : driversList.isEmpty
                              ? ListView(
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
                                            child: const Icon(Icons.assignment_ind_rounded, size: 44, color: Color(0xFFD90429)),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Drivers Found',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF121214),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No matching drivers for "$_searchQuery"'
                                                : 'No drivers found under ${provider.currentStatusFilter} status',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: const Color(0xFF6C6F79),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                                  itemCount: driversList.length + (provider.isLoadMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == driversList.length) {
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

                                    final driver = driversList[index];
                                    return _buildDriverCard(driver);
                                  },
                                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(AdminDriverModel driver) {
    final String status = driver.approvalStatus.toUpperCase();

    Color badgeBg;
    Color badgeText;
    if (status == 'APPROVED' || status == 'ACTIVE') {
      badgeBg = const Color(0xFFE7F7EF);
      badgeText = const Color(0xFF1C9A5B);
    } else if (status == 'PENDING') {
      badgeBg = const Color(0xFFFCF0DC);
      badgeText = const Color(0xFFB9700A);
    } else if (status == 'REJECTED') {
      badgeBg = const Color(0xFFFDEBEC);
      badgeText = const Color(0xFFE31C2E);
    } else {
      badgeBg = const Color(0xFFF1F1F4);
      badgeText = const Color(0xFF6C6F79);
    }

    final String driverIdDisplay = 'DRV-${driver.userId}';

    final String vehicleInfo = driver.vehicle != null
        ? '${driver.vehicle!.make} ${driver.vehicle!.model}'
        : (driver.vehicleTypeName ?? 'Vehicle Info');

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
          // Top Header Row: Name & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  driver.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF121214),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  driver.approvalStatus,
                  style: GoogleFonts.outfit(
                    color: badgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Details subtitle (ID · Vehicle · Rating ★)
          Text(
            '$driverIdDisplay · $vehicleInfo · ${driver.rating.toStringAsFixed(1)} ★',
            style: GoogleFonts.outfit(
              color: const Color(0xFF6C6F79),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Action Button matching HTML (btn btn-outline btn-sm btn-block)
          SizedBox(
            width: double.infinity,
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
                status == 'PENDING'
                    ? 'Review Application'
                    : 'Manage Driver Profile',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF121214),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DRIVER DETAILS BOTTOM SHEET (PREMIUM DESIGN)
class DriverDetailsBottomSheet extends StatefulWidget {
  final AdminDriverModel driver;

  const DriverDetailsBottomSheet({super.key, required this.driver});

  @override
  State<DriverDetailsBottomSheet> createState() => _DriverDetailsBottomSheetState();
}

class _DriverDetailsBottomSheetState extends State<DriverDetailsBottomSheet> {
  bool _isUpdating = false;
  bool _isLoadingDetails = true;
  AdminDriverModel? _fullDriver;

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    final provider = context.read<RiderVerificationProvider>();
    final result = await provider.fetchDriverById(widget.driver.userId);
    if (mounted) {
      setState(() {
        _fullDriver = result;
        _isLoadingDetails = false;
      });
    }
  }

  void _showDocumentViewerDialog(AdminDriverModel currentDriver, AdminDriverDocumentModel doc) async {
    await showDialog(
      context: context,
      builder: (context) => DocumentViewerDialog(
        driver: currentDriver,
        document: doc,
      ),
    );
    _fetchFullDetails();
  }

  void _showEditDriverDialog(AdminDriverModel driver) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return EditDriverDialog(
          driver: driver,
          onSaved: (updated) {
            if (mounted) {
              setState(() {
                _fullDriver = updated;
              });
            }
          },
        );
      },
    );
  }

  void _updateStatus(String targetStatus) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => UpdateStatusConfirmationDialog(
        targetStatus: targetStatus,
        driverName: widget.driver.name,
      ),
    );

    if (result == null) return;

    if (!mounted) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<RiderVerificationProvider>();
    final success = await provider.updateDriverStatus(
      widget.driver.id,
      targetStatus,
      rejectionReason: result.isNotEmpty ? result : null,
    );

    setState(() {
      _isUpdating = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver status updated to $targetStatus successfully!')),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }
  }

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFF1C9A5B);
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return const Color(0xFF0284C7);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiderVerificationProvider>(
      builder: (context, provider, child) {
        final driver = _fullDriver ?? provider.drivers.firstWhere(
          (d) => d.id == widget.driver.id || d.userId == widget.driver.userId,
          orElse: () => widget.driver,
        );

        const List<String> allRequiredDocTypes = [
          'AADHAAR_FRONT',
          'AADHAAR_BACK',
          'PAN_CARD',
          'DRIVING_LICENSE_FRONT',
          'DRIVING_LICENSE_BACK',
          'RC_BOOK',
          'INSURANCE',
        ];

        final uploadedDocTypes = driver.documents.map((doc) => doc.docType).toSet();
        final hasAllDocs = allRequiredDocTypes.every((type) => uploadedDocTypes.contains(type));
        final allApproved = driver.documents.isNotEmpty && driver.documents.every((doc) => doc.status == 'APPROVED');
        final canApprove = hasAllDocs && allApproved;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: _isLoadingDetails
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pull Indicator
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E7EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.name,
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone: +91 ${driver.phone}${driver.email != null ? ' • ${driver.email}' : ''}',
                                    style: GoogleFonts.outfit(fontSize: 12, color: Color(0xFF6C6F79)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (driver.vehicleTypeName != null && driver.vehicleTypeName!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDEBEC),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE31C2E).withValues(alpha: 0.15)),
                                    ),
                                    child: Text(
                                      driver.vehicleTypeName!,
                                      style: GoogleFonts.outfit(
                                        color: Color(0xFFE31C2E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () => _showEditDriverDialog(driver),
                                  icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFE31C2E)),
                                  label: Text('Edit Info', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE31C2E))),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Personal Information Section
                        Text('Personal Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121214))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE7E7EB)),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('Approval Status', driver.approvalStatus),
                              if (driver.gender != null) _buildInfoRow('Gender', driver.gender!),
                              if (driver.dob != null) _buildInfoRow('Date of Birth', driver.dob!),
                              if (driver.bio != null && driver.bio!.isNotEmpty) _buildInfoRow('Bio', driver.bio!),
                              _buildInfoRow('Rating', '${driver.rating.toStringAsFixed(1)} ⭐'),
                              _buildInfoRow('Completed Trips', driver.totalTrips.toString()),
                              _buildInfoRow('Online', driver.isOnline ? 'Yes' : 'No'),
                              if (driver.approvedAt != null) _buildInfoRow('Approved At', driver.approvedAt!),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vehicle Information Section
                        Text('Vehicle Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121214))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE7E7EB)),
                          ),
                          child: Column(
                            children: [
                              if (driver.vehicleTypeName != null) _buildInfoRow('Vehicle Type', driver.vehicleTypeName!),
                              _buildInfoRow('Registration Number', driver.vehicleNumber),
                              if (driver.color != null) _buildInfoRow('Color', driver.color!),
                              if (driver.manufacturingYear != null) _buildInfoRow('Manufacturing Year', driver.manufacturingYear.toString()),
                              if (driver.vehicleStatus != null) _buildInfoRow('Vehicle Status', driver.vehicleStatus!),
                              _buildInfoRow('License Number', driver.licenseNumber),
                              if (driver.licenseExpiry != null) _buildInfoRow('License Expiry', driver.licenseExpiry!),
                              if (driver.insuranceExpiry != null) _buildInfoRow('Insurance Expiry', driver.insuranceExpiry!),
                              if (driver.vehicle != null) ...[
                                _buildInfoRow('Make & Model', '${driver.vehicle!.make} ${driver.vehicle!.model}'),
                                _buildInfoRow('Max Weight', '${driver.vehicle!.maxWeightKg} kg'),
                                _buildInfoRow('Rate/Km', '₹${driver.vehicle!.perKmRate.toStringAsFixed(0)}'),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Documents Verification list
                        Text(
                          'Verification Documents (${driver.documents.length})',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121214)),
                        ),
                        const SizedBox(height: 8),
                        if (driver.documents.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE7E7EB)),
                            ),
                            child: Center(
                              child: Text(
                                'No documents uploaded yet.',
                                style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...driver.documents.map((doc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE7E7EB)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.description_outlined, color: Color(0xFFE31C2E), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc.docType.replaceAll('_', ' '),
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                doc.status,
                                                style: GoogleFonts.outfit(color: _getDocStatusColor(doc.status), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              if (doc.rejectionReason != null && doc.rejectionReason!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Reason: ${doc.rejectionReason}',
                                                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 10),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFDEBEC),
                                      foregroundColor: const Color(0xFFE31C2E),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                    ),
                                    icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                                    label: Text('View', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _showDocumentViewerDialog(driver, doc),
                                  ),
                                ],
                              ),
                            );
                          }),

                        // Show missing documents
                        ...allRequiredDocTypes.where((type) => !uploadedDocTypes.contains(type)).map((docType) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE7E7EB)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFF6C6F79), size: 20),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          docType.replaceAll('_', ' '),
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6C6F79)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Not Uploaded',
                                          style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1F4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Missing',
                                    style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Update Status Actions Panel
                        if (_isUpdating)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E))),
                            ),
                          )
                        else if (driver.approvalStatus == 'REJECTED')
                          const SizedBox.shrink()
                        else if (driver.approvalStatus == 'SUSPENDED')
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F1F4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE7E7EB)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6C6F79)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Driver is currently suspended. You can activate this driver below.',
                                        style: GoogleFonts.outfit(
                                          color: Color(0xFF4A5568),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1C9A5B),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _updateStatus('ACTIVATED'),
                                      child: Text('Activate Driver', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              if (driver.approvalStatus != 'APPROVED') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1C9A5B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _updateStatus('APPROVED'),
                                        child: Text('Approve Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _updateStatus('REJECTED'),
                                      child: Text('Reject Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                              if (driver.approvalStatus == 'APPROVED') ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6C6F79),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _updateStatus('SUSPENDED'),
                                        child: Text('Suspend Driver', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}


class DocumentViewerDialog extends StatefulWidget {
  final AdminDriverModel driver;
  final AdminDriverDocumentModel document;

  const DocumentViewerDialog({
    super.key,
    required this.driver,
    required this.document,
  });

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _showRejectInput = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load document image',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFF1C9A5B);
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _getDocStatusColorBg(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFFEBFDF6);
      case 'REJECTED':
        return const Color(0xFFFFF0F0);
      default:
        return const Color(0xFFFFF7E6);
    }
  }

  IconData _getDocStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle_outline_rounded;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _getFormattedDocNo(String docType) {
    final idStr = widget.driver.id.toString().padLeft(4, '0');
    if (docType.startsWith('AADHAAR')) {
      return '5321 8842 $idStr';
    } else if (docType == 'PAN_CARD' || docType == 'PAN') {
      return 'BJKPD${idStr}G';
    } else if (docType.startsWith('DRIVING_LICENSE')) {
      return 'DL-132026$idStr';
    } else if (docType == 'RC_BOOK') {
      return 'RC-DL-3C-$idStr';
    } else if (docType == 'INSURANCE') {
      return 'INS-992384-${widget.driver.id.toString().padLeft(2, '0')}';
    } else {
      return 'DOC-ID-$idStr';
    }
  }

  Widget _buildCardGraphic(String docType, String docStatus) {
    late Gradient cardGradient;
    late String cardTitle;
    late String cardLabel;
    late IconData cardIcon;

    if (docType.startsWith('AADHAAR')) {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = docType.replaceAll('_', ' ');
      cardLabel = 'Govt. of India • UIDAI';
      cardIcon = Icons.fingerprint_rounded;
    } else if (docType == 'PAN_CARD' || docType == 'PAN') {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = 'PAN CARD';
      cardLabel = 'Income Tax Department';
      cardIcon = Icons.account_balance_wallet_rounded;
    } else if (docType.startsWith('DRIVING_LICENSE')) {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF8A2387), Color(0xFFE94057)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = docType.replaceAll('_', ' ');
      cardLabel = 'Ministry of Road Transport & Highways';
      cardIcon = Icons.directions_car_rounded;
    } else if (docType == 'RC_BOOK') {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = 'REGISTRATION CERTIFICATE';
      cardLabel = 'Vehicle Registration Department';
      cardIcon = Icons.two_wheeler_rounded;
    } else if (docType == 'INSURANCE') {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF141E30), Color(0xFF243B55)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = 'VEHICLE INSURANCE';
      cardLabel = 'Motor Policy Certificate';
      cardIcon = Icons.verified_user_rounded;
    } else {
      cardGradient = const LinearGradient(
        colors: [Color(0xFFE31C2E), Color(0xFF1D5A9C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cardTitle = 'DOCUMENT';
      cardLabel = 'Verification Source';
      cardIcon = Icons.description_rounded;
    }

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardTitle,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardLabel,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      cardIcon,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 24,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: CustomPaint(
                        painter: ChipPatternPainter(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driver.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getFormattedDocNo(docType),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDocStatusColorBg(docStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getDocStatusIcon(docStatus),
                            color: _getDocStatusColor(docStatus),
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            docStatus,
                            style: GoogleFonts.outfit(
                              color: _getDocStatusColor(docStatus),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'RIDERZZ VERIFIED',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerify(String status) async {
    String? reason;
    if (status == 'REJECTED') {
      if (!_showRejectInput) {
        setState(() {
          _showRejectInput = true;
        });
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
      reason = _reasonController.text.trim();
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<RiderVerificationProvider>();
    final success = await provider.verifyDriverDocument(
      widget.driver.id,
      widget.document.id,
      status,
      rejectionReason: reason,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document ${widget.document.docType.replaceAll('_', ' ')} status updated to $status successfully!',
            ),
            backgroundColor: status == 'APPROVED' ? const Color(0xFF1C9A5B) : Colors.redAccent,
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docType = widget.document.docType;
    final fileUrl = widget.document.fileUrl;
    
    return Consumer<RiderVerificationProvider>(
      builder: (context, provider, child) {
        final currentDriver = provider.drivers.firstWhere(
          (d) => d.id == widget.driver.id,
          orElse: () => widget.driver,
        );
        final currentDoc = currentDriver.documents.firstWhere(
          (doc) => doc.id == widget.document.id,
          orElse: () => widget.document,
        );
        final docStatus = currentDoc.status;
        final rejectionReason = currentDoc.rejectionReason;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                docType.replaceAll('_', ' '),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF121214),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79), size: 20),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: fileUrl.isNotEmpty
                      ? () => _showFullScreenImage(context, fileUrl, docType.replaceAll('_', ' '))
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: fileUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  fileUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildCardGraphic(docType, docStatus);
                                  },
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.zoom_in_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to zoom',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildCardGraphic(docType, docStatus),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (docStatus == 'REJECTED' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Rejection Reason',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rejectionReason,
                          style: GoogleFonts.outfit(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_showRejectInput) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Reason for Rejection',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _reasonController,
                          autofocus: true,
                          style: GoogleFonts.outfit(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g., Document image is blurry',
                            hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF6F6F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a reason';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                  ),
                ),
              )
            else if (_showRejectInput) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C6F79),
                        side: const BorderSide(color: Color(0xFFE7E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showRejectInput = false;
                          _reasonController.clear();
                        });
                      },
                      child: Text('Back', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _handleVerify('REJECTED'),
                      child: Text('Confirm Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  if (docStatus != 'APPROVED') ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C9A5B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _handleVerify('APPROVED'),
                        child: Text('Approve', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (docStatus != 'REJECTED') ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _showRejectInput = true;
                          });
                        },
                        child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE31C2E),
                        side: const BorderSide(color: Color(0xFFE31C2E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class ChipPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// PREMIUM STATUS CONFIRMATION DIALOG
class UpdateStatusConfirmationDialog extends StatefulWidget {
  final String targetStatus;
  final String driverName;

  const UpdateStatusConfirmationDialog({
    super.key,
    required this.targetStatus,
    required this.driverName,
  });

  @override
  State<UpdateStatusConfirmationDialog> createState() => _UpdateStatusConfirmationDialogState();
}

class _UpdateStatusConfirmationDialogState extends State<UpdateStatusConfirmationDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Border? border,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: backgroundColor != Colors.transparent
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.targetStatus;
    
    // Status-specific themes
    late Color themeColor;
    late IconData iconData;
    late String title;
    late String actionText;
    late Widget subtitleWidget;

    if (status == 'APPROVED') {
      themeColor = const Color(0xFF1C9A5B); // Green
      iconData = Icons.verified_user_rounded;
      title = 'Approve Application';
      actionText = 'Approve';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            TextSpan(
              text: 'approve ',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1C9A5B)),
            ),
            TextSpan(
              text: widget.driverName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '\'s application? This will immediately activate their profile as a driver.'),
          ],
        ),
      );
    } else if (status == 'ACTIVATED') {
      themeColor = const Color(0xFF1C9A5B); // Green
      iconData = Icons.verified_user_rounded;
      title = 'Activate Driver';
      actionText = 'Activate';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            TextSpan(
              text: 'activate ',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1C9A5B)),
            ),
            TextSpan(
              text: widget.driverName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '? This will restore their active status on the platform.'),
          ],
        ),
      );
    } else if (status == 'REJECTED') {
      themeColor = const Color(0xFFDC2626); // Red
      iconData = Icons.gavel_rounded;
      title = 'Reject Application';
      actionText = 'Reject';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            TextSpan(
              text: 'reject ',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
            TextSpan(
              text: widget.driverName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '\'s application? Please specify a clear reason for the rejection below.'),
          ],
        ),
      );
    } else {
      themeColor = const Color(0xFF6C6F79); // Grey for suspended
      iconData = Icons.block_flipped;
      title = 'Suspend Driver';
      actionText = 'Suspend';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            TextSpan(
              text: 'suspend ',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF6C6F79)),
            ),
            TextSpan(
              text: widget.driverName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '? They will no longer be able to accept rides on the platform.'),
          ],
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium double-ring header icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Rich Text Subtitle
                subtitleWidget,
                const SizedBox(height: 20),
                
                // Custom text input for rejection reason
                if (status == 'REJECTED') ...[
                  TextFormField(
                    controller: _reasonController,
                    autofocus: true,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontSize: 13, color: Color(0xFF1A202C)),
                    decoration: InputDecoration(
                      hintText: 'e.g., Document image is too blurry or license is expired.',
                      hintStyle: GoogleFonts.outfit(color: Color(0xFFA0AEC0), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Rejection reason is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action Buttons (Outlined/Material-based)
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: 'Cancel',
                        backgroundColor: Colors.transparent,
                        textColor: const Color(0xFF4A5568),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildButton(
                        text: actionText,
                        backgroundColor: themeColor,
                        textColor: Colors.white,
                        onTap: () {
                          if (status == 'REJECTED') {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, _reasonController.text.trim());
                            }
                          } else {
                            Navigator.pop(context, '');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditDriverDialog extends StatefulWidget {
  final AdminDriverModel driver;
  final ValueChanged<AdminDriverModel> onSaved;

  const EditDriverDialog({super.key, required this.driver, required this.onSaved});

  @override
  State<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseNoController;
  late final TextEditingController _licenseExpiryController;
  late final TextEditingController _insuranceExpiryController;
  late final TextEditingController _bioController;
  late final TextEditingController _dobController;
  late final TextEditingController _registrationNumberController;
  late final TextEditingController _colorController;
  late final TextEditingController _mfgYearController;

  String? _gender;
  String? _vehicleStatus;
  bool _online = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _licenseNoController = TextEditingController(text: widget.driver.licenseNumber);
    _licenseExpiryController = TextEditingController(text: widget.driver.licenseExpiry);
    _insuranceExpiryController = TextEditingController(text: widget.driver.insuranceExpiry);
    _bioController = TextEditingController(text: widget.driver.bio);
    _dobController = TextEditingController(text: widget.driver.dob);
    _registrationNumberController = TextEditingController(text: widget.driver.vehicleNumber);
    _colorController = TextEditingController(text: widget.driver.color);
    _mfgYearController = TextEditingController(text: widget.driver.manufacturingYear?.toString());

    _gender = widget.driver.gender;
    _vehicleStatus = widget.driver.vehicleStatus ?? 'PENDING';
    _online = widget.driver.isOnline;
  }

  @override
  void dispose() {
    _licenseNoController.dispose();
    _licenseExpiryController.dispose();
    _insuranceExpiryController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _registrationNumberController.dispose();
    _colorController.dispose();
    _mfgYearController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text);
      } catch (_) {}
    }
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE31C2E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF121214),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() {
        controller.text = selected.toIso8601String().split('T')[0];
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final updateData = {
      'licenseNumber': _licenseNoController.text.trim(),
      'licenseExpiry': _licenseExpiryController.text.trim(),
      'insuranceExpiry': _insuranceExpiryController.text.trim(),
      'bio': _bioController.text.trim(),
      'gender': _gender,
      'dob': _dobController.text.trim(),
      'online': _online,
      'registrationNumber': _registrationNumberController.text.trim(),
      'color': _colorController.text.trim(),
      'manufacturingYear': int.tryParse(_mfgYearController.text.trim()),
      'vehicleStatus': _vehicleStatus,
    };

    final provider = context.read<RiderVerificationProvider>();
    final result = await provider.updateDriverProfileAdmin(
      userId: widget.driver.userId,
      updateData: updateData,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (result != null) {
        widget.onSaved(result);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver details updated successfully!'),
            backgroundColor: Color(0xFF1C9A5B),
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 450,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Driver Information',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF121214),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79), size: 20),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7E7EB)),
            // Form fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bio
                      _buildTextField('Bio', _bioController),
                      const SizedBox(height: 12),
                      
                      // DOB (DatePicker)
                      _buildDatePickerField('Date of Birth', _dobController),
                      const SizedBox(height: 12),

                      // Gender Dropdown
                      _buildDropdownField<String>(
                        label: 'Gender',
                        value: _gender,
                        items: ['MALE', 'FEMALE', 'OTHER'],
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                      const SizedBox(height: 12),

                      // License Number
                      _buildTextField('License Number', _licenseNoController),
                      const SizedBox(height: 12),

                      // License Expiry
                      _buildDatePickerField('License Expiry', _licenseExpiryController),
                      const SizedBox(height: 12),

                      // Insurance Expiry
                      _buildDatePickerField('Insurance Expiry', _insuranceExpiryController),
                      const SizedBox(height: 12),

                      // Registration Number
                      _buildTextField('Registration Number', _registrationNumberController),
                      const SizedBox(height: 12),

                      // Color
                      _buildTextField('Vehicle Color', _colorController),
                      const SizedBox(height: 12),

                      // Manufacturing Year
                      _buildTextField(
                        'Manufacturing Year',
                        _mfgYearController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Status Dropdown
                      _buildDropdownField<String>(
                        label: 'Vehicle Status',
                        value: _vehicleStatus,
                        items: ['PENDING', 'ACTIVE', 'INACTIVE'],
                        onChanged: (val) => setState(() => _vehicleStatus = val),
                      ),
                      const SizedBox(height: 12),

                      // Online Status Dropdown
                      _buildDropdownField<bool>(
                        label: 'Online Status',
                        value: _online,
                        items: [true, false],
                        itemLabel: (val) => val ? 'Online' : 'Offline',
                        onChanged: (val) => setState(() => _online = val ?? false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7E7EB)),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE7E7EB)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: Color(0xFF4A5568))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31C2E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Save Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.outfit(fontSize: 13),
          onTap: () => _selectDate(controller),
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6C6F79)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 13, color: Color(0xFF121214)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel != null ? itemLabel(item) : item.toString()),
            );
          }).toList(),
        ),
      ],
    );
  }
}