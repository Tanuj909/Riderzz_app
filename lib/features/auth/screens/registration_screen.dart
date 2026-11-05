import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/auth/widgets/animated_speed_logo.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPhoneValidated = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
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
    final password = _passwordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
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
      email: '${phone.trim()}@riderzz.com',
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
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62E42).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                            const Icon(Icons.arrow_forward_rounded, size: 17),
                            const SizedBox(width: 8),
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
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
                    const SizedBox(height: 4),
                    Text(
                      'Enter your details to create your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF6C6F79),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Summary Banner
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFFC62E42)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '+91 ${_phoneController.text}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
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
                                color: const Color(0xFFC62E42),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name Input
                    Text(
                      'Full Name',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFFA0AEC0),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password Input
                    Text(
                      'Password',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF121214),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter password (6+ chars)',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFFA0AEC0),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFFA0AEC0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Button / Loader
                    authProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC62E42)),
                            ),
                          )
                        : Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC62E42).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
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
                                  const Icon(Icons.check_rounded, size: 17),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Register',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
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
                        '',
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
