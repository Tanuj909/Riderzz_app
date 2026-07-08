import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {});
  }

  void _handleSendOtp(AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    final success = await authProvider.requestOtp(phone);
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

  void _handleRegister(AuthProvider authProvider) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final otp = _otpController.text.trim();

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

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP code')),
      );
      return;
    }

    final success = await authProvider.registerUser(
      name: name,
      phone: phone,
      password: password,
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
                  if (!authProvider.isOtpSent) ...[
                    // REGISTRATION: PHONE STATE
                    const AnimatedSpeedLogo(),
                    const SizedBox(height: 24),

                    // Title & Subtext
                    const Text(
                      'Create Account 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your phone number to get started.',
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
                        color: Color(0xFF6C6F79),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Input Row
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEBEC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: const Text(
                              '🇮🇳 +91',
                              style: TextStyle(
                                color: Color(0xFFE31C2E),
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
                                color: Color(0xFF121214),
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

                    // Action Button / Loader
                    authProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                            ),
                          )
                        : SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
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
                              color: Color(0xFFAE1220),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFFAE1220),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C6F79),
                        height: 1.6,
                      ),
                    ),
                  ] else ...[
                    // REGISTRATION: DETAILS STATE
                    // SMS Icon container
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBEC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.message_rounded,
                          size: 28,
                          color: Color(0xFFE31C2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Heading & Subtext
                    const Text(
                      'Complete Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter details and the 6-digit code sent to +91 ${_phoneController.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Input
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C6F79),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Color(0xFF121214),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C6F79),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Color(0xFF121214),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter password (6+ chars)',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Verification Code Label
                    const Text(
                      'Verification Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C6F79),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // OTP Custom 6-digit entry row (Lag-free and responsive)
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                                    color: isFocused ? const Color(0xFFFDEBEC) : const Color(0xFFF6F6F8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFocused ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: isFocused ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                                    ),
                                  ),
                                );
                              }),
                            ),
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

                    // Action Button / Loader
                    authProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                            ),
                          )
                        : SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _handleRegister(authProvider),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verify & Register',
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
                          color: Color(0xFF6C6F79),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // Redirect to Login (Only shown in initial state)
                  if (!authProvider.isOtpSent) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            authProvider.resetState();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFFAE1220),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
    // Start the animation loop after 600ms delay to let screen transition finish.
    // While waiting, the logo is positioned at Offset(1.5, 0.0) which is off-screen.
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
