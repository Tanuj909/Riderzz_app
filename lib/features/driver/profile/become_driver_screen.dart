import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';

class _DriverVehicleCategoryItem {
  final String key;
  final String title;
  final String subtitle;
  final String assetPath;

  const _DriverVehicleCategoryItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

const List<_DriverVehicleCategoryItem> _kDriverVehicleCategories = [
  _DriverVehicleCategoryItem(
    key: 'TWO_WHEELER',
    title: '2 Wheeler',
    subtitle: 'Bike & Scooter',
    assetPath: 'assets/category/two_wheeler.png',
  ),
  _DriverVehicleCategoryItem(
    key: 'THREE_WHEELER',
    title: '3 Wheeler',
    subtitle: 'Auto & 3-Wheeler',
    assetPath: 'assets/category/three_wheeler.png',
  ),
  _DriverVehicleCategoryItem(
    key: 'FOUR_WHEELER',
    title: '4 Wheeler',
    subtitle: 'Cab & Mini Van',
    assetPath: 'assets/category/four_wheeler.png',
  ),
  _DriverVehicleCategoryItem(
    key: 'TRUCK',
    title: 'Truck',
    subtitle: 'Mini & Heavy Truck',
    assetPath: 'assets/category/truck.png',
  ),
];

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

  VehicleTypeModel? _selectedVehicle;
  String _selectedCategoryKey = 'TWO_WHEELER';
  bool _isLoadingCategoryVehicles = false;
  List<VehicleTypeModel> _categoryVehicles = [];

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
      provider.fetchDriverProfile(force: true);
      Provider.of<AdminVehiclesProvider>(context, listen: false).fetchVehicleTypes().then((_) {
        _onCategorySelected(_selectedCategoryKey);
      });
    });
  }

  void _onCategorySelected(String categoryKey) async {
    setState(() {
      _selectedCategoryKey = categoryKey;
      _isLoadingCategoryVehicles = true;
    });

    final provider = Provider.of<AdminVehiclesProvider>(context, listen: false);
    List<VehicleTypeModel> list = [];
    try {
      list = await provider.fetchVehiclesByCategory(categoryKey);
    } catch (e) {
      debugPrint('fetchVehiclesByCategory error: $e');
    }

    if (list.isEmpty) {
      list = provider.vehicleTypes.where((v) {
        final cat = (v.category ?? '').toUpperCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
        final name = v.name.toUpperCase();
        if (categoryKey == 'TWO_WHEELER') {
          return cat.contains('TWO') || cat.contains('2_WHEEL') || name.contains('BIKE') || name.contains('SCOOT') || name.contains('2W');
        } else if (categoryKey == 'THREE_WHEELER') {
          return cat.contains('THREE') || cat.contains('3_WHEEL') || name.contains('AUTO') || name.contains('RICKSHAW') || name.contains('3W');
        } else if (categoryKey == 'FOUR_WHEELER') {
          return cat.contains('FOUR') || cat.contains('4_WHEEL') || name.contains('CAR') || name.contains('CAB') || name.contains('SEDAN') || name.contains('SUV') || name.contains('MINI') || name.contains('4W');
        } else if (categoryKey == 'TRUCK') {
          return cat.contains('TRUCK') || cat.contains('COMMERCIAL') || name.contains('TRUCK') || name.contains('ACE') || name.contains('GOODS') || name.contains('PICKUP');
        }
        return false;
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _categoryVehicles = list;
      _isLoadingCategoryVehicles = false;
      if (_selectedVehicle == null || !_categoryVehicles.any((v) => v.id == _selectedVehicle!.id)) {
        if (_categoryVehicles.isNotEmpty) {
          _selectedVehicle = _categoryVehicles.first;
        } else {
          _selectedVehicle = null;
        }
      }
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

  void _showCustomSnackBar({
    required String title,
    String? message,
    required Color primaryColor,
    required IconData icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (message != null && message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String title, [String? message]) {
    _showCustomSnackBar(
      title: title,
      message: message,
      primaryColor: const Color(0xFF10B981),
      icon: Icons.check_circle_rounded,
    );
  }

  void _showErrorSnackBar(String title, [String? message]) {
    _showCustomSnackBar(
      title: title,
      message: message,
      primaryColor: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
    );
  }

  void _showWarningSnackBar(String title, [String? message]) {
    _showCustomSnackBar(
      title: title,
      message: message,
      primaryColor: const Color(0xFFF59E0B),
      icon: Icons.warning_amber_rounded,
    );
  }

  void _submitApplication(DriverHomeProvider provider) async {
    if (_selectedVehicle == null) {
      _showWarningSnackBar(
        'Vehicle Required',
        'Please select a vehicle category first.',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
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
        _showSuccessSnackBar(
          'Registered Successfully!',
          'Your driver application has been submitted for review.',
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
        _showErrorSnackBar(
          'Submission Failed',
          provider.errorMessage ?? 'Please try again.',
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
      _showErrorSnackBar(
        'Action Failed',
        authProvider.errorMessage ?? 'Failed to activate Driver Mode. Try again.',
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
            _showSuccessSnackBar(
              'Document Uploaded',
              '$type uploaded successfully!',
            );
          } else if (mounted) {
            _showErrorSnackBar(
              'Upload Failed',
              provider.errorMessage ?? 'Failed to upload $type. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        'Document Selection Failed',
        e.toString(),
      );
    }
  }

  Future<String> _getUploadPath(XFile? file, String prefix) async {
    if (file == null) return '';
    return file.path;
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
    Color cardBorderColor = const Color(0xFFE7E7EB);
    double cardBorderWidth = 1.0;
    Color iconBgColor = const Color(0xFFF1F1F4);
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
        cardBgColor = const Color(0xFFFDEBEC);
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
        borderRadius: BorderRadius.circular(24),
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
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
                            color: statusBadgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: (hasFile || existingDoc != null) ? const Color(0xFF334155) : const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                if (existingDoc != null && existingDoc.status.toUpperCase() == 'REJECTED' && existingDoc.rejectionReason != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Reason: ${existingDoc.rejectionReason}',
                    style: GoogleFonts.poppins(
                      color: Color(0xFFB91C1C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (hasFile || existingDoc != null) ? const Color(0xFFEFF6FF) : const Color(0xFFE31C2E),
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
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(
      int.tryParse(_yearController.text) ?? now.year,
      1,
      1,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1980),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
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

    if (picked != null) {
      setState(() {
        _yearController.text = picked.year.toString();
      });
    }
  }

  Future<void> _selectLicenseExpiry(BuildContext context) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 365));
    if (_licenseExpiryController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_licenseExpiryController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
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

    if (picked != null) {
      setState(() {
        _licenseExpiryController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectInsuranceExpiry(BuildContext context) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 365));
    if (_insuranceExpiryController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_insuranceExpiryController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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

    if (picked != null) {
      setState(() {
        _insuranceExpiryController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    Widget bodyWidget;

    if (driverProvider.isLoading && profile == null) {
      bodyWidget = Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
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
          icon: Icon(Icons.arrow_back_rounded, color: Color(0xFF121214)),
          onPressed: () {
            if (profile == null && _currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Register as Driver',
          style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 18, fontWeight: FontWeight.bold),
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
        SizedBox(height: 14),
        _buildStepIndicator(),
        SizedBox(height: 24),
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
            color: isActive ? const Color(0xFFFDEBEC) : const Color(0xFFF6F6F8),
            border: Border.all(
              color: isActive ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
              width: 1.5,
            ),
            boxShadow: isCurrent 
                ? [BoxShadow(color: const Color(0xFFE31C2E).withOpacity(0.1), blurRadius: 6, spreadRadius: 1)]
                : [],
          ),
          alignment: Alignment.center,
          child: isActive && _currentStep > step
              ? Icon(Icons.check_rounded, color: Color(0xFFE31C2E), size: 16)
              : Text(
                  step.toString(),
                  style: GoogleFonts.poppins(
                    color: isActive ? const Color(0xFFE31C2E) : const Color(0xFFB0B8C4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? const Color(0xFF121214) : const Color(0xFFB0B8C4),
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
        color: isPassed ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
      ),
    );
  }

  Widget _buildStep1Onboarding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12),
        Text(
          'Registration Form',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Color(0xFF121214),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Register your vehicle, share your details, and start taking bookings in your area. Get verified within minutes!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Color(0xFF4A5568),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 24),
        
        // Perks Section (Grouped in a single clean modern Card container to fit without scrolling)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7E7EB)),
          ),
          child: Column(
            children: [
              _buildPerkRowSimple(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Daily Payments',
                desc: 'Direct transfer to your bank account with complete transparency on every payout.',
              ),
              const Divider(height: 28, color: Color(0xFFE7E7EB), thickness: 1),
              _buildPerkRowSimple(
                icon: Icons.schedule_rounded,
                title: 'Flexible Timing',
                desc: 'Turn on Driver Mode whenever you are ready to earn. Be your own boss.',
              ),
              const Divider(height: 28, color: Color(0xFFE7E7EB), thickness: 1),
              _buildPerkRowSimple(
                icon: Icons.shield_outlined,
                title: 'Safe & Supported Rides',
                desc: 'Riderzz covers support and ride assistance on every transaction.',
              ),
            ],
          ),
        ),
        
        SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31C2E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
          onPressed: () {
            setState(() => _currentStep = 2);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Application',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
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
            color: const Color(0xFFFDEBEC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFE31C2E), size: 18),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Color(0xFF121214),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  color: Color(0xFF6C6F79),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle & License Info',
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Provide accurate details so our admin team can approve your application quickly.',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 13),
          ),
          SizedBox(height: 20),

          // User Personal Info (Read-only)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E7EB)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: Color(0xFFB0B8C4), size: 20),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Applicant Name',
                      style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      phone ?? '+91 9999999999',
                      style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F7EF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Verified Profile',
                    style: GoogleFonts.poppins(color: Color(0xFF1C9A5B), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Select Available Vehicle Category
          Text(
            'Select Vehicle Category',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),

          // 4 Category Cards in sequence (TWO_WHEELER, THREE_WHEELER, FOUR_WHEELER, TRUCK)
          SizedBox(
            height: 106,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _kDriverVehicleCategories.length,
              itemBuilder: (context, index) {
                final cat = _kDriverVehicleCategories[index];
                final isSelected = _selectedCategoryKey == cat.key;

                return GestureDetector(
                  onTap: () => _onCategorySelected(cat.key),
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 86,
                          height: 66,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFDEBEC) : const Color(0xFFF6F6F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
                              width: isSelected ? 2.0 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE31C2E).withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Image.asset(
                              cat.assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.local_shipping_rounded,
                                size: 32,
                                color: Color(0xFFE31C2E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Sub-section: Select Specific Vehicle of chosen category
          Text(
            'Select Vehicle Model',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          if (_isLoadingCategoryVehicles) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading available vehicles...',
                    style: GoogleFonts.poppins(color: const Color(0xFF6C6F79), fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else if (_categoryVehicles.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                'No vehicle models available for this category.',
                style: GoogleFonts.poppins(color: const Color(0xFFC2410C), fontSize: 12),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 106,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryVehicles.length,
                itemBuilder: (context, index) {
                  final vt = _categoryVehicles[index];
                  final isSelected = _selectedVehicle?.id == vt.id;

                  final categoryAsset = _kDriverVehicleCategories
                      .firstWhere(
                        (c) => c.key == _selectedCategoryKey,
                        orElse: () => _kDriverVehicleCategories.first,
                      )
                      .assetPath;

                  Widget vehicleImageWidget;
                  if (vt.iconUrl != null && vt.iconUrl!.isNotEmpty) {
                    vehicleImageWidget = Image.network(
                      vt.iconUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        categoryAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFFE31C2E),
                          size: 30,
                        ),
                      ),
                    );
                  } else {
                    vehicleImageWidget = Image.asset(
                      categoryAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_shipping_rounded,
                        color: Color(0xFFE31C2E),
                        size: 30,
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedVehicle = vt);
                    },
                    child: Container(
                      width: 86,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 86,
                            height: 66,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFDEBEC) : const Color(0xFFF6F6F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
                                width: isSelected ? 2.0 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE31C2E).withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: vehicleImageWidget,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vt.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              height: 1.2,
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
          SizedBox(height: 20),

          // Driving License Input
          Text(
            'Driving License Number',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _licenseController,
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
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
          SizedBox(height: 20),

          // Vehicle Plate Number Input
          Text(
            'Vehicle Plate Number',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _plateController,
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
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
          SizedBox(height: 20),

          // Vehicle Color and Manufacturing Year
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Color',
                      style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _colorController,
                      style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                      decoration: _buildInputDecoration('e.g. White', Icons.color_lens_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Color is required' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manufacturing Year',
                      style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _yearController,
                      readOnly: true,
                      onTap: () => _selectYear(context),
                      style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                      decoration: _buildInputDecoration('Select Year', Icons.calendar_today_outlined),
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
          SizedBox(height: 20),

          // License Expiry and Insurance Expiry Dates
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License Expiry',
                      style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _licenseExpiryController,
                      readOnly: true,
                      onTap: () => _selectLicenseExpiry(context),
                      style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                      decoration: _buildInputDecoration('Select Expiry Date', Icons.date_range_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Expiry required' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insurance Expiry',
                      style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _insuranceExpiryController,
                      readOnly: true,
                      onTap: () => _selectInsuranceExpiry(context),
                      style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                      decoration: _buildInputDecoration('Select Expiry Date', Icons.date_range_outlined),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Expiry required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Driver Bio
          Text(
            'Short Bio / Experience',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 2,
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
            decoration: _buildInputDecoration('Describe your experience...', Icons.info_outline),
            validator: (value) => value == null || value.trim().isEmpty ? 'Bio is required' : null,
          ),
          SizedBox(height: 20),

          // Gender Selection Dropdown
          Text(
            'Gender',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration('Select Gender', Icons.people_outline),
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C6F79)),
            isExpanded: true,
            borderRadius: BorderRadius.circular(24),
            items: [
              DropdownMenuItem(
                value: 'MALE',
                child: Text('Male', style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14)),
              ),
              DropdownMenuItem(
                value: 'FEMALE',
                child: Text('Female', style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14)),
              ),
              DropdownMenuItem(
                value: 'OTHER',
                child: Text('Other', style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14)),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedGender = val;
                });
              }
            },
          ),
          SizedBox(height: 24),

          // Upload Document Cards section
          Text(
            'Upload Verification Documents 📁',
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Upload your actual documents from your gallery to verify your profile:',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 11),
          ),
          SizedBox(height: 16),

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
          SizedBox(height: 16),

          // Submit button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => _submitApplication(driverProvider),
            child: driverProvider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit Application',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Color(0xFFB0B8C4), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFB0B8C4), size: 20),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Pending Review',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF0369A1),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your details and documents are under review. We will notify you once approved.',
                        style: GoogleFonts.poppins(
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
          SizedBox(height: 20),

          // Submitted Details Card
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
                Text(
                  'Submitted Application Details',
                  style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20, color: Color(0xFFE7E7EB)),
                _buildDetailRow('Submission Date', _formatDateTime(profile.createdAt)),
                _buildDetailRow('License Number', profile.licenseNumber),
                _buildDetailRow('Vehicle Plate Number', profile.vehicleNumber),
                _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
                _buildDetailRow('Documents Status', '${profile.documents.length} Uploaded (Pending Verification)'),
              ],
            ),
          ),
          _buildCollapsibleProfileDetails(profile),
          SizedBox(height: 24),

          // Document section header
          Text(
            'Verification Documents 📁',
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Check the status or re-upload documents if required:',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 11),
          ),
          SizedBox(height: 16),

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
          SizedBox(height: 24),

          // Grouped Buttons at the Bottom
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            icon: Icon(Icons.edit_rounded, size: 18),
            label: Text('Update Profile Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          SizedBox(height: 12),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE31C2E)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () => _showAllDetailsBottomSheet(profile),
            icon: Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFE31C2E)),
            label: Text(
              'View All Details',
              style: GoogleFonts.poppins(color: Color(0xFFE31C2E), fontSize: 14, fontWeight: FontWeight.w600),
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
                    color: const Color(0xFFE7E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Application Details',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF121214),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFE7E7EB)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Applicant Info
                      _buildSectionHeader('Applicant Information', Icons.person_outline_rounded),
                      SizedBox(height: 12),
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

                      SizedBox(height: 24),

                      // Vehicle Info
                      _buildSectionHeader('Vehicle Information', Icons.directions_car_outlined),
                      SizedBox(height: 12),
                      _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
                      _buildDetailRow('Registration Number', profile.vehicleNumber),
                      _buildDetailRow('Vehicle Color', profile.color.isNotEmpty ? profile.color : 'N/A'),
                      _buildDetailRow('Manufacturing Year', profile.manufacturingYear.toString()),
                      _buildDetailRow('Vehicle Status', profile.vehicleStatus),

                      SizedBox(height: 24),

                      // Documents Info
                      _buildSectionHeader('Verification Documents', Icons.folder_open_outlined),
                      SizedBox(height: 12),
                      if (profile.documents.isEmpty)
                        Text(
                          'No documents uploaded.',
                          style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 13),
                        )
                      else
                        ...profile.documents.map((doc) => _buildDocumentItem(doc)),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31C2E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.edit_rounded, size: 18),
                        label: Text('Edit Profile Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                            color: const Color(0xFFE7E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profile Details',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF121214),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Color(0xFFE7E7EB)),
                      SizedBox(height: 12),

                      // License Number
                      Text(
                        'License Number',
                        style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: licenseController,
                        style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                        decoration: _buildInputDecoration('License Number', Icons.badge_outlined),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),

                      // DOB
                      Text(
                        'Date of Birth',
                        style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: dobController,
                        style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                        decoration: _buildInputDecoration('YYYY-MM-DD', Icons.date_range_outlined),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),

                      // Gender
                      Text(
                        'Gender',
                        style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: genderValue,
                        style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
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
                      SizedBox(height: 16),

                      // Bio
                      Text(
                        'Bio / Experience',
                        style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: bioController,
                        maxLines: 2,
                        style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14),
                        decoration: _buildInputDecoration('Short Bio', Icons.info_outline),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE7E7EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () => Navigator.pop(context),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                  if (success) {
                                    _showSuccessSnackBar('Profile Updated', 'Your profile details have been saved successfully.');
                                  } else {
                                    _showErrorSnackBar('Update Failed', provider.errorMessage ?? 'Please try again.');
                                  }
                                }
                              },
                              child: isSaving
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
        Icon(icon, color: const Color(0xFFE31C2E), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Color(0xFF121214),
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
      statusColor = const Color(0xFF1C9A5B);
    } else if (doc.status.toUpperCase() == 'REJECTED') {
      statusColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doc.docType.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Color(0xFF121214),
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
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          InkWell(
            onTap: () {
              // Clickable link behavior, or copy to clipboard
            },
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: Color(0xFFE31C2E), size: 14),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doc.fileUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Color(0xFFE31C2E),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (doc.rejectionReason != null && doc.rejectionReason!.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              'Reason: ${doc.rejectionReason}',
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          SizedBox(height: 6),
          Text(
            'Uploaded: ${_formatDateTime(doc.uploadedAt)}',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 10),
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
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
                        style: GoogleFonts.poppins(
                          color: Color(0xFF166534),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Congratulations, your driver partner registration is complete. Welcome to the Riderzz network.',
                        style: GoogleFonts.poppins(
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
          SizedBox(height: 24),

          // Approved details summary
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
                Text(
                  'Approved Partner Details',
                  style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20, color: Color(0xFFE7E7EB)),
                _buildDetailRow('Submission Date', _formatDateTime(profile.createdAt)),
                _buildDetailRow('License Number', profile.licenseNumber),
                _buildDetailRow('Vehicle Plate', profile.vehicleNumber),
                _buildDetailRow('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : (profile.vehicle?.vehicleTypeName ?? 'N/A')),
              ],
            ),
          ),
          _buildCollapsibleProfileDetails(profile),
          SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            icon: Icon(Icons.edit_rounded, size: 18),
            label: Text('Update Profile Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C9A5B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: _handleRoleTransition,
            child: Text(
              userRole == 'ROLE_DRIVER' ? 'Go to Dashboard' : 'Enter Driver Mode',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
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
              color: const Color(0xFFFDEBEC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Row(
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
                        style: GoogleFonts.poppins(
                          color: Color(0xFF991B1B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please check the status of each document and re-upload rejected or missing ones.',
                        style: GoogleFonts.poppins(
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
          SizedBox(height: 20),

          // Rejection Reason Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBEC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejection Reason',
                        style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        rejectionReason,
                        style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
          Text(
            'Verification Documents 📁',
            style: GoogleFonts.poppins(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Please update/re-upload any rejected documents below:',
            style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 11),
          ),
          SizedBox(height: 16),

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
          SizedBox(height: 24),
          _buildCollapsibleProfileDetails(profile),
          SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            icon: Icon(Icons.edit_rounded, size: 18),
            label: Text('Update Profile Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            onPressed: () => _showEditProfileBottomSheet(profile),
          ),
          SizedBox(height: 36),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                _forceShowForm = true;
                _currentStep = 2; // Jump directly to form
              });
            },
            child: Text(
              'Modify & Re-apply',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
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
              style: GoogleFonts.poppins(color: Color(0xFF6C6F79), fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                color: Color(0xFF121214),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.info_outline_rounded, color: Color(0xFFE31C2E)),
          title: Text(
            'View Full Profile Details',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
          ),
          subtitle: Text(
            'Tap to view dates, bio, gender, color etc.',
            style: GoogleFonts.poppins(fontSize: 10, color: Color(0xFF6C6F79)),
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
