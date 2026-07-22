import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';


class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
  final _rechargeController = TextEditingController();
  late Razorpay _razorpay;
  int? _currentRechargeId;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchDriverWallet();
    });
  }

  @override
  void dispose() {
    _rechargeController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentRechargeId == null || _currentOrderId == null) return;

    final provider = context.read<DriverHomeProvider>();
    final success = await provider.verifyRecharge(
      _currentRechargeId!,
      _currentOrderId!,
      response.paymentId ?? '',
      response.signature ?? '',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet recharged successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.walletError ?? 'Failed to verify payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}'),
        ),
      );
    }
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final year = dt.year;
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final hourNum = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hourNum:$minute $ampm';
    } catch (_) {
      return dateTimeStr;
    }
  }

  void _showRechargeDialog(BuildContext context, DriverHomeProvider provider) {
    _rechargeController.text = '500'; // Default quick amount
    bool isSubmitting = false;
    final minBal = provider.wallet?.minBalanceRequired ?? 100.0;
 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Custom Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEBEC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFFCC2D3B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recharge Wallet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: const Color(0xFF121214),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6C6F79),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
 
                    // Limits and Label Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enter Amount',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Limit: ₹50 - ₹1,000',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
 
                    // Amount Text Field
                    TextField(
                      controller: _rechargeController,
                      keyboardType: TextInputType.number,
                      enabled: !isSubmitting,
                      onChanged: (val) {
                        setState(() {}); // Rebuild to update matching select state of helper cards
                      },
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF121214),
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF121214),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFCC2D3B),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
 
                    // Quick select cards
                    Row(
                      children: [100, 500, 1000].map((amount) {
                        final isSelected =
                            _rechargeController.text == amount.toString();
                        return Expanded(
                          child: GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _rechargeController.text = amount.toString();
                                    });
                                  },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFDEBEC)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFCC2D3B)
                                      : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+ ₹$amount',
                                style: GoogleFonts.outfit(
                                  color: isSelected
                                      ? const Color(0xFFCC2D3B)
                                      : const Color(0xFF4B5563),
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
 
                    // Dialog Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCC2D3B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final amtStr = _rechargeController.text.trim();
                                    final amt = double.tryParse(amtStr);
                                    if (amt == null || amt <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid amount',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
 
                                    if (amt < 50.0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'can not add money less than 50',
                                          ),
                                          backgroundColor: Color(0xFFEF4444),
                                        ),
                                      );
                                      return;
                                    }
 
                                    if (amt > 1000.0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'can not add more than 1000',
                                          ),
                                          backgroundColor: Color(0xFFEF4444),
                                        ),
                                      );
                                      return;
                                    }
 
                                    setState(() {
                                      isSubmitting = true;
                                    });
 
                                    final res = await provider.initiateRecharge(amt);
 
                                    setState(() {
                                      isSubmitting = false;
                                      if (res != null) {
                                        debugPrint('--- RAZORPAY SUCCESS ---');
                                        debugPrint('Razorpay Key ID: ${res.razorpayKeyId}');
                                        debugPrint('Razorpay Order ID: ${res.razorpayOrderId}');
                                        debugPrint('Recharge ID: ${res.rechargeId}');
                                        debugPrint('Amount: ${res.amount}');
                                        debugPrint('------------------------');
                                        if (context.mounted) {
                                          Navigator.pop(dialogContext); // Close the dialog
                                        }
 
                                        _currentRechargeId = res.rechargeId;
                                        _currentOrderId = res.razorpayOrderId;
 
                                        final profile = provider.profile;
 
                                        var options = {
                                          'key': (dotenv.env['RAZORPAY_KEY_ID'] != null && dotenv.env['RAZORPAY_KEY_ID']!.isNotEmpty)
                                              ? dotenv.env['RAZORPAY_KEY_ID']!
                                              : res.razorpayKeyId,
                                          'amount': (res.amount * 100).toInt(), // Razorpay expects amount in paise
                                          'name': 'Riderzz',
                                          'description': 'Wallet Recharge',
                                          'order_id': res.razorpayOrderId,
                                          'prefill': {
                                            'contact': profile?.phone ?? '',
                                            'name': profile?.name ?? '',
                                          },
                                          'theme': {'color': '#E31C2E'},
                                        };
 
                                        try {
                                          _razorpay.open(options);
                                        } catch (e) {
                                          debugPrint('Error: $e');
                                        }
                                      } else {
                                        debugPrint('--- RAZORPAY ERROR ---');
                                        debugPrint('Recharge failed with: ${provider.walletError}');
                                        debugPrint('----------------------');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.walletError ?? 'Failed to initiate recharge',
                                              ),
                                              backgroundColor: const Color(0xFFEF4444),
                                            ),
                                          );
                                        }
                                      }
                                    });
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Recharge',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final wallet = driverProvider.wallet;

    if (driverProvider.isWalletLoading && wallet == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
          ),
        ),
      );
    }

    if (driverProvider.isWalletNotCreated) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEBEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFFE31C2E),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to your Wallet!',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF121214),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your wallet now and claim your exclusive sign-in reward to get started!',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4B5563),
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCC2D3B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.read<DriverHomeProvider>().createDriverWallet();
                    },
                    child: Text(
                      'Get Sign-in Reward!',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

    if (driverProvider.walletError != null && wallet == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  driverProvider.walletError!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4A5568),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC2D3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<DriverHomeProvider>().fetchDriverWallet();
                  },
                  child: Text(
                    'Retry',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final balance = wallet?.balance ?? 0.0;
    final minBal = wallet?.minBalanceRequired ?? 100.0;
    final isLowBalance = balance < minBal;
    final transactions = wallet?.transactions ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<DriverHomeProvider>().fetchDriverWallet(force: true),
          color: const Color(0xFFD90429),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                  child: Text(
                    'My Wallet',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF121214),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                
                // Wallet Balance Card (Matching .wallet-hero styling)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF121214), Color(0xFF2A2B30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD90429), Color(0xFF8D021F)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _showRechargeDialog(context, driverProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                            elevation: 0,
                          ),
                          child: Text(
                            '+ Add money',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Low Balance Warning
                if (isLowBalance) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alert: Balance is below the minimum required amount. Please recharge to continue receiving ride bookings.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFB91C1C),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Transactions Header
                Text(
                  'Transaction history',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA2A5AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),

                // Transactions List
                if (transactions.isEmpty)
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                    ),
                    child: Text(
                      'No transactions found.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6C6F79),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A121214),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFFE1E1E6),
                        height: 1,
                        thickness: 0.5,
                      ),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];

                        final isCredit =
                            tx.type == 'RECHARGE' ||
                            tx.type == 'CREDIT' ||
                            tx.type == 'BOOKING_CREDIT' ||
                            tx.type == 'BONUS';
                        
                        Color iconColor;
                        Color iconBg;
                        IconData iconData;
                        String titleText;

                        if (tx.type == 'RECHARGE') {
                          iconColor = const Color(0xFF1C9A5B);
                          iconBg = const Color(0xFFE7F7EF);
                          iconData = Icons.add_rounded;
                          titleText = 'Wallet recharge';
                        } else if (tx.type == 'CREDIT' || tx.type == 'BOOKING_CREDIT') {
                          iconColor = const Color(0xFF1C9A5B);
                          iconBg = const Color(0xFFE7F7EF);
                          iconData = Icons.directions_car_rounded;
                          titleText = 'Trip Earnings';
                        } else {
                          iconColor = const Color(0xFF121214);
                          iconBg = const Color(0xFFF1F1F4);
                          iconData = Icons.arrow_outward_rounded;
                          titleText = tx.type == 'COMMISSION_DEBIT' ? 'Commission Debit' : 'Withdrawal';
                        }

                        return Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            iconColor: const Color(0xFF6C6F79),
                            collapsedIconColor: const Color(0xFF6C6F79),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: iconColor, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titleText,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.5,
                                          color: const Color(0xFF121214),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDateTime(tx.createdAt),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF6C6F79),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? "+" : "−"}₹${tx.amount.abs().toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isCredit ? const Color(0xFF1C9A5B) : const Color(0xFF121214),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(color: Color(0xFFE1E1E6), thickness: 0.5),
                                    const SizedBox(height: 8),
                                    _buildDetailRow('Transaction Type', tx.type),
                                    _buildDetailRow('Status', tx.status),
                                    _buildDetailRow('Opening Balance', '₹${tx.openingBalance.toStringAsFixed(2)}'),
                                    _buildDetailRow('Closing Balance', '₹${tx.closingBalance.toStringAsFixed(2)}'),
                                    _buildDetailRow('Reference No.', tx.referenceNumber),
                                    if (tx.bookingNumber != null && tx.bookingNumber!.isNotEmpty)
                                      _buildDetailRow('Booking No.', tx.bookingNumber!),
                                    if (tx.remarks.isNotEmpty)
                                      _buildDetailRow('Remarks', tx.remarks),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA2A5AE),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: const Color(0xFF121214),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
