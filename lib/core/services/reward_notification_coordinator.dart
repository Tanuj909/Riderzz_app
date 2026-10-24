import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
import 'package:riderzz_app/features/notification/data/models/notification_model.dart';
import 'package:riderzz_app/features/user/coupons/providers/customer_coupon_provider.dart';
import 'package:riderzz_app/features/user/coupons/widgets/customer_coupons_bottom_sheet.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';

/// Centralized coordinator for handling `REWARD_RECEIVED` notifications
/// across WebSocket, FCM foreground, FCM background taps, and terminated launches.
class RewardNotificationCoordinator {
  RewardNotificationCoordinator._internal();

  static final RewardNotificationCoordinator instance =
      RewardNotificationCoordinator._internal();

  /// Route observer attached to MaterialApp to track top-level page transitions
  final RewardRouteObserver routeObserver = RewardRouteObserver();

  /// Currently active top-level screen route name (e.g. '/user_home', '/driver_home')
  String? _currentScreenRoute;

  /// Whether the active home page has fully mounted and initiated its data loading
  bool _isHomeDataReady = false;

  /// Timestamp when the home screen was reached
  DateTime? _homeScreenMountedTime;

  /// Set of notification IDs/keys that have already displayed a popup in the current session.
  final Set<String> _shownRewardPopupIds = <String>{};

  /// Pending reward data queued when the app UI context is not yet mounted or ready.
  Map<String, dynamic>? _pendingRewardData;

  /// Guard flag to ensure at most one reward dialog is active at a time.
  bool _isDialogVisible = false;

  /// Timer for polling UI readiness when a reward is queued.
  Timer? _readinessPollTimer;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle & Route Notifiers
  // ──────────────────────────────────────────────────────────────────────────

  /// Notified by [RewardRouteObserver] when a top-level route changes.
  void onPageRouteChanged(String routeName) {
    debugPrint('[REWARD_COORDINATOR] Active route changed to: $routeName');
    _currentScreenRoute = routeName;
    if (routeName == AppRoutes.userHome || routeName == AppRoutes.driverHome) {
      _homeScreenMountedTime ??= DateTime.now();
      checkAndShowPendingReward();
    }
  }

  /// Notified by [UserHomePage] or [DriverHomeScreen] once initial data fetches are underway.
  void onHomeScreenReady() {
    debugPrint('[REWARD_COORDINATOR] Home screen marked ready');
    _isHomeDataReady = true;
    _homeScreenMountedTime ??= DateTime.now();
    checkAndShowPendingReward();
  }

