import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  int _currentStep = 1;
  
  // Form keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _plateController = TextEditingController();
  
  String _selectedVehicleType = 'Mini';
  
  // Verification progress simulation
  String _verificationMessage = 'Uploading documents...';
  bool _isVerificationFinished = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'type': 'Bike',
      'icon': Icons.directions_bike_rounded,
      'rate': '₹8/km',
    },
    {
      'type': 'Mini',
      'icon': Icons.directions_car_rounded,
      'rate': '₹12/km',
    },
    {
      'type': 'Sedan',
      'icon': Icons.directions_car_filled_rounded,
      'rate': '₹15/km',
    },
    {
      'type': 'SUV',
      'icon': Icons.airport_shuttle_rounded,
      'rate': '₹20/km',
    },
    {
      'type': 'Truck',
      'icon': Icons.local_shipping_rounded,
      'rate': '₹30/km',
    },
  ];

  @override
  void dispose() {
    _licenseController.dispose();
    _vehicleModelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _startVerification() async {
    setState(() {
      _currentStep = 3;
      _verificationMessage = 'Uploading driving license documents...';
      _isVerificationFinished = false;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _verificationMessage = 'Analyzing license plate number...';
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _verificationMessage = 'Finalizing background verification...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isVerificationFinished = true;
    });
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2233)),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else if (_currentStep == 1) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Register as Partner',
          style: TextStyle(color: Color(0xFF1A2233), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            _buildStepIndicator(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: _buildCurrentStepView(user?.name, user?.phone),
              ),
            ),
          ],
        ),
      ),
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
          _buildStepLine(2),
          _buildStepNode(3, 'Verify'),
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
          child: isActive 
              ? const Icon(Icons.check_rounded, color: Color(0xFF1A3D6B), size: 16)
              : Text(
                  step.toString(),
                  style: const TextStyle(
                    color: Color(0xFFB0B8C4),
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

  Widget _buildCurrentStepView(String? name, String? phone) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Onboarding();
      case 2:
        return _buildStep2Form(name, phone);
      case 3:
        return _buildStep3Verification();
      default:
        return _buildStep1Onboarding();
    }
  }

  Widget _buildStep1Onboarding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              size: 64,
              color: Color(0xFF1A3D6B),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Become a Riderzz Partner 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Register your vehicle, share your details, and start taking bookings in your area. Get verified within minutes!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        
        // Perks Section
        _buildPerkRow(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Daily Payments',
          desc: 'Direct transfer to your bank account, no hidden commission fees.',
        ),
        const SizedBox(height: 16),
        _buildPerkRow(
          icon: Icons.schedule_rounded,
          title: 'Flexible Timing',
          desc: 'Turn on Driver Mode whenever you are ready to earn. Be your own boss.',
        ),
        const SizedBox(height: 16),
        _buildPerkRow(
          icon: Icons.shield_outlined,
          title: 'Safe & Insured Rides',
          desc: 'Riderzz covers support and ride assistance on every transaction.',
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
            setState(() => _currentStep = 2);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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

  Widget _buildPerkRow({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A3D6B), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFF6B7785), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form(String? name, String? phone) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle & License Info 📝',
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

          // Driving License Input
          const Text(
            'Driving License Number',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _licenseController,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: _buildInputDecoration('e.g. DL-1420261234567', Icons.badge_outlined),
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

          // Vehicle Type selection
          const Text(
            'Select Vehicle Category',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _vehicleTypes.length,
              itemBuilder: (context, index) {
                final v = _vehicleTypes[index];
                final isSelected = _selectedVehicleType == v['type'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedVehicleType = v['type']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
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
                          v['icon'] as IconData,
                          color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          v['type'] as String,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF1A2233),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v['rate'] as String,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF1A3D6B).withOpacity(0.7) : const Color(0xFFB0B8C4),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle Model Input
          const Text(
            'Vehicle Brand & Model',
            style: TextStyle(color: Color(0xFF6B7785), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vehicleModelController,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: _buildInputDecoration('e.g. Maruti Suzuki Swift / Honda Activa', Icons.car_rental_rounded),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vehicle details are required';
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
            decoration: _buildInputDecoration('e.g. DL 3C AB 1234', Icons.pin_outlined),
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
          const SizedBox(height: 32),

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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _startVerification();
              }
            },
            child: const Text(
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

  Widget _buildStep3Verification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        if (!_isVerificationFinished) ...[
          // Loading verification animations
          const Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Verifying Application...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _verificationMessage,
              key: ValueKey<String>(_verificationMessage),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7785),
                fontSize: 14,
              ),
            ),
          ),
        ] else ...[
          // Verification finished success UI
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F9B6E), width: 1.5),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF0F9B6E),
              ),
            ),
          ),
          const SizedBox(height: 30),
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
          const SizedBox(height: 40),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9B6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _handleRoleTransition,
            child: const Text(
              'Enter Driver Mode',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}
