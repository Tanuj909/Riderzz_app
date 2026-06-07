import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp(AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    final success = await authProvider.loginRequestOtp(phone);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Sent successfully!')),
        );
      }
    } else {
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!)),
        );
      }
    }
  }

  void _handleVerifyOtp(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.loginVerifyOtp(
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      size: 80,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.isLoginOtpSent
                          ? 'Enter the OTP sent to your phone'
                          : 'Login with your registered phone number',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !authProvider.isLoginOtpSent,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.phone, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white24),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.cyanAccent),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (val) =>
                                (val == null || val.length < 10) ? 'Enter valid phone number' : null,
                          ),
                          const SizedBox(height: 20),

                          if (authProvider.isLoginOtpSent) ...[
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'OTP Code',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.security, color: Colors.cyanAccent),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.cyanAccent),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (val) =>
                                  (val == null || val.isEmpty) ? 'Enter OTP code' : null,
                            ),
                            const SizedBox(height: 24),
                          ],

                          authProvider.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                                )
                              : SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor: const Color(0xFF0F2027),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: authProvider.isLoginOtpSent
                                        ? () => _handleVerifyOtp(authProvider)
                                        : () => _handleSendOtp(authProvider),
                                    child: Text(
                                      authProvider.isLoginOtpSent ? 'Verify & Login' : 'Send OTP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () {
                                  authProvider.resetState();
                                  Navigator.pushReplacementNamed(context, '/registration');
                                },
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (authProvider.isLoginOtpSent) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                authProvider.resetState();
                              },
                              child: const Text(
                                'Change Phone Number',
                                style: TextStyle(color: Colors.white70),
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
          ),
        ),
      ),
    );
  }
}
