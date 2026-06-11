import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _glowAnimation = Tween<double>(begin: 25.0, end: 75.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleAndRedirect();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      if (role == 'ROLE_USER') {
        Navigator.pushReplacementNamed(context, '/user_home');
      } else if (role == 'ROLE_DRIVER') {
        Navigator.pushReplacementNamed(context, '/driver_home');
      } else {
        Navigator.pushReplacementNamed(context, '/user_home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B141C),
              Color(0xFF162534),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Riderzz text with breathing glow effect
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Text(
                    'Riderzz',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.6),
                          blurRadius: _glowAnimation.value * 0.4,
                        ),
                        Shadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.35),
                          blurRadius: _glowAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              
              // Loading Bar
              SizedBox(
                width: 140,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFF1E2E3D),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
