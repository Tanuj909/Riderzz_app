import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/features/admin/rider_verification/providers/rider_verification_provider.dart';

class RiderVerificationScreen extends StatefulWidget {
  const RiderVerificationScreen({super.key});

  @override
  State<RiderVerificationScreen> createState() => _RiderVerificationScreenState();
}

class _RiderVerificationScreenState extends State<RiderVerificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _statuses = [
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFF0F9B6E);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'UNDER_REVIEW':
        return const Color(0xFF1A3D6B);
      case 'REJECTED':
        return Colors.redAccent;
      case 'SUSPENDED':
        return const Color(0xFF6B7785);
      default:
        return const Color(0xFF1A2233);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFFEBFDF6);
      case 'PENDING':
        return const Color(0xFFFFF7E6);
      case 'UNDER_REVIEW':
        return const Color(0xFFE8F0FB);
      case 'REJECTED':
        return const Color(0xFFFFF0F0);
      case 'SUSPENDED':
        return const Color(0xFFF7F8FA);
      default:
        return const Color(0xFFF7F8FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<RiderVerificationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filter Status Tabs
              Container(
                height: 48,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = provider.currentStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: InkWell(
                        onTap: () => provider.setStatusFilter(status),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _getStatusBgColor(status) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: _getStatusColor(status).withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Text(
                            status.replaceFirst('_', ' '),
                            style: TextStyle(
                              color: isSelected ? _getStatusColor(status) : const Color(0xFF6B7785),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE9ECF0)),

              // Driver List Container
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchDrivers(isRefresh: true),
                  color: const Color(0xFF1A3D6B),
                  child: provider.isLoading && provider.drivers.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                                      style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3D6B)),
                                      onPressed: () => provider.fetchDrivers(isRefresh: true),
                                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : provider.drivers.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                                            child: const Icon(Icons.assignment_ind_rounded, size: 48, color: Color(0xFF1A3D6B)),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Drivers Found (${provider.currentStatusFilter})',
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
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  itemCount: provider.drivers.length + (provider.isLoadMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == provider.drivers.length) {
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

                                    final driver = provider.drivers[index];
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDriverDetailsBottomSheet(driver),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
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
                        color: _getStatusBgColor(driver.approvalStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        driver.approvalStatus,
                        style: TextStyle(
                          color: _getStatusColor(driver.approvalStatus),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, color: Color(0xFFE9ECF0)),
                ),

                // Vehicle Information
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.airport_shuttle_rounded, color: Color(0xFF1A3D6B), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.vehicle != null
                                ? '${driver.vehicle!.make} ${driver.vehicle!.model}'
                                : 'No vehicle info',
                            style: const TextStyle(
                              color: Color(0xFF1A2233),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Plate: ${driver.vehicleNumber} • Type: ${driver.vehicle?.vehicleTypeName ?? "N/A"}',
                            style: const TextStyle(
                              color: Color(0xFF6B7785),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Trips & Rating info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'Verify Documents',
                          style: TextStyle(
                            color: Color(0xFF1A3D6B),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1A3D6B), size: 10),
                      ],
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

// DRIVER DETAILS BOTTOM SHEET (PREMIUM DESIGN)
class DriverDetailsBottomSheet extends StatefulWidget {
  final AdminDriverModel driver;

  const DriverDetailsBottomSheet({super.key, required this.driver});

  @override
  State<DriverDetailsBottomSheet> createState() => _DriverDetailsBottomSheetState();
}

class _DriverDetailsBottomSheetState extends State<DriverDetailsBottomSheet> {
  bool _isUpdating = false;

  void _showDocumentViewerDialog(AdminDriverModel currentDriver, AdminDriverDocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) => DocumentViewerDialog(
        driver: currentDriver,
        document: doc,
      ),
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

    if (result == null) return; // User cancelled

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
        return const Color(0xFF0F9B6E);
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiderVerificationProvider>(
      builder: (context, provider, child) {
        final driver = provider.drivers.firstWhere(
          (d) => d.id == widget.driver.id,
          orElse: () => widget.driver,
        );
        final vehicle = driver.vehicle;

        const List<String> allRequiredDocTypes = [
          'AADHAR',
          'PAN',
          'DRIVING_LICENSE',
          'RC_BOOK',
          'INSURANCE',
        ];

        final uploadedDocTypes = driver.documents.map((doc) => doc.docType).toSet();
        final hasAllDocs = allRequiredDocTypes.every((type) => uploadedDocTypes.contains(type));
        final allApproved = driver.documents.isNotEmpty && driver.documents.every((doc) => doc.status == 'APPROVED');
        final canApprove = hasAllDocs && allApproved;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
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
                        color: const Color(0xFFE9ECF0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    driver.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                  ),
                  Text(
                    'Phone: +91 ${driver.phone} • Status: ${driver.approvalStatus}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Specs section
                  const Text('Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A2233))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECF0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Make & Model', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
                            Text(
                              vehicle != null ? '${vehicle.make} ${vehicle.model}' : 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A2233)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Plate Number', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
                            Text(
                              driver.vehicleNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A2233)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Max Weight Capacity', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
                            Text(
                              vehicle != null ? '${vehicle.maxWeightKg} kg' : 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A2233)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Base Rate per Km', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
                            Text(
                              vehicle != null ? '₹${vehicle.perKmRate.toStringAsFixed(0)}' : 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A2233)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Documents Verification list
                  const Text('Verification Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A2233))),
                  const SizedBox(height: 8),
                  ...allRequiredDocTypes.map((docType) {
                    final docIndex = driver.documents.indexWhere((d) => d.docType == docType);
                    final hasDoc = docIndex != -1;

                    if (hasDoc) {
                      final doc = driver.documents[docIndex];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description_outlined, color: Color(0xFF1A3D6B), size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.docType.replaceAll('_', ' '),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A2233)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Status: ${doc.status}',
                                      style: TextStyle(color: _getDocStatusColor(doc.status), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F0FB),
                                foregroundColor: const Color(0xFF1A3D6B),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                              label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _showDocumentViewerDialog(driver, doc),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      docType.replaceAll('_', ' '),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6B7785)),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Still Pending (Not Uploaded)',
                                      style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Missing',
                                style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }),

                  const SizedBox(height: 24),

                  // Update Status Actions Panel
                  if (_isUpdating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B))),
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
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6B7785)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Driver is currently suspended. You can activate this driver below.',
                                  style: TextStyle(
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
                                  backgroundColor: const Color(0xFF0F9B6E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () => _updateStatus('ACTIVATED'),
                                child: const Text('Activate Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                    backgroundColor: canApprove ? const Color(0xFF0F9B6E) : const Color(0xFFE9ECF0),
                                    foregroundColor: canApprove ? Colors.white : const Color(0xFFA0AEC0),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (canApprove) {
                                      _updateStatus('APPROVED');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('All documents must be uploaded and approved first.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Approve Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                          if (!canApprove) ...[
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF6B7785)),
                                SizedBox(width: 4),
                                Text(
                                  'All documents must be uploaded and approved first.',
                                  style: TextStyle(color: Color(0xFF6B7785), fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () => _updateStatus('REJECTED'),
                                child: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                    backgroundColor: const Color(0xFF6B7785),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _updateStatus('SUSPENDED'),
                                  child: const Text('Suspend Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFF0F9B6E);
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
    switch (docType) {
      case 'AADHAR':
        return '5321 8842 $idStr';
      case 'PAN':
        return 'BJKPD${idStr}G';
      case 'DRIVING_LICENSE':
        return 'DL-132026$idStr';
      case 'RC_BOOK':
        return 'RC-DL-3C-$idStr';
      case 'INSURANCE':
        return 'INS-992384-${widget.driver.id.toString().padLeft(2, '0')}';
      default:
        return 'DOC-ID-$idStr';
    }
  }

  Widget _buildCardGraphic(String docType, String docStatus) {
    late Gradient cardGradient;
    late String cardTitle;
    late String cardLabel;
    late IconData cardIcon;

    switch (docType) {
      case 'AADHAR':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        cardTitle = 'AADHAAR CARD';
        cardLabel = 'Govt. of India • UIDAI';
        cardIcon = Icons.fingerprint_rounded;
        break;
      case 'PAN':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        cardTitle = 'PAN CARD';
        cardLabel = 'Income Tax Department';
        cardIcon = Icons.account_balance_wallet_rounded;
        break;
      case 'DRIVING_LICENSE':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF8A2387), Color(0xFFE94057)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        cardTitle = 'DRIVING LICENSE';
        cardLabel = 'Ministry of Road Transport & Highways';
        cardIcon = Icons.directions_car_rounded;
        break;
      case 'RC_BOOK':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        cardTitle = 'REGISTRATION CERTIFICATE';
        cardLabel = 'Vehicle Registration Department';
        cardIcon = Icons.two_wheeler_rounded;
        break;
      case 'INSURANCE':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        cardTitle = 'VEHICLE INSURANCE';
        cardLabel = 'Motor Policy Certificate';
        cardIcon = Icons.verified_user_rounded;
        break;
      default:
        cardGradient = const LinearGradient(
          colors: [Color(0xFF1A3D6B), Color(0xFF1D5A9C)],
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
        borderRadius: BorderRadius.circular(16),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardLabel,
                          style: TextStyle(
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getFormattedDocNo(docType),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'Courier',
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
                            style: TextStyle(
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
                          style: TextStyle(
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
            backgroundColor: status == 'APPROVED' ? const Color(0xFF0F9B6E) : Colors.redAccent,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                docType.replaceAll('_', ' '),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A2233),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785), size: 20),
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
                _buildCardGraphic(docType, docStatus),
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
                        const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Rejection Reason',
                              style: TextStyle(
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
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9ECF0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Color(0xFF6B7785), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A3D6B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF1A3D6B), size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: fileUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document link copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                if (_showRejectInput) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Reason for Rejection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _reasonController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g., Document image is blurry',
                            hintStyle: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE9ECF0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE9ECF0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                  ),
                ),
              )
            else if (_showRejectInput) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7785),
                        side: const BorderSide(color: Color(0xFFE9ECF0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showRejectInput = false;
                          _reasonController.clear();
                        });
                      },
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      child: const Text('Confirm Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                          backgroundColor: const Color(0xFF0F9B6E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _handleVerify('APPROVED'),
                        child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A3D6B),
                        side: const BorderSide(color: Color(0xFF1A3D6B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
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
      themeColor = const Color(0xFF0F9B6E); // Green
      iconData = Icons.verified_user_rounded;
      title = 'Approve Application';
      actionText = 'Approve';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            const TextSpan(
              text: 'approve ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F9B6E)),
            ),
            TextSpan(
              text: widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '\'s application? This will immediately activate their profile as a driver.'),
          ],
        ),
      );
    } else if (status == 'ACTIVATED') {
      themeColor = const Color(0xFF0F9B6E); // Green
      iconData = Icons.verified_user_rounded;
      title = 'Activate Driver';
      actionText = 'Activate';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            const TextSpan(
              text: 'activate ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F9B6E)),
            ),
            TextSpan(
              text: widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
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
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            const TextSpan(
              text: 'reject ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
            TextSpan(
              text: widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const TextSpan(text: '\'s application? Please specify a clear reason for the rejection below.'),
          ],
        ),
      );
    } else {
      themeColor = const Color(0xFF6B7785); // Grey for suspended
      iconData = Icons.block_flipped;
      title = 'Suspend Driver';
      actionText = 'Suspend';
      subtitleWidget = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Are you sure you want to '),
            const TextSpan(
              text: 'suspend ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7785)),
            ),
            TextSpan(
              text: widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
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
                  style: const TextStyle(
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
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A202C)),
                    decoration: InputDecoration(
                      hintText: 'e.g., Document image is too blurry or license is expired.',
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
