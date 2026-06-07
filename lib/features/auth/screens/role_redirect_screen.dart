import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

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

  void _checkRoleAndRedirect() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.tryAutoLogin();

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
    return const Scaffold(
      backgroundColor: Color(0xFF0F2027),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.cyanAccent,
        ),
      ),
    );
  }
}
