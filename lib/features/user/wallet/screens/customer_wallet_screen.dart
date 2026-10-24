import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_bank_account_model.dart';

class CustomerWalletScreen extends StatefulWidget {
  final bool showBackButton;
  const CustomerWalletScreen({super.key, this.showBackButton = true});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerWalletProvider>().fetchCustomerWallet(force: true);
      context.read<CustomerWalletProvider>().fetchBankAccount(force: true);
    });
  }

  void _showComingSoonSnackBar([String message = 'Withdraw Feature will be available soon!']) {
    final displayText = message.toLowerCase().contains('soon')
        ? message
        : '$message feature will be available soon!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          displayText,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E1E24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<CustomerWalletProvider>();
    final wallet = walletProvider.wallet;
    final isLoading = walletProvider.isLoading;
    final errorMessage = walletProvider.errorMessage;

    final isActive = wallet?.active ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
              )
            : null,
        title: Text(
          'Wallet',
          style: GoogleFonts.outfit(
            color: const Color(0xFF121214),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (wallet != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active Wallet' : 'Inactive Wallet',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<CustomerWalletProvider>().fetchCustomerWallet(force: true),
            context.read<CustomerWalletProvider>().fetchBankAccount(force: true),
          ]);
        },
        color: const Color(0xFFE31C2E),
        child: isLoading && wallet == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                ),
              )
            : wallet == null
                ? (walletProvider.isWalletNotFound
                    ? _buildRequestWalletView()
                    : _buildErrorView(errorMessage ?? 'No wallet found'))
                : _buildWalletContent(wallet),
      ),
    );
  }

  Widget _buildRequestWalletView() {
    final walletProvider = context.watch<CustomerWalletProvider>();
    final isCreating = walletProvider.isCreatingWallet;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD5D5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE31C2E).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFE31C2E),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Wallet Found',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121214),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your customer wallet has not been created yet. Tap below to request and set up your wallet to claim coupon rewards and manage your balance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF6C6F79),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31C2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: isCreating
                    ? null
                    : () async {
                        final success = await context
                            .read<CustomerWalletProvider>()
                            .createCustomerWallet();
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Customer wallet created successfully!',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF15803D),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else {
                            final err = context
                                    .read<CustomerWalletProvider>()
                                    .errorMessage ??
                                'Failed to create wallet';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  err,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_card_rounded, size: 20),
                label: Text(
                  isCreating ? 'Creating Wallet...' : 'Request Wallet',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context
                  .read<CustomerWalletProvider>()
                  .fetchCustomerWallet(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6C6F79)),
              label: Text(
                'Check Again',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C6F79),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE31C2E),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Wallet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121214),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6C6F79),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF121214),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  onPressed: () => context.read<CustomerWalletProvider>().fetchCustomerWallet(force: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await context.read<CustomerWalletProvider>().createCustomerWallet();
                  },
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: Text(
                    'Request Wallet',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent(wallet) {
    final balance = wallet?.balance ?? 0.0;
    final holdBalance = wallet?.holdBalance ?? 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Premium Balance Card ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E24), Color(0xFF121214)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Balance" Label
                Text(
                  'Balance',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Amount (Same font size for ₹ and money)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: const ['Helvetica Neue', 'Roboto', 'Arial', 'sans-serif'],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      balance.toStringAsFixed(2),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 12),

                // Hold Balance Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_clock_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'On Hold Balance',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: const ['Helvetica Neue', 'Roboto', 'Arial', 'sans-serif'],
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          holdBalance.toStringAsFixed(2),
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Action: Withdraw ──
          ElevatedButton.icon(
            onPressed: () => _showComingSoonSnackBar('Withdraw Feature will be available soon!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
            label: Text(
              'Withdraw',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          // ── Section: Bank Account ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'BANK ACCOUNT',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9EA3AE),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Consumer<CustomerWalletProvider>(
            builder: (context, provider, _) {
              if (provider.isBankAccountLoading && provider.bankAccount == null) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F1F4)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                      ),
                    ),
                  ),
                );
              }
              final account = provider.bankAccount;
              return account != null
                  ? _buildActiveBankAccountCard(context, account)
                  : _buildEmptyBankAccountCard(context);
            },
          ),
          const SizedBox(height: 24),

          // ── Help Footer ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFF6C6F79)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Need assistance with withdrawals or bank accounts? Contact our 24/7 customer support.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF6C6F79),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _indianBanks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Punjab National Bank',
    'Axis Bank',
    'Bank of Baroda',
    'Kotak Mahindra Bank',
    'Canara Bank',
    'Union Bank of India',
    'Bank of India',
    'IndusInd Bank',
    'Yes Bank',
    'Central Bank of India',
    'Indian Bank',
    'IDBI Bank',
    'Federal Bank',
    'IDFC FIRST Bank',
    'Indian Overseas Bank',
    'UCO Bank',
    'Punjab & Sind Bank',
    'Bank of Maharashtra',
    'Bandhan Bank',
    'South Indian Bank',
    'AU Small Finance Bank',
    'Paytm Payments Bank',
    'Airtel Payments Bank',
  ];

  Widget _buildEmptyBankAccountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F6F8),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/wallet_icon/bank.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your bank account',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121214),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'To accept the Withdraw amount!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF6C6F79),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showBankAccountBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF121214),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Add Bank Account',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBankAccountCard(BuildContext context, CustomerBankAccountModel bankAccount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/wallet_icon/bank.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankAccount.bankName.isNotEmpty ? bankAccount.bankName : 'Bank Account',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bankAccount.accountNumber,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C6F79),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bankAccount.verified
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: bankAccount.verified
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      bankAccount.verified ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 11,
                      color: bankAccount.verified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bankAccount.verified ? 'Verified' : 'Pending',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: bankAccount.verified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F1F4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT HOLDER',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9EA3AE),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bankAccount.accountHolderName,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'IFSC CODE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9EA3AE),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bankAccount.ifscCode,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (bankAccount.bankRegisteredPhone != null && bankAccount.bankRegisteredPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF6C6F79)),
                const SizedBox(width: 5),
                Text(
                  'Registered Phone: ${bankAccount.bankRegisteredPhone!.startsWith('+91') ? bankAccount.bankRegisteredPhone : '+91 ${bankAccount.bankRegisteredPhone}'}',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF6C6F79),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F1F4)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmDeleteBankAccount(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE31C2E)),
                label: Text(
                  'Delete',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE31C2E),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showBankAccountBottomSheet(context, existingAccount: bankAccount),
                icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF121214)),
                label: Text(
                  'Edit',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121214),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBankAccountBottomSheet(BuildContext context, {CustomerBankAccountModel? existingAccount}) {
    final isEdit = existingAccount != null;
    final formKey = GlobalKey<FormState>();

    final holderNameController = TextEditingController(text: existingAccount?.accountHolderName ?? '');
    final hasMaskedNumber = existingAccount?.accountNumber.contains('*') ?? false;
    final accountNumberController = TextEditingController(
      text: hasMaskedNumber ? '' : (existingAccount?.accountNumber ?? ''),
    );
    final bankController = TextEditingController(text: existingAccount?.bankName ?? '');
    final ifscController = TextEditingController(text: existingAccount?.ifscCode ?? '');

    String initialPhone = existingAccount?.bankRegisteredPhone ?? '';
    if (initialPhone.startsWith('+91')) {
      initialPhone = initialPhone.substring(3);
    } else if (initialPhone.length > 10 && initialPhone.startsWith('91')) {
      initialPhone = initialPhone.substring(2);
    }
    final phoneController = TextEditingController(text: initialPhone);

    final holderFocusNode = FocusNode();
    final bankFocusNode = FocusNode();
    final accountFocusNode = FocusNode();
    final ifscFocusNode = FocusNode();
    final phoneFocusNode = FocusNode();

    bool isBankDropdownOpen = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final query = bankController.text.trim().toLowerCase();
            final filteredBanks = query.isEmpty
                ? _indianBanks
                : _indianBanks.where((b) => b.toLowerCase().contains(query)).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/wallet_icon/bank.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit ? 'Update Bank Account' : 'Add Bank Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSubmitting ? null : () => Navigator.pop(bottomSheetContext),
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Account Holder Name
                        TextFormField(
                          controller: holderNameController,
                          focusNode: holderFocusNode,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          onFieldSubmitted: (_) {
                            setModalState(() => isBankDropdownOpen = true);
                            bankFocusNode.requestFocus();
                          },
                          onTap: () {
                            if (isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = false);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Account Holder Name',
                            hintText: 'Full name as per bank records',
                            labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5)),
                          ),
                          style: GoogleFonts.outfit(fontSize: 14),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Account holder name is required';
                            if (val.trim().length > 100) return 'Account holder name cannot exceed 100 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Bank Name Input Field with Interactive Dropdown (Same width, white background, keyboard stays open)
                        TextFormField(
                          controller: bankController,
                          focusNode: bankFocusNode,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          onFieldSubmitted: (_) {
                            setModalState(() => isBankDropdownOpen = false);
                            accountFocusNode.requestFocus();
                          },
                          onTap: () {
                            if (!isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = true);
                            }
                          },
                          onChanged: (text) {
                            if (!isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = true);
                            } else {
                              setModalState(() {});
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Bank Name',
                            hintText: 'Select or type bank name',
                            labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isBankDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF6C6F79),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  isBankDropdownOpen = !isBankDropdownOpen;
                                  if (isBankDropdownOpen) {
                                    bankFocusNode.requestFocus();
                                  }
                                });
                              },
                            ),
                          ),
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF121214)),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Bank name is required';
                            if (val.trim().length > 100) return 'Bank name cannot exceed 100 characters';
                            return null;
                          },
                        ),

                        // Dropdown List Container (100% matches field width, pure white background)
                        if (isBankDropdownOpen) ...[
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 210),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                children: [
                                  if (filteredBanks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Text(
                                        'No matching preset bank found',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF9EA3AE),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  else
                                    ...filteredBanks.map((bank) {
                                      final isSelected = bankController.text.trim().toLowerCase() == bank.toLowerCase();
                                      return Material(
                                        color: isSelected ? const Color(0xFFFFF0F0) : Colors.white,
                                        child: InkWell(
                                          onTap: () {
                                            bankController.text = bank;
                                            setModalState(() {
                                              isBankDropdownOpen = false;
                                            });
                                            // Keep keyboard open and advance to Account Number field
                                            accountFocusNode.requestFocus();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    bank,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 13.5,
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                      color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(Icons.check_rounded, color: Color(0xFFE31C2E), size: 16),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  const Divider(height: 1, color: Color(0xFFF1F1F4)),
                                  Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          isBankDropdownOpen = false;
                                          if (_indianBanks.contains(bankController.text.trim())) {
                                            bankController.clear();
                                          }
                                        });
                                        bankFocusNode.requestFocus();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_note_rounded, color: Color(0xFFE31C2E), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Others (Enter Bank Manually)',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFFE31C2E),
                                                ),
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
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Account Number
                        TextFormField(
                          controller: accountNumberController,
                          focusNode: accountFocusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => ifscFocusNode.requestFocus(),
                          onTap: () {
                            if (isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = false);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Account Number',
                            hintText: isEdit && hasMaskedNumber
                                ? 'Enter full account number'
                                : 'Enter 6-50 digit account number',
                            helperText: isEdit && hasMaskedNumber
                                ? 'Account number was hidden for security. Enter full number.'
                                : null,
                            helperMaxLines: 2,
                            helperStyle: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79)),
                            labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5)),
                          ),
                          style: GoogleFonts.outfit(fontSize: 14),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Account number is required';
                            final clean = val.trim();
                            if (!RegExp(r'^[0-9]{6,50}$').hasMatch(clean)) {
                              return 'Account number must contain 6 to 50 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // IFSC Code
                        TextFormField(
                          controller: ifscController,
                          focusNode: ifscFocusNode,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => phoneFocusNode.requestFocus(),
                          onTap: () {
                            if (isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = false);
                            }
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(11),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'IFSC Code',
                            hintText: 'e.g. HDFC0001234',
                            labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5)),
                          ),
                          style: GoogleFonts.outfit(fontSize: 14),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'IFSC code is required';
                            final clean = val.trim().toUpperCase();
                            if (!RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$').hasMatch(clean)) {
                              return 'Invalid IFSC code (e.g. HDFC0001234)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Registered Phone Number (Mandatory, 10 digits)
                        TextFormField(
                          controller: phoneController,
                          focusNode: phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            if (isBankDropdownOpen) {
                              setModalState(() => isBankDropdownOpen = false);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Bank Registered Phone Number',
                            hintText: '10-digit mobile number',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF6C6F79)),
                            prefixText: '+91 ',
                            prefixStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF121214),
                            ),
                            labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5)),
                          ),
                          style: GoogleFonts.outfit(fontSize: 14),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Bank registered phone is required';
                            }
                            final cleanPhone = val.trim();
                            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
                              return 'Enter a valid 10-digit Indian mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSubmitting = true);

                                  final finalBankName = bankController.text.trim();

                                  final provider = context.read<CustomerWalletProvider>();
                                  final success = isEdit
                                      ? await provider.updateBankAccount(
                                          accountHolderName: holderNameController.text.trim(),
                                          accountNumber: accountNumberController.text.trim(),
                                          ifscCode: ifscController.text.trim().toUpperCase(),
                                          bankName: finalBankName,
                                          bankRegisteredPhone: phoneController.text.trim(),
                                        )
                                      : await provider.addBankAccount(
                                          accountHolderName: holderNameController.text.trim(),
                                          accountNumber: accountNumberController.text.trim(),
                                          ifscCode: ifscController.text.trim().toUpperCase(),
                                          bankName: finalBankName,
                                          bankRegisteredPhone: phoneController.text.trim(),
                                        );

                                  if (context.mounted) {
                                    setModalState(() => isSubmitting = false);
                                    if (success) {
                                      Navigator.pop(bottomSheetContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEdit
                                                ? 'Bank account updated successfully!'
                                                : 'Bank account added successfully!',
                                            style: GoogleFonts.outfit(),
                                          ),
                                          backgroundColor: const Color(0xFF15803D),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    } else {
                                      final err = provider.bankAccountError ?? 'Failed to save bank account';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err, style: GoogleFonts.outfit()),
                                          backgroundColor: const Color(0xFFE31C2E),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31C2E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : Text(
                                  isEdit ? 'Update Account' : 'Save Account',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBankAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Bank Account?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete this bank account? You will need to add a bank account again to withdraw funds.',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6C6F79), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<CustomerWalletProvider>();
              final success = await provider.deleteBankAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Bank account deleted successfully' : (provider.bankAccountError ?? 'Failed to delete bank account'),
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: success ? const Color(0xFF15803D) : const Color(0xFFE31C2E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