  /// Checks if the user is currently on an active logged-in home screen (not splash/login).
  bool _isHomeScreenActive() {
    // 1. Check observer tracked route
    if (_currentScreenRoute != null) {
      if (_currentScreenRoute == AppRoutes.initial ||
          _currentScreenRoute == AppRoutes.roleRedirect ||
          _currentScreenRoute == AppRoutes.login ||
          _currentScreenRoute == AppRoutes.registration) {
        return false;
      }
      return true;
    }

    // 2. Fallback: inspect top PageRoute on NavigatorState without popping
    String? topRoute;
    AppRoutes.navigatorKey.currentState?.popUntil((route) {
      if (route is PageRoute && route.settings.name != null) {
        topRoute = route.settings.name;
      }
      return true;
    });

    if (topRoute != null) {
      _currentScreenRoute = topRoute;
      if (topRoute == AppRoutes.initial ||
          topRoute == AppRoutes.roleRedirect ||
          topRoute == AppRoutes.login ||
          topRoute == AppRoutes.registration) {
        return false;
      }
      return true;
    }

    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Entry Points
  // ──────────────────────────────────────────────────────────────────────────

  /// Handle reward from WebSocket (/user/queue/notifications).
  void handleRewardFromWebSocket(NotificationModel notification) {
    if (notification.type != 'REWARD_RECEIVED') return;

    final data = <String, dynamic>{
      'notificationId': notification.notificationId ?? notification.id.toString(),
      'title': notification.title,
      'body': notification.message,
      'actionUrl': notification.actionUrl,
      'type': notification.type,
    };

    debugPrint('[REWARD_COORDINATOR] Received from WebSocket: ${data['notificationId']}');
    _processReward(data);
  }

  /// Handle reward from FCM (foreground or tap).
  void handleRewardFromFcm(Map<String, dynamic> data, {String? notificationTitle, String? notificationBody, bool isTap = false}) {
    final type = data['type']?.toString();
    final actionUrl = data['actionUrl']?.toString();
    final isReward = type == 'REWARD_RECEIVED' ||
        actionUrl == '/customer/coupons' ||
        actionUrl == '/rewards/customer/coupons';
    if (!isReward) return;

    final rewardData = <String, dynamic>{
      'notificationId': data['notificationId']?.toString(),
      'title': notificationTitle ?? data['title']?.toString(),
      'body': notificationBody ?? data['message']?.toString() ?? data['body']?.toString(),
      'actionUrl': data['actionUrl']?.toString(),
      'type': type ?? 'REWARD_RECEIVED',
      'isTap': isTap,
    };

    debugPrint('[REWARD_COORDINATOR] Received from FCM (isTap=$isTap): ${rewardData['notificationId']}');
    _processReward(rewardData);
  }

  /// Handle reward payload from local notification response.
  void handleRewardFromLocalPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final actionUrl = data['actionUrl']?.toString();
    final isReward = type == 'REWARD_RECEIVED' ||
        actionUrl == '/customer/coupons' ||
        actionUrl == '/rewards/customer/coupons';
    if (!isReward) return;

    final rewardData = <String, dynamic>{
      'notificationId': data['notificationId']?.toString(),
      'title': data['title']?.toString(),
      'body': data['body']?.toString() ?? data['message']?.toString(),
      'actionUrl': data['actionUrl']?.toString(),
      'type': type ?? 'REWARD_RECEIVED',
      'isTap': true,
    };

    debugPrint('[REWARD_COORDINATOR] Received from LocalNotification tap: ${rewardData['notificationId']}');
    _processReward(rewardData);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Processing & Deduplication
  // ──────────────────────────────────────────────────────────────────────────

  void _processReward(Map<String, dynamic> data) {
    final notificationId = data['notificationId']?.toString();
    final title = data['title']?.toString() ?? '';
    final body = data['body']?.toString() ?? '';

    // Generate deduplication key for the popup
    final dedupeKey = (notificationId != null && notificationId.isNotEmpty)
        ? notificationId
        : '$title|$body';

    if (dedupeKey.isNotEmpty && _shownRewardPopupIds.contains(dedupeKey)) {
      debugPrint('[REWARD_COORDINATOR] Suppressing duplicate popup for key: $dedupeKey');
      return;
    }

    _pendingRewardData = data;
    checkAndShowPendingReward();
  }

  /// Verifies if UI is ready and shows the pending reward popup if available.
  void checkAndShowPendingReward() {
    if (_pendingRewardData == null || _isDialogVisible) return;

    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) {
      _startReadinessPolling();
      return;
    }

    // 1. Ensure AuthProvider is ready and user is authenticated
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser == null) {
        _startReadinessPolling();
        return;
      }
    } catch (_) {
      _startReadinessPolling();
      return;
    }

    // 2. Ensure we are not on a transient splash/loading route (RoleRedirectScreen or Login)
    if (!_isHomeScreenActive()) {
      _startReadinessPolling();
      return;
    }

    // 3. Ensure home screen data has finished its initial load
    final elapsedSinceMount = _homeScreenMountedTime != null
        ? DateTime.now().difference(_homeScreenMountedTime!).inMilliseconds
        : 9999;
    if (!_isHomeDataReady && elapsedSinceMount < 3000) {
      _startReadinessPolling();
      return;
    }

    _readinessPollTimer?.cancel();
    _readinessPollTimer = null;

    final rewardData = _pendingRewardData!;
    _pendingRewardData = null;

    final notificationId = rewardData['notificationId']?.toString();
    final title = rewardData['title']?.toString() ?? '';
    final body = rewardData['body']?.toString() ?? '';
    final dedupeKey = (notificationId != null && notificationId.isNotEmpty)
        ? notificationId
        : '$title|$body';

    if (dedupeKey.isNotEmpty) {
      _shownRewardPopupIds.add(dedupeKey);
    }

    final bool isTap = rewardData['isTap'] == true;

    // Settle delay: ensures page route transitions and all initial home data
    // (bookings, wallet, coupons, vehicles) are completely loaded and settled.
    final int delayMs = (1400 - elapsedSinceMount).clamp(350, 1400);

    Future.delayed(Duration(milliseconds: delayMs), () {
      final navContext = AppRoutes.navigatorKey.currentState?.overlay?.context ??
          AppRoutes.navigatorKey.currentContext ??
          context;

      if (!navContext.mounted) return;

      if (isTap) {
        _navigateToRewardScreen(navContext);
      } else {
        _displayRewardDialog(navContext, rewardData);
      }
    });
  }

  void _startReadinessPolling() {
    if (_readinessPollTimer != null && _readinessPollTimer!.isActive) return;

    int attempts = 0;
    _readinessPollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      attempts++;
      if (_pendingRewardData == null || attempts > 35) {
        timer.cancel();
        _readinessPollTimer = null;
        return;
      }
      checkAndShowPendingReward();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Dialog Presentation
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _displayRewardDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    final String title = (data['title']?.toString().isNotEmpty ?? false)
        ? data['title'].toString()
        : 'Reward Received! 🎉';

    final String message = (data['body']?.toString().isNotEmpty ?? false)
        ? data['body'].toString()
        : 'You have unlocked a special reward! View your coupon to claim instant wallet credits.';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _RewardDialogContent(
              title: title,
              message: message,
              onViewCoupon: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _navigateToRewardScreen(context);
                });
              },
              onDismiss: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              },
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[REWARD_COORDINATOR] Error presenting dialog: $e');
    } finally {
      _isDialogVisible = false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Role-Based Navigation
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _navigateToRewardScreen(BuildContext context) async {
    try {
      final role = await SecureStorageService().getRole();
      final navContext = AppRoutes.navigatorKey.currentState?.overlay?.context ??
          AppRoutes.navigatorKey.currentContext ??
          context;

      if (role == 'DRIVER') {
        final driverHomeState =
            navContext.findAncestorStateOfType<DriverHomeScreenState>();
        if (driverHomeState != null) {
          driverHomeState.setIndex(2); // DriverWalletPage index
        }
        try {
          navContext.read<CustomerCouponProvider>().fetchCoupons(force: true);
        } catch (_) {}

        showCustomerCouponsBottomSheet(navContext);
      } else {
        // Customer role: open bottom sheet directly
        try {
          navContext.read<CustomerCouponProvider>().fetchCoupons(force: true);
          navContext.read<CustomerWalletProvider>().fetchCustomerWallet(force: true);
        } catch (_) {}

        showCustomerCouponsBottomSheet(navContext);
      }
    } catch (e) {
      debugPrint('[REWARD_COORDINATOR] Navigation error: $e');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// UI Dialog Component
// ──────────────────────────────────────────────────────────────────────────

class _RewardDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onViewCoupon;
  final VoidCallback onDismiss;

  const _RewardDialogContent({
    required this.title,
    required this.message,
    required this.onViewCoupon,
    required this.onDismiss,
  });

  @override
  State<_RewardDialogContent> createState() => _RewardDialogContentState();
}

class _RewardDialogContentState extends State<_RewardDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration / Icon Badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFE4E6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE31C2E).withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/coupon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.card_giftcard_rounded,
                      size: 32,
                      color: Color(0xFFE31C2E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Explanatory Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Primary Action: View My Coupon
              SizedBox(
                width: double.infinity,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE31C2E), Color(0xFFC62E42)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE31C2E).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onViewCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View My Coupon',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Secondary Dismiss Action: Maybe later
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8E8E93),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: Text(
                    'Maybe later',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E8E93),
                    ),
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

/// NavigatorObserver that monitors page route changes to inform [RewardNotificationCoordinator].
class RewardRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute && route.settings.name != null) {
      RewardNotificationCoordinator.instance.onPageRouteChanged(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute && newRoute.settings.name != null) {
      RewardNotificationCoordinator.instance.onPageRouteChanged(newRoute.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && previousRoute.settings.name != null) {
      RewardNotificationCoordinator.instance.onPageRouteChanged(previousRoute.settings.name!);
    }
  }
}

