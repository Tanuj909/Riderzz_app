import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_bank_accounts_page.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_all_bookings_screen.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 20.0),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Color(0xFF121214),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),

              // Avatar and Name Header (Left Shifted)
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD90429), // var(--red)
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFD90429).withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        driverName.isNotEmpty ? driverName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Outfit',
                                  color: Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDEBEC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Color(0xFFD90429),
                                    fontSize: 9,
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+91 $driverPhone',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontFamily: 'Outfit',
                              color: Color(0xFF6C6F79),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                approvalStatus == 'APPROVED' ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                approvalStatus == 'APPROVED' ? 'Verified Partner' : 'Verification Reviewing',
                                style: TextStyle(
                                  color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5,
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

              // Nav Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x02121214), blurRadius: 8, offset: Offset(0, 2)),
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
                      showBorder: true,
                    ),
                    _buildNavTile(
                      icon: Icons.assignment_outlined,
                      title: 'All Bookings',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverAllBookingsScreen()));
                      },
                      showBorder: false,
                    ),
                  ],
                ),
              ),

              // Documents Header
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Documents',
                  style: TextStyle(
                    color: Color(0xFFA2A5AE),
                    fontSize: 11,
                    fontFamily: 'Outfit',
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Documents Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x02121214), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    if (profile?.documents != null && profile!.documents.isNotEmpty)
                      ...profile.documents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        return _buildDocTile(
                          context: context,
                          title: doc.docType.replaceAll('_', ' '),
                          subtitle: 'Doc #${doc.id}',
                          status: doc.status,
                          url: doc.fileUrl,
                          showBorder: index != profile.documents.length - 1,
                        );
                      })
                    else ...[
                      _buildDocTile(context: context, title: 'Driving License', subtitle: 'DL-1420110012345', status: 'APPROVED', url: null, showBorder: true),
                      _buildDocTile(context: context, title: 'Vehicle RC', subtitle: 'UP16-CV-4471', status: 'APPROVED', url: null, showBorder: true),
                      _buildDocTile(context: context, title: 'Aadhar Card', subtitle: '**** **** 1234', status: 'PENDING', url: null, showBorder: false),
                    ],
                  ],
                ),
              ),
              
              // Logout Button (Dark Red Gradient)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD90429), Color(0xFF8D021F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD90429).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      context.read<LocationTrackingService>().stop();
                    } catch (_) {}
                    final ap = Provider.of<AuthProvider>(context, listen: false);
                    await ap.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 14, fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.normal),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required VoidCallback onTap, required bool showBorder}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFE1E1E6))) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF121214), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF121214),
                  fontSize: 14,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EA0A5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String status,
    required String? url,
    required bool showBorder,
  }) {
    final isApproved = status == 'APPROVED';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFE1E1E6))) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF6C6F79), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF121214),
                    fontSize: 14,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6C6F79),
                    fontSize: 12,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFFE7F7EF) : const Color(0xFFFCF0DC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApproved ? Icons.check_rounded : Icons.more_horiz_rounded,
                  color: isApproved ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                  size: 12,
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF6C6F79), size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit', fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                          child: Image.network(
                            url,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator(color: Color(0xFFD90429))),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 150,
                              child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
