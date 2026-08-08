import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/auth/screens/login_screen.dart';
import 'package:riderzz_app/features/user/home/user_home_screen.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/admin/dashboard/admin_dashboard_screen.dart';

enum AuthResult {
  loggedOut,
  customer,
  driver,
  admin,
}

class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> with TickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _isLooping = false;
  late AnimationController _entranceController;
  late AnimationController _loopController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _entranceAlignmentAnimation;
  late Animation<Offset> _loopAlignmentAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _entranceAlignmentAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.0, 0.0), // Moves all the way left and disappears
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _loopAlignmentAnimation = Tween<Offset>(
      begin: const Offset(2.0, 0.0), // Starts from right
      end: const Offset(-2.0, 0.0),  // Moves to left and disappears
    ).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: Curves.linear,
      ),
    );

    _entranceController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isLooping = true;
        });
        _loopController.repeat();
      }
    });

    _initializeLocationInBackground();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  void _initializeLocationInBackground() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    // Start location initialization/fetching in the background.
    // Location MUST NOT block navigation.
    locationProvider.initialize().catchError((error) {
      debugPrint('Location initialization failed: $error');
    });
  }

  Future<void> _checkAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    AuthResult result = AuthResult.loggedOut;

    try {
      // Allow the animation to play out completely (1000ms) before navigating, 
      // while also fetching the auth result in parallel.
      final results = await Future.wait([
        authProvider.tryAutoLogin(),
        () async {
          int elapsed = _entranceController.lastElapsedDuration?.inMilliseconds ?? 0;
          int remaining = 1200 - elapsed;
          if (remaining > 0) {
            await Future.delayed(Duration(milliseconds: remaining));
          }
        }(),
      ]);

      final isLoggedIn = results[0] as bool;

      if (isLoggedIn && authProvider.currentUser != null) {
        final role = authProvider.currentUser!.role;
        switch (role) {
          case 'CUSTOMER':
            result = AuthResult.customer;
            break;
          case 'DRIVER':
            result = AuthResult.driver;
            break;
          case 'ADMIN':
            result = AuthResult.admin;
            break;
          default:
            result = AuthResult.loggedOut;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Auto-login failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      result = AuthResult.loggedOut;
    }

    _routeToDestination(result);
  }

  void _routeToDestination(AuthResult result) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Widget destination;
    String routeName;

    switch (result) {
      case AuthResult.customer:
        destination = const UserHomeScreen();
        routeName = '/user_home';
        break;
      case AuthResult.driver:
        destination = const DriverHomeScreen();
        routeName = '/driver_home';
        break;
      case AuthResult.admin:
        destination = const AdminDashboardScreen();
        routeName = '/admin_dashboard';
        break;
      case AuthResult.loggedOut:
      default:
        destination = const LoginScreen();
        routeName = '/login';
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SlideTransition(
          position: _isLooping ? _loopAlignmentAnimation : _entranceAlignmentAnimation,
          child: FadeTransition(
            opacity: _isLooping ? const AlwaysStoppedAnimation(1.0) : _fadeAnimation,
            child: ScaleTransition(
              scale: _isLooping ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
              child: Image.asset(
                'assets/logo/logo.png',
                width: 280, // Approx suitable size for the wide text logo
              ),
            ),
          ),
        ),
      ),
    );
  }
}

