import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/auth/screens/login_screen.dart';
import 'package:riderzz_app/features/user/home/user_home_screen.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/admin/dashboard/admin_dashboard_screen.dart';

class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleAndRedirect();
    });
  }

  void _navigateTo(Widget page, String routeName) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  void _checkRoleAndRedirect() async {
    final startTime = DateTime.now();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Run auth check and location initialization in parallel
    late final bool isLoggedIn;
    await Future.wait([
      authProvider.tryAutoLogin().then((v) => isLoggedIn = v),
      locationProvider.initialize(),
    ]);

    final elapsedTime = DateTime.now().difference(startTime);
    final remainingTime = const Duration(milliseconds: 1800) - elapsedTime;
    
    if (remainingTime > Duration.zero) {
      await Future.delayed(remainingTime);
    }

    if (!mounted) return;

    if (isLoggedIn && authProvider.currentUser != null) {
      final role = authProvider.currentUser!.role;
      if (role == 'ROLE_USER' || role == 'CUSTOMER' || role == 'ROLE_CUSTOMER') {
        _navigateTo(const UserHomeScreen(), '/user_home');
      } else if (role == 'ROLE_DRIVER' || role == 'DRIVER') {
        _navigateTo(const DriverHomeScreen(), '/driver_home');
      } else if (role == 'ADMIN' || role == 'ROLE_ADMIN') {
        _navigateTo(const AdminDashboardScreen(), '/admin_dashboard');
      } else {
        _navigateTo(const UserHomeScreen(), '/user_home');
      }
    } else {
      _navigateTo(const LoginScreen(), '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image (Constrained to prevent screen edge sticking)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 140,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo/logo.jpeg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              // Loading Dots Blue Animation
              const BouncingDotsIndicator(
                color: Color(0xFFE31C2E),
                size: 11.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BouncingDotsIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const BouncingDotsIndicator({
    super.key,
    required this.color,
    this.size = 12.0,
  });

  @override
  State<BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<BouncingDotsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate delay/phase shift for each dot (staggered)
            final double progress = (_controller.value - (index * 0.15)) % 1.0;
            
            // Map progress to bounce/scale curve (0.0 -> 1.0 -> 0.0)
            double scale = 1.0;
            double opacity = 0.3;
            
            if (progress < 0.5) {
              final double t = progress / 0.5; // 0.0 to 1.0
              scale = 1.0 + 0.45 * t; // scale up to 1.45
              opacity = 0.3 + 0.7 * t; // opacity up to 1.0
            } else {
              final double t = (progress - 0.5) / 0.5; // 0.0 to 1.0
              scale = 1.45 - 0.45 * t; // scale down to 1.0
              opacity = 1.0 - 0.7 * t; // opacity down to 0.3
            }

            return Container(
              width: widget.size,
              height: widget.size,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(opacity),
              ),
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              transformAlignment: Alignment.center,
            );
          },
        );
      }),
    );
  }
}
