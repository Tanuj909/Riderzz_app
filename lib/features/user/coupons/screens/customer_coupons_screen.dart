import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/coupons/widgets/customer_coupons_bottom_sheet.dart';
export 'package:riderzz_app/features/user/coupons/widgets/customer_coupons_bottom_sheet.dart';

/// Legacy screen wrapper: redirects immediately to the Customer Coupons bottom sheet.
class CustomerCouponsScreen extends StatefulWidget {
  const CustomerCouponsScreen({super.key});

  @override
  State<CustomerCouponsScreen> createState() => _CustomerCouponsScreenState();
}

class _CustomerCouponsScreenState extends State<CustomerCouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navState = Navigator.of(context);
      final parentContext = navState.overlay?.context ?? context;
      navState.maybePop();
      showCustomerCouponsBottomSheet(parentContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
