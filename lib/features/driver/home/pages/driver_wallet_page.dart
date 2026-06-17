import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';

class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
  final _rechargeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchDriverWallet();
    });
  }

  @override
  void dispose() {
    _rechargeController.dispose();
    super.dispose();
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    try {
      final parts = dateTimeStr.split('T');
      if (parts.length < 2) return dateTimeStr;
      final date = parts[0];
      final timeParts = parts[1].split('.');
      final time = timeParts[0];
      return '$date $time';
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
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Recharge Wallet',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enter amount (₹)',
                        style: TextStyle(color: Color(0xFF6B7785), fontSize: 13),
                      ),
                      Text(
                        'Limit: ₹${minBal.toStringAsFixed(0)} - ₹2,000',
                        style: const TextStyle(color: Color(0xFF9AA5B4), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rechargeController,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE9ECF0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick select chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [100, 500, 1000].map((amount) {
                      return ChoiceChip(
                        label: Text('₹$amount'),
                        selected: _rechargeController.text == amount.toString(),
                        onSelected: isSubmitting
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _rechargeController.text = amount.toString();
                                  });
                                }
                              },
                        selectedColor: const Color(0xFFE8F0FB),
                        backgroundColor: const Color(0xFFF7F8FA),
                        labelStyle: TextStyle( 
                          color: _rechargeController.text == amount.toString()
                              ? const Color(0xFF1A3D6B)
                              : const Color(0xFF6B7785),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785))),
                ),
                isSubmitting
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final amtStr = _rechargeController.text.trim();
                          final amt = double.tryParse(amtStr);
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount')),
                            );
                            return;
                          }

                          final minBal = provider.wallet?.minBalanceRequired ?? 100.0;
                          if (amt < minBal) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Recharge amount must be at least ₹${minBal.toStringAsFixed(2)}'),
                                backgroundColor: const Color(0xFFF97316),
                              ),
                            );
                            return;
                          }

                          if (amt > 2000.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recharge amount cannot exceed ₹2,000.00'),
                                backgroundColor: Color(0xFFF97316),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          final success = await provider.rechargeWallet(amt);
                          
                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Wallet recharged successfully! 🎉'),
                                  backgroundColor: Color(0xFF0F9B6E),
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.walletError ?? 'Failed to recharge wallet.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Recharge'),
                      ),
              ],
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  driverProvider.walletError!,
                  style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3D6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<DriverHomeProvider>().fetchDriverWallet();
                  },
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w500)),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wallet Balance Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A3D6B),
                  Color(0xFF2563A8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A3D6B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () => _showRechargeDialog(context, driverProvider),
                      child: const Text(
                        'Recharge',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Text(
                  'Minimum Required Balance: ₹${minBal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Low Balance Warning
          if (isLowBalance)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF97316), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alert: Balance is below the minimum required amount. Please recharge to continue receiving ride bookings.',
                      style: TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Transactions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Color(0xFF1A2233),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A3D6B), size: 20),
                onPressed: () {
                  context.read<DriverHomeProvider>().fetchDriverWallet();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transactions List
          if (transactions.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9ECF0)),
              ),
              child: const Text(
                'No transactions found.',
                style: TextStyle(color: Color(0xFF6B7785), fontSize: 13),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isPayout = tx.type == 'RECHARGE' || tx.type == 'BONUS';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECF0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPayout ? const Color(0xFFE6F7F2) : const Color(0xFFF7F8FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPayout ? Icons.add_rounded : Icons.call_made_rounded,
                          color: isPayout ? const Color(0xFF0F9B6E) : const Color(0xFF6B7785),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: const TextStyle(
                                color: Color(0xFF1A2233),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(tx.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF6B7785),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isPayout ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPayout ? const Color(0xFF0F9B6E) : const Color(0xFF1A2233),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
