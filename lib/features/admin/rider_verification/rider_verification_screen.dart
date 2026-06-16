import 'package:flutter/material.dart';
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
    'UNDER_REVIEW',
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

  void _showDocumentViewerDialog(AdminDriverDocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          doc.docType.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECF0)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.redAccent),
                  SizedBox(height: 12),
                  Text('Document PDF File', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233))),
                  SizedBox(height: 4),
                  Text('Tap view external to open URL', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              doc.fileUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1A3D6B), fontSize: 11, decoration: TextDecoration.underline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String targetStatus) async {
    String? rejectionReason;

    if (targetStatus == 'REJECTED') {
      final reasonController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason...',
              hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm Reject'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      rejectionReason = reasonController.text.trim();
      if (rejectionReason.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejection reason cannot be empty!')),
          );
        }
        return;
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$targetStatus Application?', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to change this driver\'s status to $targetStatus?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D6B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<RiderVerificationProvider>();
    final success = await provider.updateDriverStatus(
      widget.driver.id,
      targetStatus,
      rejectionReason: rejectionReason,
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
    final driver = widget.driver;
    final vehicle = driver.vehicle;

    return Container(
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
            if (driver.documents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('No documents uploaded yet.', style: TextStyle(color: Color(0xFF6B7785), fontSize: 12)),
              )
            else
              ...driver.documents.map((doc) => Container(
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
                          onPressed: () => _showDocumentViewerDialog(doc),
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 24),

            // Update Status Actions Panel
            if (_isUpdating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B))),
                ),
              )
            else
              Column(
                children: [
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
                          onPressed: () => _updateStatus('APPROVED'),
                          child: const Text('Approve Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A3D6B),
                            side: const BorderSide(color: Color(0xFF1A3D6B)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _updateStatus('UNDER_REVIEW'),
                          child: const Text('Under Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () => _updateStatus('REJECTED'),
                          child: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    );
  }
}
