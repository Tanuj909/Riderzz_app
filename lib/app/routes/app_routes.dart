import 'package:flutter/material.dart';
import 'package:riderzz_app/features/auth/screens/registration_screen.dart';
import 'package:riderzz_app/features/auth/screens/login_screen.dart';
import 'package:riderzz_app/features/auth/screens/role_redirect_screen.dart';
import 'package:riderzz_app/features/user/home/user_home_screen.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/auth/screens/admin_login_screen.dart';
import 'package:riderzz_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:riderzz_app/features/auth/screens/forgot_password_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String initial = '/';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String roleRedirect = '/role_redirect';
  static const String userHome = '/user_home';
  static const String driverHome = '/driver_home';
  static const String adminLogin = '/admin_login';
  static const String adminDashboard = '/admin_dashboard';
  static const String forgotPassword = '/forgot_password';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const RoleRedirectScreen(),
        registration: (context) => const RegistrationScreen(),
        login: (context) => const LoginScreen(),
        roleRedirect: (context) => const RoleRedirectScreen(),
        userHome: (context) => const UserHomeScreen(),
        driverHome: (context) => const DriverHomeScreen(),
        adminLogin: (context) => const AdminLoginScreen(),
        adminDashboard: (context) => const AdminDashboardScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
      };
}
