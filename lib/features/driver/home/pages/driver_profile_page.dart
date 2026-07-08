import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_bank_accounts_page.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  void _handleRoleTransition(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateUserRole('ROLE_USER');
    
    if (success && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/role_redirect', (route) => false);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to switch to Customer Mode.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);

    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    final driverName = profile?.name ?? user?.name ?? 'Partner';
    final driverPhone = profile?.phone ?? user?.phone ?? '';
    final approvalStatus = profile?.approvalStatus ?? 'UNDER_REVIEW';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar and Name Header
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD90429), // var(--red)
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD90429).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Text(
                    driverName.isNotEmpty ? driverName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEBEC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Color(0xFFD90429),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+91 $driverPhone',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6C6F79),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFE1E1E6), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          approvalStatus == 'APPROVED' ? Icons.verified_rounded : Icons.pending_actions_rounded,
                          color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          approvalStatus == 'APPROVED' ? 'Verified' : 'Reviewing',
                          style: TextStyle(
                            color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nav Card
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E1E6)),
              boxShadow: const [
                BoxShadow(color: Color(0x05121214), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildNavTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  onTap: () {},
                  showBorder: true,
                ),
                _buildNavTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Accounts',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverBankAccountsPage()));
                  },
                  showBorder: false,
                ),
              ],
            ),
          ),

          // Documents Header
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Documents',
              style: TextStyle(
                color: Color(0xFF6C6F79),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Documents Card
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E1E6)),
              boxShadow: const [
                BoxShadow(color: Color(0x05121214), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                if (profile?.documents != null && profile!.documents.isNotEmpty)
                  ...profile.documents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    return _buildDocTile(
                      title: doc.docType.replaceAll('_', ' '),
                      subtitle: 'Doc #${doc.id}',
                      status: doc.status,
                      showBorder: index != profile.documents.length - 1,
                    );
                  })
                else ...[
                  _buildDocTile(title: 'Driving License', subtitle: 'DL-1420110012345', status: 'APPROVED', showBorder: true),
                  _buildDocTile(title: 'Vehicle RC', subtitle: 'UP16-CV-4471', status: 'APPROVED', showBorder: true),
                  _buildDocTile(title: 'Aadhar Card', subtitle: '**** **** 1234', status: 'PENDING', showBorder: false),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Switch Role Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD90429),
              side: const BorderSide(color: Color(0xFFFDEBEC), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _handleRoleTransition(context),
            child: const Text(
              'Switch to Rider Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          // Logout Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF121214),
              side: const BorderSide(color: Color(0xFFE1E1E6), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final ap = Provider.of<AuthProvider>(context, listen: false);
              await ap.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required VoidCallback onTap, required bool showBorder}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFE1E1E6))) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF121214), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF121214),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EA0A5), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile({required String title, required String subtitle, required String status, required bool showBorder}) {
    final isApproved = status == 'APPROVED';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFE1E1E6))) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF6C6F79), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF121214),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6C6F79),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFFE7F7EF) : const Color(0xFFFCF0DC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isApproved ? Icons.check_rounded : Icons.more_horiz_rounded,
              color: isApproved ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

