import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    final success = await authProvider.loginWithPassword(
      phone: phone,
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
                  // Logo
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome Text
                  Text(
                    'Welcome Back 👋',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Book vehicles for moving goods anytime.',
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

                  // Input Row - Phone
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password input field label
                  Text(
                    'Password',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF6C6F79),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Input Row - Password
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: Color(0xFFA0AEC0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF121214),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFFA0AEC0),
                                fontSize: 14.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
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
                            size: 20,
                            color: const Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        authProvider.resetState();
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFE31C2E),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue Button / Loader
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
                            onPressed: () => _handleLogin(authProvider),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Login',
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

                  // Common Switch Redirect (Only shown in Mobile input state)
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A5568),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          authProvider.resetState();
                          Navigator.pushReplacementNamed(context, '/registration');
                        },
                        child: Text(
                          "Register",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFAE1220),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        authProvider.resetState();
                        Navigator.pushNamed(context, '/admin_login');
                      },
                      child: Text(
                        "Administrator Login",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFE31C2E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
