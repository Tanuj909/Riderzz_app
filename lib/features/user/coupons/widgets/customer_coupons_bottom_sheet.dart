import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/driver/home/driver_home_screen.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_wallet_page.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/user/coupons/data/models/customer_coupon_model.dart';
import 'package:riderzz_app/features/user/coupons/providers/customer_coupon_provider.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';
import 'package:riderzz_app/features/user/wallet/screens/customer_wallet_screen.dart';

/// Shows the Customer Coupons & Rewards modal bottom sheet
Future<void> showCustomerCouponsBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (sheetContext) => const CustomerCouponsBottomSheet(),
  );
}

class CustomerCouponsBottomSheet extends StatefulWidget {
  const CustomerCouponsBottomSheet({super.key});

  @override
  State<CustomerCouponsBottomSheet> createState() =>
      _CustomerCouponsBottomSheetState();
}

class _CustomerCouponsBottomSheetState extends State<CustomerCouponsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  static const Color _primaryRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex && mounted) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCouponProvider>().fetchCoupons(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRewardTitle(String code) {
    if (code.isEmpty) return 'Special Reward';
    final cleaned = code.replaceAll('_', ' ').toLowerCase();
    final words = cleaned.split(' ').map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

    if (!words.toLowerCase().contains('reward') &&
        !words.toLowerCase().contains('bonus')) {
      return '$words Reward';
    }
    return words;
  }

  String _formatExpiryDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Valid till 31 Dec 2027';
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Valid till ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Valid till $isoString';
    }
  }

  String _formatClaimedDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Claimed';
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Claimed on ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Claimed: $isoString';
    }
  }

  Future<void> _handleClaim(CustomerCouponModel coupon) async {
    final couponProvider = context.read<CustomerCouponProvider>();
    final walletProvider = context.read<CustomerWalletProvider>();

    try {
      final result = await couponProvider.claimCoupon(
        coupon.id,
        walletProvider: walletProvider,
      );

      try {
        context.read<DriverHomeProvider>().fetchDriverWallet(force: true);
      } catch (_) {}

      final double amount = (result?['amount'] as num?)?.toDouble() ??
          (coupon.rewardAmount > 0 ? coupon.rewardAmount : 0.0);
      final String msg = result?['message']?.toString() ??
          'Customer reward claimed successfully';
      if (mounted) {
        _showSuccessRewardDialog(
          context,
          amount: amount,
          code: coupon.rewardCode,
          serverMessage: msg,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showClaimErrorDialog(
        context,
        errorMsg: msg,
        coupon: coupon,
      );
    }
  }

  void _showClaimErrorDialog(
    BuildContext context, {
    required String errorMsg,
    required CustomerCouponModel coupon,
  }) {
    final lower = errorMsg.toLowerCase();
    final bool isWalletMissing = lower.contains('wallet') ||
        lower.contains('not found') ||
        lower.contains('exist') ||
        lower.contains('not exist');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isWalletMissing
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWalletMissing
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFFECDD3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isWalletMissing
                        ? Image.asset(
                            'assets/wallet_icon/wallet.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          )
                        : const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isWalletMissing ? 'Wallet Required' : 'Claim Failed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 18),
                if (isWalletMissing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final role = await SecureStorageService().getRole();
                            if (role == 'DRIVER') {
                              Navigator.pop(context);
                              final driverHomeState = context
                                  .findAncestorStateOfType<DriverHomeScreenState>();
                              if (driverHomeState != null) {
                                driverHomeState.setIndex(2);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DriverWalletPage(),
                                  ),
                                );
                              }
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerWalletScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Request Wallet',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessRewardDialog(
    BuildContext context, {
    required double amount,
    required String code,
    String? serverMessage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Icon Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFE4E6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/coupon.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Congratulations! 🎉',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serverMessage != null && serverMessage.isNotEmpty
                      ? '$serverMessage (${_formatRewardTitle(code)})'
                      : 'Reward credited for ${_formatRewardTitle(code)}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Amount Credited Box
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7F7), Color(0xFFFEE2E2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _primaryRed,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            amount.truncateToDouble() == amount
                                ? amount.toInt().toString()
                                : amount.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _primaryRed,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Added directly to your wallet',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          'Awesome!',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final role = await SecureStorageService().getRole();
                          if (role == 'DRIVER') {
                            Navigator.pop(context);
                            final driverHomeState = context
                                .findAncestorStateOfType<DriverHomeScreenState>();
                            if (driverHomeState != null) {
                              driverHomeState.setIndex(2);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DriverWalletPage(),
                                ),
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CustomerWalletScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Wallet',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Clean, professional "How it works" popup dialog without Got it button
  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDF2F4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFE11D48),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'How it works',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildCleanStep(
                        number: '1',
                        title: 'Tap Redeem',
                        description:
                            'Select any available coupon and tap the Redeem button.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      _buildCleanStep(
                        number: '2',
                        title: 'Win up to ₹2,000',
                        description:
                            'Unlock surprise cash rewards on every coupon redemption.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      _buildCleanStep(
                        number: '3',
                        title: 'Use in Wallet',
                        description:
                            'The cash reward is instantly added to your Riderzz wallet balance.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCleanStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFE11D48),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final couponProvider = context.watch<CustomerCouponProvider>();
    final availableCoupons = couponProvider.availableCoupons;
    final claimedCoupons = couponProvider.claimedCoupons;
    final isLoading = couponProvider.isLoading;

    final sheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Top Header: Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Coupons',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Redeem coupons to get cash in your wallet',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Pill Tabs: Available (count) & Used (count)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Available Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _currentIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentIndex == 0
                              ? Border.all(
                                  color: const Color(0xFFFCA5A5), width: 1.2)
                              : null,
                          boxShadow: _currentIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 18,
                              color: _currentIndex == 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Available (${availableCoupons.length})',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: _currentIndex == 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _currentIndex == 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Used Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _currentIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentIndex == 1
                              ? Border.all(
                                  color: const Color(0xFFFCA5A5), width: 1.2)
                              : null,
                          boxShadow: _currentIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 18,
                              color: _currentIndex == 1
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Used (${claimedCoupons.length})',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: _currentIndex == 1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _currentIndex == 1
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: isLoading && couponProvider.coupons.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAvailableTab(availableCoupons, couponProvider),
                        _buildClaimedTab(claimedCoupons, couponProvider),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab(
    List<CustomerCouponModel> coupons,
    CustomerCouponProvider provider,
  ) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchCoupons(force: true),
      color: _primaryRed,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Banner Card ("REDEEM & EARN" shown ONLY in Available tab)
          _buildRedeemBannerCard(),

          const SizedBox(height: 12),

          // Available Coupons List
          if (coupons.isEmpty)
            _buildEmptyTabState(
              title: 'No Available Coupons',
              subtitle:
                  'You do not have any unclaimed coupons right now. Check back soon for exciting rewards!',
              icon: Icons.card_giftcard_rounded,
            )
          else
            ...coupons.asMap().entries.map((entry) {
              final index = entry.key;
              final coupon = entry.value;
              final isClaiming = provider.isClaiming(coupon.id);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: _buildCouponCard(
                  coupon: coupon,
                  index: index,
                  isClaiming: isClaiming,
                  isUsed: false,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildClaimedTab(
    List<CustomerCouponModel> coupons,
    CustomerCouponProvider provider,
  ) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchCoupons(force: true),
      color: _primaryRed,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
        children: [
          // Claimed Coupons List (Banner card is NOT shown in Used tab!)
          if (coupons.isEmpty)
            _buildEmptyTabState(
              title: 'No Used Coupons',
              subtitle:
                  'Coupons you redeem will appear here with the credited cash amount.',
              icon: Icons.history_rounded,
            )
          else
            ...coupons.asMap().entries.map((entry) {
              final index = entry.key;
              final coupon = entry.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: _buildCouponCard(
                  coupon: coupon,
                  index: index,
                  isClaiming: false,
                  isUsed: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Banner Card created using assets/wallet_icon/offer_box.png
  /// Top space reduced, offer_box.png enlarged, with up to ₹2,000 text
  Widget _buildRedeemBannerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F2), Color(0xFFFFE4E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCE7EB), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REDEEM & EARN',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE11D48),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showHowItWorksDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Redeem coupons & win up to ₹2,000!',
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF881337),
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instant cash credited directly to your wallet',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Image.asset(
            'assets/wallet_icon/offer_box.png',
            height: 122,
            width: 122,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  /// Ticket-shaped coupon card:
  /// - Crisp, dark border boundary
  /// - Real perforated dotted line cutout separating left and right
  /// - NO price on Available tab (only shining Redeem button)
  /// - Shining animation on Redeem button
  Widget _buildCouponCard({
    required CustomerCouponModel coupon,
    required int index,
    required bool isClaiming,
    required bool isUsed,
  }) {
    // Crisp, darker boundaries for high contrast and definition
    final themeIndex = index % 3;
    Color borderColor;
    Color iconBgColor;
    Color iconBorderColor;

    if (themeIndex == 0) {
      // Rose theme with dark boundary
      borderColor = const Color(0xFFE11D48).withOpacity(0.55);
      iconBgColor = const Color(0xFFFFF1F2);
      iconBorderColor = const Color(0xFFFECDD3);
    } else if (themeIndex == 1) {
      // Amber/Gold theme with dark boundary
      borderColor = const Color(0xFFD97706).withOpacity(0.55);
      iconBgColor = const Color(0xFFFFFBEB);
      iconBorderColor = const Color(0xFFFDE68A);
    } else {
      // Purple theme with dark boundary
      borderColor = const Color(0xFF7C3AED).withOpacity(0.50);
      iconBgColor = const Color(0xFFF5F3FF);
      iconBorderColor = const Color(0xFFDDD6FE);
    }

    final String amountStr = coupon.rewardAmount.truncateToDouble() ==
            coupon.rewardAmount
        ? coupon.rewardAmount.toInt().toString()
        : coupon.rewardAmount.toStringAsFixed(0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double rightSectionWidth = isUsed ? 102 : 106;
        final double dividerX = w - rightSectionWidth;

        return CustomPaint(
          painter: _TicketPainter(
            dividerX: dividerX,
            borderColor: borderColor,
            isForeground: false,
          ),
          foregroundPainter: _TicketPainter(
            dividerX: dividerX,
            borderColor: borderColor,
            isForeground: true,
          ),
          child: ClipPath(
            clipper: _TicketClipper(dividerX: dividerX),
            child: Container(
              color: Colors.white,
              height: 108,
              child: Row(
                children: [
                  // Left Section (Icon, Title, Subtitle, Validity)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // Left Icon Container (Using assets/icons/coupon.png)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: iconBorderColor),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/coupon.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Text Information
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatRewardTitle(coupon.rewardCode),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isUsed
                                      ? _formatClaimedDate(coupon.claimedAt)
                                      : 'Instant wallet cash reward',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isUsed
                                            ? 'Claimed'
                                            : _formatExpiryDate(coupon.expiresAt),
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.5,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Section
                  // Available Tab: NO PRICE! ONLY shining Redeem button!
                  // Used Tab: Shows ₹amount + CREDITED + Claimed button
                  SizedBox(
                    width: rightSectionWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: isUsed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹$amountStr',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF16A34A),
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'CREDITED',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF16A34A),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: 68,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Claimed',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: ShiningRedeemButton(
                                onPressed: isClaiming
                                    ? null
                                    : () => _handleClaim(coupon),
                                isClaiming: isClaiming,
                                text: 'Redeem',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shining Redeem Button with continuous smooth radiant glow & specular light sweep
class ShiningRedeemButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isClaiming;
  final String text;

  const ShiningRedeemButton({
    super.key,
    required this.onPressed,
    required this.isClaiming,
    this.text = 'Redeem',
  });

  @override
  State<ShiningRedeemButton> createState() => _ShiningRedeemButtonState();
}

class _ShiningRedeemButtonState extends State<ShiningRedeemButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isClaiming) {
      return Container(
        height: 36,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        // Glowing line sweep position across button (-2.0 to +2.0)
        final double slide = -2.0 + (_animController.value * 4.0);

        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            height: 36,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D48).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Button Text
                Text(
                  widget.text,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                // Clean glowing line sweeping left to right
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment(slide - 0.45, -1.0),
                          end: Alignment(slide + 0.45, 1.0),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.60),
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom Clipper for Ticket Shape with:
/// - Rounded outer corners (16px)
/// - Left edge half-circle notch
/// - Right edge half-circle notch
/// - Top and bottom divider line half-circle notches
class _TicketClipper extends CustomClipper<Path> {
  final double dividerX;
  final double cornerRadius;
  final double notchRadius;

  _TicketClipper({
    required this.dividerX,
    this.cornerRadius = 16.0,
    this.notchRadius = 9.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;

    // Top-left corner
    path.moveTo(r, 0);

    // Top edge to divider notch
    path.lineTo(dividerX - nr, 0);
    path.arcToPoint(
      Offset(dividerX + nr, 0),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Top edge to top-right
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // Right edge to right center notch
    path.lineTo(w, h / 2 - nr);
    path.arcToPoint(
      Offset(w, h / 2 + nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Right edge to bottom-right
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // Bottom edge to divider notch
    path.lineTo(dividerX + nr, h);
    path.arcToPoint(
      Offset(dividerX - nr, h),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Bottom edge to bottom-left
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

    // Left edge to left center notch
    path.lineTo(0, h / 2 + nr);
    path.arcToPoint(
      Offset(0, h / 2 - nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Left edge to top-left
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) =>
      oldClipper.dividerX != dividerX ||
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.notchRadius != notchRadius;
}

class _TicketPainter extends CustomPainter {
  final double dividerX;
  final Color borderColor;
  final double cornerRadius;
  final double notchRadius;
  final bool isForeground;

  _TicketPainter({
    required this.dividerX,
    required this.borderColor,
    this.cornerRadius = 16.0,
    this.notchRadius = 9.0,
    this.isForeground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = _TicketClipper(
      dividerX: dividerX,
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
    );
    final path = clipper.getClip(size);

    if (!isForeground) {
      // Soft ambient drop shadow following the ticket cutouts
      canvas.drawShadow(path, Colors.black.withOpacity(0.06), 3.0, false);
      return;
    }

    // Draw dark, crisp outer shaped border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, borderPaint);

    // Draw vertical dotted / dashed line between top notch and bottom notch
    final dashPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    const double dashLength = 3.5;
    const double dashSpace = 3.5;
    double startY = notchRadius + 3.0;
    final double endY = size.height - notchRadius - 3.0;

    while (startY < endY) {
      final double nextY = math.min(startY + dashLength, endY);
      canvas.drawLine(Offset(dividerX, startY), Offset(dividerX, nextY), dashPaint);
      startY += dashLength + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TicketPainter oldDelegate) =>
      oldDelegate.dividerX != dividerX ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.isForeground != isForeground;
}
