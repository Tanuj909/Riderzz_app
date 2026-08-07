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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Default to false — will be overwritten if auth resolves in time.
    bool isLoggedIn = false;

    // Race the full init work against a strict 2-second wall-clock timer.
    // Whichever finishes first wins. Splash never hangs past 2 seconds.
    // Start location init in the background without awaiting it.
    locationProvider.initialize().catchError((_) => Future<void>.value());

    await Future.any([
      // Only wait for Auth. It reads from local storage so it's instant (< 10ms).
      authProvider
          .tryAutoLogin()
          .then((v) => isLoggedIn = v)
          .catchError((_) => isLoggedIn = false)
          .timeout(
            const Duration(milliseconds: 300),
            onTimeout: () => isLoggedIn = false,
          ),

      // Hard 300ms wall-clock cap — always exits splash by this point.
      Future.delayed(const Duration(milliseconds: 300)),
    ]);

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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }
}
