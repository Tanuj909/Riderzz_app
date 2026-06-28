import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';

class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  int _currentStep = 1;
  bool _forceShowForm = false;
  
  // Form keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController(text: 'White');
  final _yearController = TextEditingController(text: '2020');
  final _licenseExpiryController = TextEditingController(text: '2028-06-30');
  final _insuranceExpiryController = TextEditingController(text: '2025-12-31');
  final _bioController = TextEditingController(text: 'Experienced goods delivery driver');
  String _selectedGender = 'MALE';
  
  // Document text inputs
  final _aadharFrontController = TextEditingController();
  final _aadharBackController = TextEditingController();
  final _panCardController = TextEditingController();
  final _dlFrontController = TextEditingController();
  final _dlBackController = TextEditingController();
  final _rcBookController = TextEditingController();
  final _insuranceController = TextEditingController();

  AvailableVehicleModel? _selectedVehicle;

  // Image picker and picked file references
  final ImagePicker _picker = ImagePicker();
  XFile? _aadharFrontFile;
  XFile? _aadharBackFile;
  XFile? _panCardFile;
  XFile? _dlFrontFile;
  XFile? _dlBackFile;
  XFile? _rcBookFile;
  XFile? _insuranceFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DriverHomeProvider>(context, listen: false);
      provider.fetchDriverProfile();
      provider.fetchAvailableVehicles();
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _licenseExpiryController.dispose();
    _insuranceExpiryController.dispose();
    _bioController.dispose();
    _aadharFrontController.dispose();
    _aadharBackController.dispose();
    _panCardController.dispose();
    _dlFrontController.dispose();
    _dlBackController.dispose();
    _rcBookController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  void _submitApplication(DriverHomeProvider provider) async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle category first.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_aadharFrontController.text.trim().isEmpty ||
          _aadharBackController.text.trim().isEmpty ||
          _panCardController.text.trim().isEmpty ||
          _dlFrontController.text.trim().isEmpty ||
          _dlBackController.text.trim().isEmpty ||
          _rcBookController.text.trim().isEmpty ||
          _insuranceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload all required documents.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final body = {
        "vehicleId": _selectedVehicle!.id,
        "registrationNumber": _plateController.text.trim(),
        "color": _colorController.text.trim(),
        "manufacturingYear": int.tryParse(_yearController.text.trim()) ?? 2020,
        "licenseNumber": _licenseController.text.trim(),
        "licenseExpiry": _licenseExpiryController.text.trim(),
        "insuranceExpiry": _insuranceExpiryController.text.trim(),
        "bio": _bioController.text.trim(),
        "gender": _selectedGender,
      };

      final aadharFrontPath = await _getUploadPath(_aadharFrontFile, 'aadhar_front');
      final aadharBackPath = await _getUploadPath(_aadharBackFile, 'aadhar_back');
      final panCardPath = await _getUploadPath(_panCardFile, 'pan_card');
      final dlFrontPath = await _getUploadPath(_dlFrontFile, 'dl_front');
      final dlBackPath = await _getUploadPath(_dlBackFile, 'dl_back');
      final rcBookPath = await _getUploadPath(_rcBookFile, 'rc_book');
      final insurancePath = await _getUploadPath(_insuranceFile, 'insurance');

      final success = await provider.applyAsDriver(
        body,
        aadharFrontPath: aadharFrontPath,
        aadharBackPath: aadharBackPath,
        panCardPath: panCardPath,
        dlFrontPath: dlFrontPath,
        dlBackPath: dlBackPath,
        rcBookPath: rcBookPath,
        insurancePath: insurancePath,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Color(0xFF0F9B6E),
          ),
        );
        setState(() {
          _forceShowForm = false;
          _currentStep = 1;
          _aadharFrontFile = null;
          _aadharBackFile = null;
          _panCardFile = null;
          _dlFrontFile = null;
          _dlBackFile = null;
          _rcBookFile = null;
          _insuranceFile = null;
          _aadharFrontController.clear();
          _aadharBackController.clear();
          _panCardController.clear();
          _dlFrontController.clear();
          _dlBackController.clear();
          _rcBookController.clear();
          _insuranceController.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Submission failed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleRoleTransition() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateUserRole('ROLE_DRIVER');
    
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/role_redirect', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to activate Driver Mode. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickDocument(String type, DriverHomeProvider provider) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final fileUrl = 'https://cdn.riderzz.com/docs/uploaded_${image.name}';
        setState(() {
          if (type == 'AADHAAR_FRONT') {
            _aadharFrontFile = image;
            _aadharFrontController.text = fileUrl;
          } else if (type == 'AADHAAR_BACK') {
            _aadharBackFile = image;
            _aadharBackController.text = fileUrl;
          } else if (type == 'PAN_CARD') {
            _panCardFile = image;
            _panCardController.text = fileUrl;
          } else if (type == 'DRIVING_LICENSE_FRONT') {
            _dlFrontFile = image;
            _dlFrontController.text = fileUrl;
          } else if (type == 'DRIVING_LICENSE_BACK') {
            _dlBackFile = image;
            _dlBackController.text = fileUrl;
          } else if (type == 'RC_BOOK') {
            _rcBookFile = image;
            _rcBookController.text = fileUrl;
          } else if (type == 'INSURANCE') {
            _insuranceFile = image;
            _insuranceController.text = fileUrl;
          }
        });

        // If user already has a profile (submitted/pending/rejected), upload immediately!
        if (provider.profile != null) {
          final uploadSuccess = await provider.uploadDocument(type, image.path);
          if (uploadSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$type uploaded successfully!'),
                backgroundColor: const Color(0xFF0F9B6E),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'Failed to upload $type. Please try again.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select document: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<String> _getUploadPath(XFile? file, String prefix) async {
    if (file != null) return file.path;
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/dummy_${prefix}_doc.png');
    if (!await tempFile.exists()) {
      await tempFile.writeAsString('Dummy document content for $prefix');
    }
    return tempFile.path;
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String documentType,
    required XFile? pickedFile,
    required String defaultUrl,
    required VoidCallback onTap,
    DriverProfileModel? profile,
  }) {
    DriverDocumentModel? existingDoc;
    if (profile != null) {
      for (final doc in profile.documents) {
        if (doc.docType.toUpperCase() == documentType.toUpperCase()) {
          existingDoc = doc;
          break;
        }
      }
    }

    final String defaultFileName = defaultUrl.split('/').last;
    final hasFile = pickedFile != null;
    
    Color cardBgColor = const Color(0xFFF8FAFC);
    Color cardBorderColor = const Color(0xFFE2E8F0);
    double cardBorderWidth = 1.0;
    Color iconBgColor = const Color(0xFFF1F5F9);
    Color iconColor = const Color(0xFF64748B);
    IconData cardIcon = Icons.cloud_upload_outlined;
    String statusBadgeText = '';
    Color statusBadgeColor = Colors.grey;

    if (hasFile) {
      cardBgColor = const Color(0xFFEEF2FF);
      cardBorderColor = const Color(0xFFE0E7FF);
      cardBorderWidth = 1.2;
      iconBgColor = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4F46E5);
      cardIcon = Icons.file_present_rounded;
    } else if (existingDoc != null) {
      final status = existingDoc.status.toUpperCase();
      if (status == 'APPROVED') {
        cardBgColor = const Color(0xFFF0FDF4);
        cardBorderColor = const Color(0xFFDCFCE7);
        cardBorderWidth = 1.2;
        iconBgColor = const Color(0xFFD1FAE5);
        iconColor = const Color(0xFF166534);
        cardIcon = Icons.check_circle_rounded;
        statusBadgeText = 'APPROVED';
        statusBadgeColor = const Color(0xFF16A34A);
      } else if (status == 'REJECTED') {
        cardBgColor = const Color(0xFFFEF2F2);
        cardBorderColor = const Color(0xFFFEE2E2);
        cardBorderWidth = 1.2;
        iconBgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFF991B1B);
        cardIcon = Icons.cancel_rounded;
        statusBadgeText = 'REJECTED';
        statusBadgeColor = const Color(0xFFDC2626);
      } else {
        cardBgColor = const Color(0xFFF0F9FF);
        cardBorderColor = const Color(0xFFE0F2FE);
        cardBorderWidth = 1.2;
        iconBgColor = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        cardIcon = Icons.hourglass_empty_rounded;
        statusBadgeText = 'PENDING';
        statusBadgeColor = const Color(0xFF0284C7);
      }
    }

    final displayName = hasFile 
        ? pickedFile.name 
        : (existingDoc != null 
            ? existingDoc.fileUrl.split("/").last 
            : 'No file selected');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorderColor,
          width: cardBorderWidth,
        ),
        boxShadow: (hasFile || existingDoc != null) 
            ? [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cardIcon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (statusBadgeText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBadgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusBadgeText,
                          style: TextStyle(
                            color: statusBadgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (hasFile || existingDoc != null) ? const Color(0xFF334155) : const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                if (existingDoc != null && existingDoc.status.toUpperCase() == 'REJECTED' && existingDoc.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${existingDoc.rejectionReason}',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (hasFile || existingDoc != null) ? const Color(0xFFEFF6FF) : const Color(0xFF1A3D6B),
              foregroundColor: (hasFile || existingDoc != null) ? const Color(0xFF1E40AF) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap,
            child: Text(
              (hasFile || existingDoc != null) ? 'Change' : 'Upload',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    Widget bodyWidget;

    if (driverProvider.isLoading && profile == null) {
      bodyWidget = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
        ),
      );
    } else if (profile != null && !_forceShowForm) {
      bodyWidget = _buildStatusView(profile, user?.role, driverProvider);
    } else {
      bodyWidget = _buildRegistrationFlow(user?.name, user?.phone, driverProvider);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2233)),
          onPressed: () {
            if (profile == null && _currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Register as Driver',
          style: TextStyle(color: Color(0xFF1A2233), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: bodyWidget,
      ),
    );
  }

  Widget _buildRegistrationFlow(String? name, String? phone, DriverHomeProvider driverProvider) {
    return Column(
      children: [
        const SizedBox(height: 14),
        _buildStepIndicator(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: _currentStep == 1
                ? _buildStep1Onboarding()
                : _buildStep2Form(name, phone, driverProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode(1, 'Onboard'),
          _buildStepLine(1),
          _buildStepNode(2, 'Details'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFE8F0FB) : const Color(0xFFF7F8FA),
            border: Border.all(
              color: isActive ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
              width: 1.5,
            ),
            boxShadow: isCurrent 
                ? [BoxShadow(color: const Color(0xFF1A3D6B).withOpacity(0.1), blurRadius: 6, spreadRadius: 1)]
                : [],
          ),
          alignment: Alignment.center,
          child: isActive && _currentStep > step
              ? const Icon(Icons.check_rounded, color: Color(0xFF1A3D6B), size: 16)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: isActive ? const Color(0xFF1A3D6B) : const Color(0xFFB0B8C4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1A2233) : const Color(0xFFB0B8C4),
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int startStep) {
    final isPassed = _currentStep > startStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isPassed ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
      ),
    );
  }

  Widget _buildStep1Onboarding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Registration Form',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Register your vehicle, share your details, and start taking bookings in your area. Get verified within minutes!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Perks Section (Grouped in a single clean modern Card container to fit without scrolling)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9ECF0)),
          ),
          child: Column(
            children: [
              _buildPerkRowSimple(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Daily Payments',
                desc: 'Direct transfer to your bank account with complete transparency on every payout.',
              ),
              const Divider(height: 28, color: Color(0xFFE9ECF0), thickness: 1),
              _buildPerkRowSimple(
                icon: Icons.schedule_rounded,
                title: 'Flexible Timing',
                desc: 'Turn on Driver Mode whenever you are ready to earn. Be your own boss.',
              ),
              const Divider(height: 28, color: Color(0xFFE9ECF0), thickness: 1),
              _buildPerkRowSimple(
                icon: Icons.shield_outlined,
                title: 'Safe & Supported Rides',
                desc: 'Riderzz covers support and ride assistance on every transaction.',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3D6B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () {
            setState(() => _currentStep = 2);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Application',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerkRowSimple({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A3D6B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A2233),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF6B7785),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Form(String? name, String? phone, DriverHomeProvider driverProvider) {
    final vehicles = driverProvider.availableVehicles;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle & License Info',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Provide accurate details so our admin team can approve your application quickly.',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // User Personal Info (Read-only)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: Color(0xFFB0B8C4), size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Applicant Name',
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone ?? '+91 9999999999',
                      style: const TextStyle(color: Color(0xFF6B7785), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified Profile',
                    style: TextStyle(color: Color(0xFF0F9B6E), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Select Available Vehicle Category
          const Text(
            'Select Vehicle Category',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          
          if (driverProvider.isLoading && vehicles.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                  ),
                ),
              ),
            )
          ] else if (vehicles.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: const Text(
                'No available vehicles found. Please contact admin.',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  final isSelected = _selectedVehicle?.id == v.id;
                  
                  IconData categoryIcon = Icons.directions_car_rounded;
                  if (v.vehicleTypeName.toLowerCase().contains('bike')) {
                    categoryIcon = Icons.directions_bike_rounded;
                  } else if (v.vehicleTypeName.toLowerCase().contains('cart')) {
                    categoryIcon = Icons.local_shipping_rounded;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedVehicle = v);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F0FB) : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            categoryIcon,
                            color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${v.make} ${v.model}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF1A2233),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${v.perKmRate.toStringAsFixed(0)}/km',
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF1A3D6B).withOpacity(0.7) : const Color(0xFFB0B8C4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Driving License Input
          const Text(
            'Driving License Number',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _licenseController,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: _buildInputDecoration('e.g. DL1420241234567', Icons.badge_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Driving License number is required';
              }
              if (value.trim().length < 6) {
                return 'Enter a valid license number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Vehicle Plate Number Input
          const Text(
            'Vehicle Plate Number',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _plateController,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            textCapitalization: TextCapitalization.characters,
            decoration: _buildInputDecoration('e.g. DL01AB1234', Icons.pin_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'License plate number is required';
              }
              if (value.trim().length < 4) {
                return 'Enter a valid license plate';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Vehicle Color and Manufacturing Year
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Color',
                      style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _colorController,
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                      decoration: _buildInputDecoration('e.g. White', Icons.color_lens_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Color is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manufacturing Year',
                      style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                      decoration: _buildInputDecoration('e.g. 2020', Icons.calendar_today_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Year is required';
                        if (int.tryParse(value.trim()) == null) return 'Enter valid year';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // License Expiry and Insurance Expiry Dates
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'License Expiry',
                      style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _licenseExpiryController,
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                      decoration: _buildInputDecoration('YYYY-MM-DD', Icons.date_range_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Expiry required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insurance Expiry',
                      style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _insuranceExpiryController,
                      style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                      decoration: _buildInputDecoration('YYYY-MM-DD', Icons.date_range_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Expiry required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Driver Bio
          const Text(
            'Short Bio / Experience',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: _buildInputDecoration('Describe your experience...', Icons.info_outline),
            validator: (value) => value == null || value.trim().isEmpty ? 'Bio is required' : null,
          ),
          const SizedBox(height: 20),

          // Gender Selection Dropdown
          const Text(
            'Gender',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: _buildInputDecoration('Select Gender', Icons.people_outline),
            dropdownColor: Colors.white,
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Male')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedGender = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Upload Document Cards section
          const Text(
            'Upload Verification Documents 📁',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload your actual documents from your gallery to verify your profile:',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 11),
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadCard(
            title: 'Aadhaar Card Front',
            documentType: 'AADHAAR_FRONT',
            pickedFile: _aadharFrontFile,
            defaultUrl: _aadharFrontController.text,
            onTap: () => _pickDocument('AADHAAR_FRONT', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'Aadhaar Card Back',
            documentType: 'AADHAAR_BACK',
            pickedFile: _aadharBackFile,
            defaultUrl: _aadharBackController.text,
            onTap: () => _pickDocument('AADHAAR_BACK', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'PAN Card',
            documentType: 'PAN_CARD',
            pickedFile: _panCardFile,
            defaultUrl: _panCardController.text,
            onTap: () => _pickDocument('PAN_CARD', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Front',
            documentType: 'DRIVING_LICENSE_FRONT',
            pickedFile: _dlFrontFile,
            defaultUrl: _dlFrontController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_FRONT', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Back',
            documentType: 'DRIVING_LICENSE_BACK',
            pickedFile: _dlBackFile,
            defaultUrl: _dlBackController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_BACK', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'RC Book (Registration Certificate)',
            documentType: 'RC_BOOK',
            pickedFile: _rcBookFile,
            defaultUrl: _rcBookController.text,
            onTap: () => _pickDocument('RC_BOOK', driverProvider),
            profile: driverProvider.profile,
          ),

          _buildDocumentUploadCard(
            title: 'Vehicle Insurance',
            documentType: 'INSURANCE',
            pickedFile: _insuranceFile,
            defaultUrl: _insuranceController.text,
            onTap: () => _pickDocument('INSURANCE', driverProvider),
            profile: driverProvider.profile,
          ),
          const SizedBox(height: 16),

          // Submit button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => _submitApplication(driverProvider),
            child: driverProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Application',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFB0B8C4), size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9ECF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  Widget _buildStatusView(DriverProfileModel profile, String? userRole, DriverHomeProvider driverProvider) {
    final status = profile.approvalStatus.toUpperCase();

    if (status == 'PENDING') {
      return _buildPendingUI(profile, driverProvider);
    } else if (status == 'APPROVED') {
      return _buildApprovedUI(profile, userRole);
    } else if (status == 'REJECTED') {
      return _buildRejectedUI(profile, driverProvider);
    } else {
      return _buildPendingUI(profile, driverProvider);
    }
  }

  Widget _buildPendingUI(DriverProfileModel profile, DriverHomeProvider driverProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant compact soft-blue status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Pending Review',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Your details and documents are under review. We will notify you once approved.',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submitted Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitted Application Details',
                  style: TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20, color: Color(0xFFE9ECF0)),
                _buildDetailRow('Submission Date', _formatDateTime(profile.createdAt)),
                _buildDetailRow('License Number', profile.licenseNumber),
                _buildDetailRow('Vehicle Plate Number', profile.vehicleNumber),
                _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
                _buildDetailRow('Documents Status', '${profile.documents.length} Uploaded (Pending Verification)'),
              ],
            ),
          ),
          _buildCollapsibleProfileDetails(profile),
          const SizedBox(height: 24),

          // Document section header
          const Text(
            'Verification Documents 📁',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check the status or re-upload documents if required:',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Document Upload Cards (Pending status shows here)
          _buildDocumentUploadCard(
            title: 'Aadhaar Card Front',
            documentType: 'AADHAAR_FRONT',
            pickedFile: _aadharFrontFile,
            defaultUrl: _aadharFrontController.text,
            onTap: () => _pickDocument('AADHAAR_FRONT', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Aadhaar Card Back',
            documentType: 'AADHAAR_BACK',
            pickedFile: _aadharBackFile,
            defaultUrl: _aadharBackController.text,
            onTap: () => _pickDocument('AADHAAR_BACK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'PAN Card',
            documentType: 'PAN_CARD',
            pickedFile: _panCardFile,
            defaultUrl: _panCardController.text,
            onTap: () => _pickDocument('PAN_CARD', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Front',
            documentType: 'DRIVING_LICENSE_FRONT',
            pickedFile: _dlFrontFile,
            defaultUrl: _dlFrontController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_FRONT', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Back',
            documentType: 'DRIVING_LICENSE_BACK',
            pickedFile: _dlBackFile,
            defaultUrl: _dlBackController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_BACK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'RC Book (Registration Certificate)',
            documentType: 'RC_BOOK',
            pickedFile: _rcBookFile,
            defaultUrl: _rcBookController.text,
            onTap: () => _pickDocument('RC_BOOK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Vehicle Insurance',
            documentType: 'INSURANCE',
            pickedFile: _insuranceFile,
            defaultUrl: _insuranceController.text,
            onTap: () => _pickDocument('INSURANCE', driverProvider),
            profile: profile,
          ),
          const SizedBox(height: 24),

          // Grouped Buttons at the Bottom
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A3D6B)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showAllDetailsBottomSheet(profile),
            icon: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1A3D6B)),
            label: const Text(
              'View All Details',
              style: TextStyle(color: Color(0xFF1A3D6B), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => driverProvider.fetchDriverProfile(),
            child: driverProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text(
                    'Refresh Application Status',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAllDetailsBottomSheet(DriverProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull down handle bar
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Application Details',
                    style: TextStyle(
                      color: Color(0xFF1A2233),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFE9ECF0)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Applicant Info
                      _buildSectionHeader('Applicant Information', Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _buildDetailRow('Full Name', profile.name),
                      _buildDetailRow('Phone Number', profile.phone),
                      _buildDetailRow('Gender', profile.gender),
                      _buildDetailRow('Date of Birth', (profile.dob != null && profile.dob!.isNotEmpty) ? profile.dob! : 'N/A'),
                      _buildDetailRow('Bio', profile.bio.isNotEmpty ? profile.bio : 'N/A'),
                      _buildDetailRow('Approval Status', profile.approvalStatus),
                      _buildDetailRow('Rating', profile.rating.toStringAsFixed(2)),
                      _buildDetailRow('Completed Trips', profile.totalTrips.toString()),
                      _buildDetailRow('License Number', profile.licenseNumber),
                      _buildDetailRow('License Expiry', profile.licenseExpiry.isNotEmpty ? profile.licenseExpiry : 'N/A'),
                      _buildDetailRow('Insurance Expiry', profile.insuranceExpiry.isNotEmpty ? profile.insuranceExpiry : 'N/A'),
                      _buildDetailRow('Submitted On', _formatDateTime(profile.createdAt)),
                      if (profile.approvedAt != null && profile.approvedAt!.isNotEmpty)
                        _buildDetailRow('Approved At', _formatDateTime(profile.approvedAt!)),

                      const SizedBox(height: 24),

                      // Vehicle Info
                      _buildSectionHeader('Vehicle Information', Icons.directions_car_outlined),
                      const SizedBox(height: 12),
                      _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
                      _buildDetailRow('Registration Number', profile.vehicleNumber),
                      _buildDetailRow('Vehicle Color', profile.color.isNotEmpty ? profile.color : 'N/A'),
                      _buildDetailRow('Manufacturing Year', profile.manufacturingYear.toString()),
                      _buildDetailRow('Vehicle Status', profile.vehicleStatus),

                      const SizedBox(height: 24),

                      // Documents Info
                      _buildSectionHeader('Verification Documents', Icons.folder_open_outlined),
                      const SizedBox(height: 12),
                      if (profile.documents.isEmpty)
                        const Text(
                          'No documents uploaded.',
                          style: TextStyle(color: Color(0xFF6B7785), fontSize: 13),
                        )
                      else
                        ...profile.documents.map((doc) => _buildDocumentItem(doc)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProfileBottomSheet(profile);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileBottomSheet(DriverProfileModel profile) {
    final licenseController = TextEditingController(text: profile.licenseNumber);
    final bioController = TextEditingController(text: profile.bio);
    final dobController = TextEditingController(text: (profile.dob != null && profile.dob!.isNotEmpty) ? profile.dob : '1992-03-20');
    String genderValue = profile.gender.isNotEmpty ? profile.gender : 'MALE';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Profile Details',
                            style: TextStyle(
                              color: Color(0xFF1A2233),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Color(0xFFE9ECF0)),
                      const SizedBox(height: 12),

                      // License Number
                      const Text(
                        'License Number',
                        style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: licenseController,
                        style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                        decoration: _buildInputDecoration('License Number', Icons.badge_outlined),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // DOB
                      const Text(
                        'Date of Birth',
                        style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: dobController,
                        style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                        decoration: _buildInputDecoration('YYYY-MM-DD', Icons.date_range_outlined),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      const Text(
                        'Gender',
                        style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: genderValue,
                        style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                        decoration: _buildInputDecoration('Gender', Icons.people_outline),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              genderValue = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      const Text(
                        'Bio / Experience',
                        style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: bioController,
                        maxLines: 2,
                        style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
                        decoration: _buildInputDecoration('Short Bio', Icons.info_outline),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE9ECF0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3D6B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() {
                                  isSaving = true;
                                });
                                final provider = context.read<DriverHomeProvider>();
                                final success = await provider.updateProfile(
                                  licenseNumber: licenseController.text.trim(),
                                  bio: bioController.text.trim(),
                                  gender: genderValue,
                                  dob: dobController.text.trim(),
                                );
                                setSheetState(() {
                                  isSaving = false;
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Profile updated successfully!' : (provider.errorMessage ?? 'Update failed.')),
                                      backgroundColor: success ? const Color(0xFF0F9B6E) : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A3D6B), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(DriverDocumentModel doc) {
    Color statusColor = Colors.orangeAccent;
    if (doc.status.toUpperCase() == 'APPROVED') {
      statusColor = const Color(0xFF0F9B6E);
    } else if (doc.status.toUpperCase() == 'REJECTED') {
      statusColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doc.docType.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1A2233),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doc.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              // Clickable link behavior, or copy to clipboard
            },
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF1A3D6B), size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doc.fileUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3D6B),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (doc.rejectionReason != null && doc.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${doc.rejectionReason}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Uploaded: ${_formatDateTime(doc.uploadedAt)}',
            style: const TextStyle(color: Color(0xFF6B7785), fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeStr;
    }
  }

  Widget _buildApprovedUI(DriverProfileModel profile, String? userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant modern approved banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Approved! 🎉',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Congratulations, your driver partner registration is complete. Welcome to the Riderzz network.',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Approved details summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approved Partner Details',
                  style: TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20, color: Color(0xFFE9ECF0)),
                _buildDetailRow('Submission Date', _formatDateTime(profile.createdAt)),
                _buildDetailRow('License Number', profile.licenseNumber),
                _buildDetailRow('Vehicle Plate', profile.vehicleNumber),
                _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
              ],
            ),
          ),
          _buildCollapsibleProfileDetails(profile),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9B6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _handleRoleTransition,
            child: Text(
              userRole == 'ROLE_DRIVER' ? 'Go to Dashboard' : 'Enter Driver Mode',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedUI(DriverProfileModel profile, DriverHomeProvider driverProvider) {
    final String rejectionReason = profile.vehicle?.rejectionReason ?? 'Submitted document(s) were invalid or illegible.';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant modern rejected banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Rejected ❌',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please check the status of each document and re-upload rejected or missing ones.',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rejection Reason Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason',
                        style: TextStyle(color: Color(0xFF1A2233), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rejectionReason,
                        style: const TextStyle(color: Color(0xFF6B7785), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Verification Documents 📁',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please update/re-upload any rejected documents below:',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 11),
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadCard(
            title: 'Aadhaar Card Front',
            documentType: 'AADHAAR_FRONT',
            pickedFile: _aadharFrontFile,
            defaultUrl: _aadharFrontController.text,
            onTap: () => _pickDocument('AADHAAR_FRONT', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Aadhaar Card Back',
            documentType: 'AADHAAR_BACK',
            pickedFile: _aadharBackFile,
            defaultUrl: _aadharBackController.text,
            onTap: () => _pickDocument('AADHAAR_BACK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'PAN Card',
            documentType: 'PAN_CARD',
            pickedFile: _panCardFile,
            defaultUrl: _panCardController.text,
            onTap: () => _pickDocument('PAN_CARD', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Front',
            documentType: 'DRIVING_LICENSE_FRONT',
            pickedFile: _dlFrontFile,
            defaultUrl: _dlFrontController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_FRONT', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Driving License Back',
            documentType: 'DRIVING_LICENSE_BACK',
            pickedFile: _dlBackFile,
            defaultUrl: _dlBackController.text,
            onTap: () => _pickDocument('DRIVING_LICENSE_BACK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'RC Book (Registration Certificate)',
            documentType: 'RC_BOOK',
            pickedFile: _rcBookFile,
            defaultUrl: _rcBookController.text,
            onTap: () => _pickDocument('RC_BOOK', driverProvider),
            profile: profile,
          ),

          _buildDocumentUploadCard(
            title: 'Vehicle Insurance',
            documentType: 'INSURANCE',
            pickedFile: _insuranceFile,
            defaultUrl: _insuranceController.text,
            onTap: () => _pickDocument('INSURANCE', driverProvider),
            profile: profile,
          ),
          const SizedBox(height: 24),
          _buildCollapsibleProfileDetails(profile),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                _forceShowForm = true;
                _currentStep = 2; // Jump directly to form
              });
            },
            child: const Text(
              'Modify & Re-apply',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7785), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF1A2233),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleProfileDetails(DriverProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF1A3D6B)),
          title: const Text(
            'View Full Profile Details',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
          ),
          subtitle: const Text(
            'Tap to view dates, bio, gender, color etc.',
            style: TextStyle(fontSize: 10, color: Color(0xFF6B7785)),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            _buildDetailRow('Full Name', profile.name),
            _buildDetailRow('Phone Number', profile.phone),
            _buildDetailRow('Gender', profile.gender),
            _buildDetailRow('Date of Birth', (profile.dob != null && profile.dob!.isNotEmpty) ? profile.dob! : 'N/A'),
            _buildDetailRow('Bio / Intro', profile.bio.isNotEmpty ? profile.bio : 'N/A'),
            _buildDetailRow('Approval Status', profile.approvalStatus),
            _buildDetailRow('Rating', profile.rating.toStringAsFixed(2)),
            _buildDetailRow('Completed Trips', profile.totalTrips.toString()),
            _buildDetailRow('License Number', profile.licenseNumber),
            _buildDetailRow('License Expiry', profile.licenseExpiry.isNotEmpty ? profile.licenseExpiry : 'N/A'),
            _buildDetailRow('Insurance Expiry', profile.insuranceExpiry.isNotEmpty ? profile.insuranceExpiry : 'N/A'),
            _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
            _buildDetailRow('Registration Number', profile.vehicleNumber),
            _buildDetailRow('Vehicle Color', profile.color.isNotEmpty ? profile.color : 'N/A'),
            _buildDetailRow('Manufacturing Year', profile.manufacturingYear.toString()),
            _buildDetailRow('Vehicle Status', profile.vehicleStatus),
            _buildDetailRow('Submitted On', _formatDateTime(profile.createdAt)),
            if (profile.approvedAt != null && profile.approvedAt!.isNotEmpty)
              _buildDetailRow('Approved At', _formatDateTime(profile.approvedAt!)),
          ],
        ),
      ),
    );
  }
}
