import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _resendTimer;
  int _secondsRemaining = 42;
  bool _canResend = false;
  bool _lastIsLoginOtpSent = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {});
  }

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 42;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
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
        _startTimer();
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
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP code')),
      );
      return;
    }

    final success = await authProvider.loginVerifyOtp(
      phone: _phoneController.text.trim(),
      otp: otp,
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

    // Auto-focus and timer setup when switching states
    if (authProvider.isLoginOtpSent && !_lastIsLoginOtpSent) {
      _lastIsLoginOtpSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNode.requestFocus();
        _startTimer();
      });
    } else if (!authProvider.isLoginOtpSent) {
      _lastIsLoginOtpSent = false;
      _resendTimer?.cancel();
      _resendTimer = null;
    }

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
                  if (!authProvider.isLoginOtpSent) ...[
                    // SCREEN 2: LOGIN UI
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo/logo.jpeg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Welcome Text
                    const Text(
                      'Welcome Back 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2233),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Book vehicles for moving goods anytime.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Phone input field label
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Input Row
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
                                hintText: 'Enter mobile number',
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
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFFB0B8C4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Button / Loader
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
                              onPressed: () => _handleSendOtp(authProvider),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 14),

                    // Terms text
                    const Text.rich(
                      TextSpan(
                        text: 'By continuing you agree to our ',
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF2563A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF2563A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7785),
                        height: 1.6,
                      ),
                    ),
                  ] else ...[
                    // SCREEN 3: OTP VERIFICATION UI
                    // SMS Icon container
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.message_rounded,
                          size: 28,
                          color: Color(0xFF1A3D6B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Heading & Subtext
                    const Text(
                      'Verify OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2233),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit code sent to +91 ${_phoneController.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OTP Custom 6-digit entry row (Lag-free and instantly responsive)
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Visual row of styled containers (at the bottom)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final text = _otpController.text;
                                final char = text.length > index ? text[index] : '';
                                final isFocused = _otpFocusNode.hasFocus &&
                                    (text.length == index || (text.length == 6 && index == 5));

                                return Container(
                                  width: 42,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isFocused ? const Color(0xFFE8F0FB) : const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFocused ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: isFocused ? const Color(0xFF1A3D6B) : const Color(0xFF1A2233),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // 2. Invisible TextFormField on top to receive native gestures instantly
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.01,
                                child: TextFormField(
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  showCursor: false,
                                  enableInteractiveSelection: false,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                    fontSize: 1,
                                  ),
                                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Timer / Resend Links
                    if (!_canResend) ...[
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Resend OTP in ',
                            children: [
                              TextSpan(
                                text: '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Color(0xFF2563A8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7785),
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            _handleSendOtp(authProvider);
                          },
                          child: const Text(
                            "Didn't receive? Resend OTP",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Verify Button / Loader
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
                              onPressed: () => _handleVerifyOtp(authProvider),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verify & Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
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
                        authProvider.resetState();
                        _otpController.clear();
                      },
                      child: const Text(
                        'Change Phone Number',
                        style: TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // Common Switch Redirect (Only shown in Mobile input state)
                  if (!authProvider.isLoginOtpSent) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            authProvider.resetState();
                            Navigator.pushReplacementNamed(context, '/registration');
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              color: Color(0xFF2563A8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                        child: const Text(
                          "Administrator Login",
                          style: TextStyle(
                            color: Color(0xFF1A3D6B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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
