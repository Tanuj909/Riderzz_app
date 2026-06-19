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
  
  // Document text inputs (pre-filled for premium user convenience)
  final _aadharController = TextEditingController(text: 'https://cdn.riderzz.com/docs/aadhar.pdf');
  final _panController = TextEditingController(text: 'https://cdn.riderzz.com/docs/pan.pdf');
  final _dlDocController = TextEditingController(text: 'https://cdn.riderzz.com/docs/license.pdf');

  AvailableVehicleModel? _selectedVehicle;

  // Image picker and picked file references
  final ImagePicker _picker = ImagePicker();
  XFile? _aadharFile;
  XFile? _panFile;
  XFile? _dlFile;

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
    _aadharController.dispose();
    _panController.dispose();
    _dlDocController.dispose();
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
      if (_aadharController.text.trim().isEmpty ||
          _panController.text.trim().isEmpty ||
          _dlDocController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload all required documents.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final body = {
        "vehicle": {
          "id": _selectedVehicle!.id,
          "vehicleTypeId": _selectedVehicle!.vehicleTypeId,
          "vehicleTypeName": _selectedVehicle!.vehicleTypeName,
          "make": _selectedVehicle!.make,
          "model": _selectedVehicle!.model,
          "vehicleNumber": _plateController.text.trim(),
          "perKmRate": _selectedVehicle!.perKmRate,
          "status": "APPROVED",
          "existing": true
        },
        "documents": [
          {
            "documentType": "AADHAR",
            "fileUrl": _aadharController.text.trim()
          },
          {
            "documentType": "PAN",
            "fileUrl": _panController.text.trim()
          },
          {
            "documentType": "DRIVING_LICENSE",
            "fileUrl": _dlDocController.text.trim()
          }
        ],
        "licenseNumber": _licenseController.text.trim(),
        "vehicleNumber": _plateController.text.trim()
      };

      final success = await provider.applyAsDriver(body);
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
          _aadharFile = null;
          _panFile = null;
          _dlFile = null;
          _aadharController.text = 'https://cdn.riderzz.com/docs/aadhar.pdf';
          _panController.text = 'https://cdn.riderzz.com/docs/pan.pdf';
          _dlDocController.text = 'https://cdn.riderzz.com/docs/license.pdf';
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

  Future<void> _pickDocument(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (type == 'AADHAR') {
            _aadharFile = image;
            _aadharController.text = 'https://cdn.riderzz.com/docs/uploaded_${image.name}';
          } else if (type == 'PAN') {
            _panFile = image;
            _panController.text = 'https://cdn.riderzz.com/docs/uploaded_${image.name}';
          } else if (type == 'DL') {
            _dlFile = image;
            _dlDocController.text = 'https://cdn.riderzz.com/docs/uploaded_${image.name}';
          }
        });
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

  Widget _buildDocumentUploadCard({
    required String title,
    required String documentType,
    required XFile? pickedFile,
    required String defaultUrl,
    required VoidCallback onTap,
  }) {
    final String defaultFileName = defaultUrl.split('/').last;
    final hasFile = pickedFile != null;
    final displayName = hasFile ? pickedFile.name : '$defaultFileName (Auto-attached)';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
          width: hasFile ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFE8F0FB) : const Color(0xFFE9ECF0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasFile ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
              color: hasFile ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
              size: 20,
            ),
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
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasFile ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasFile ? const Color(0xFFE8F0FB) : const Color(0xFF1A3D6B),
              foregroundColor: hasFile ? const Color(0xFF1A3D6B) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap,
            child: Text(
              hasFile ? 'Change' : 'Upload',
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
            title: 'Aadhar Card',
            documentType: 'AADHAR',
            pickedFile: _aadharFile,
            defaultUrl: _aadharController.text,
            onTap: () => _pickDocument('AADHAR'),
          ),

          _buildDocumentUploadCard(
            title: 'PAN Card',
            documentType: 'PAN',
            pickedFile: _panFile,
            defaultUrl: _panController.text,
            onTap: () => _pickDocument('PAN'),
          ),

          _buildDocumentUploadCard(
            title: 'Driving License',
            documentType: 'DL',
            pickedFile: _dlFile,
            defaultUrl: _dlDocController.text,
            onTap: () => _pickDocument('DL'),
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
      return _buildRejectedUI(profile);
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
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 64,
                color: Color(0xFFF97316),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Application Pending Review ⏳',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your application to become a driver partner has been received and is currently under review by our admin team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

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
                if (profile.vehicle != null) ...[
                  _buildDetailRow('Vehicle Type', profile.vehicle!.vehicleTypeName),
                  _buildDetailRow('Vehicle Make/Model', '${profile.vehicle!.make} ${profile.vehicle!.model}'),
                ],
                _buildDetailRow('Documents Status', '${profile.documents.length} Uploaded (Pending Verification)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // View All Details Button
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
          const SizedBox(height: 16),

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
                      _buildDetailRow('User Status', profile.userStatus),
                      _buildDetailRow('Approval Status', profile.approvalStatus),
                      _buildDetailRow('License Number', profile.licenseNumber),
                      _buildDetailRow('Rating', profile.rating.toStringAsFixed(2)),
                      _buildDetailRow('Total Trips', profile.totalTrips.toString()),
                      _buildDetailRow('Submitted On', _formatDateTime(profile.createdAt)),

                      const SizedBox(height: 24),

                      // Vehicle Info
                      _buildSectionHeader('Vehicle Information', Icons.directions_car_outlined),
                      const SizedBox(height: 12),
                      _buildDetailRow('License Plate Number', profile.vehicleNumber),
                      if (profile.vehicle != null) ...[
                        _buildDetailRow('Vehicle Category', profile.vehicle!.vehicleTypeName),
                        _buildDetailRow('Make', profile.vehicle!.make),
                        _buildDetailRow('Model', profile.vehicle!.model),
                        _buildDetailRow('Per Km Rate', '₹${profile.vehicle!.perKmRate.toStringAsFixed(2)}'),
                        _buildDetailRow('Max Weight', '${profile.vehicle!.maxWeightKg} Kg'),
                        _buildDetailRow('Vehicle Status', profile.vehicle!.status),
                        if (profile.vehicle!.approvedAt != null)
                          _buildDetailRow('Approved At', _formatDateTime(profile.vehicle!.approvedAt!)),
                      ],

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
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F7F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF0F9B6E),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Application Approved! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Congratulations, your driver partner registration is complete. Click below to launch your Driver dashboard and start earning.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

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
                if (profile.vehicle != null) ...[
                  _buildDetailRow('Vehicle Category', profile.vehicle!.vehicleTypeName),
                  _buildDetailRow('Vehicle Model', '${profile.vehicle!.make} ${profile.vehicle!.model}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 36),

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

  Widget _buildRejectedUI(DriverProfileModel profile) {
    final String rejectionReason = profile.vehicle?.rejectionReason ?? 'Submitted document(s) were invalid or illegible.';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Application Rejected ❌',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Unfortunately, your application to become a driver partner has been rejected due to the following reason:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              height: 1.5,
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
}
