import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPhoneValidated = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndContinuePhone() {
    final phone = _phoneController.text.trim();

    // Check if phone number is a valid 10-digit Indian mobile number (starts with 6, 7, 8, or 9)
    final indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (phone.isEmpty || !indianPhoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit Indian phone number'),
        ),
      );
      return;
    }

    setState(() {
      _isPhoneValidated = true;
    });
  }

  void _handleRegister(AuthProvider authProvider) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final success = await authProvider.registerUserNoOtp(
      fullName: name,
      phone: phone,
      email: email,
      password: password,
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/role_redirect');
      }
    } else {
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isPhoneValidated) ...[
                    // REGISTRATION STEP 1: PHONE NUMBER INPUT & INDIAN NUMBER CHECK
                    const AnimatedSpeedLogo(),
                    const SizedBox(height: 24),

                    // Title & Subtext
                    Text(
                      'Create Account 👋',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter your phone number to get started.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF6C6F79),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Phone input field label
                    Text(
                      'Mobile Number',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Input Row
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEBEC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(
                              '🇮🇳 +91',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFE31C2E),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter mobile number',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFFA0AEC0),
                                  fontSize: 14.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFFA0AEC0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31C2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: _validateAndContinuePhone,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Terms text
                    Text.rich(
                      TextSpan(
                        text: 'By continuing you agree to our ',
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFAE1220),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFAE1220),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: const Color(0xFF6C6F79),
                        height: 1.6,
                      ),
                    ),
                  ] else ...[
                    // REGISTRATION STEP 2: USER DETAILS INPUT (NO OTP)
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBEC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 28,
                          color: Color(0xFFE31C2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Heading & Subtext
                    Text(
                      'Complete Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your details to create your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF6C6F79),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Summary Banner
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFFE31C2E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🇮🇳 +91 ${_phoneController.text}',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF121214),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPhoneValidated = false;
                              });
                            },
                            child: Text(
                              'Change',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE31C2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name Input
                    Text(
                      'Full Name',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFFA0AEC0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Address Input
                    Text(
                      'Email Address (Optional)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFFA0AEC0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    Text(
                      'Password',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF121214),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password (6+ chars)',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFFA0AEC0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button / Loader
                    authProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                            ),
                          )
                        : SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: () => _handleRegister(authProvider),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Register',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),

                    // Back / Change Number Button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isPhoneValidated = false;
                        });
                      },
                      child: Text(
                        'Change Phone Number',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C6F79),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Redirect to Login (Only shown in initial state)
                  if (!_isPhoneValidated) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            authProvider.resetState();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            "Login",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFAE1220),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedSpeedLogo extends StatefulWidget {
  const AnimatedSpeedLogo({super.key});

  @override
  State<AnimatedSpeedLogo> createState() => _AnimatedSpeedLogoState();
}

class _AnimatedSpeedLogoState extends State<AnimatedSpeedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600), // 3.6s total loop time
    );

    _animation = TweenSequence<Offset>([
      // 1. Slide in from right (takes 800ms)
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: const Offset(1.5, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22.0,
      ),
      // 2. Pause in center (stays 2000ms)
      TweenSequenceItem<Offset>(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 56.0,
      ),
      // 3. Slide out to left (takes 800ms)
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.5, 0.0),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 22.0,
      ),
    ]).animate(_controller);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SlideTransition(
        position: _animation,
        child: Image.asset(
          'assets/images/logo/logo.jpeg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
