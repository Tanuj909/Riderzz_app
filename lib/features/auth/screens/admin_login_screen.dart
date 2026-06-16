import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAdminLogin(AuthProvider authProvider) async {
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

    final success = await authProvider.adminLogin(
      phone: phone,
      password: password,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin authentication successful!')),
        );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2233), size: 20),
          onPressed: () {
            authProvider.resetState();
            Navigator.pop(context);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Admin Security Shield Icon with Cyan Accent Glow
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FB),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 44,
                        color: Color(0xFF1A3D6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Heading Text
                  const Text(
                    'Administrator Access 🔐',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2233),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authorized administrative personnel only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7785),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Phone number field label
                  const Text(
                    'Admin Mobile Number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7785),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phone Input Row
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      border: Border.all(color: const Color(0xFFE9ECF0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Text(
                            '🇮🇳 +91',
                            style: TextStyle(
                              color: Color(0xFF1A3D6B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Color(0xFF1A2233),
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter admin mobile number',
                              hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
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
                  const SizedBox(height: 20),

                  // Password field label
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7785),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Password Input Box
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      border: Border.all(color: const Color(0xFFE9ECF0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        color: Color(0xFF1A2233),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        hintStyle: const TextStyle(color: Color(0xFFB0B8C4)),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: const Color(0xFFB0B8C4),
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button / Loader
                  authProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                          ),
                        )
                      : SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3D6B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _handleAdminLogin(authProvider),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.login_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Secure Login',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Cancel/Back Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        authProvider.resetState();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel & Return to User Login",
                        style: TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
