import 'package:flutter/material.dart';

class UserPaymentsPage extends StatelessWidget {
  const UserPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE31C2E), Color(0xFFAE1220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                const Text('₹1,250.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Top Up', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send Money', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF121214))),
          const SizedBox(height: 10),

          // Transaction list
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTransactionItem(
                title: 'Wallet Top Up',
                date: '09 Jun 2026, 12:45 PM',
                amount: '+₹500.00',
                isCredit: true,
              ),
              _buildTransactionItem(
                title: 'Ride Paid (CS-98762)',
                date: '09 Jun 2026, 10:15 AM',
                amount: '-₹405.00',
                isCredit: false,
              ),
              _buildTransactionItem(
                title: 'Ride Paid (CS-98610)',
                date: '06 Jun 2026, 04:30 PM',
                amount: '-₹85.00',
                isCredit: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({required String title, required String date, required String amount, required bool isCredit}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7EB))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE7F7EF) : const Color(0xFFFDEBEC),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
              color: isCredit ? const Color(0xFF1C9A5B) : Colors.redAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF121214))),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF6C6F79))),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCredit ? const Color(0xFF1C9A5B) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
