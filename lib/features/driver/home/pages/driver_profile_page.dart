import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/features/driver/home/pages/driver_bank_accounts_page.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/features/driver/profile/driver_profile_screen.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/features/support/screens/support_tickets_screen.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingDocType;

  // Dark refined red shade for icons (consistent with UserAccountPage)
  static const Color _iconColor = Color(0xFF8B1A2B);
  static const Color _iconBgColor = Color(0xFFFDF2F4);
  static const Color _destructiveColor = Color(0xFFCC2D3B);
  static const Color _destructiveBgColor = Color(0xFFFDEBEC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchDriverProfile();
    });
  }

  void _handleRoleTransition() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateUserRole('ROLE_USER');
    
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/role_redirect', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to switch to Customer Mode.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _destructiveBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: _destructiveColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Logout',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF121214), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your partner account?',
          style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _destructiveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                context.read<LocationTrackingService>().stop();
              } catch (_) {}
              context.read<DriverHomeProvider>().clearData();
              await authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadDocument(String type, DriverHomeProvider provider) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image == null) return;

      setState(() {
        _uploadingDocType = type;
      });

      final success = await provider.uploadDocument(type, image.path);

      if (mounted) {
        setState(() {
          _uploadingDocType = null;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_formatDocType(type)} uploaded successfully!'),
              backgroundColor: const Color(0xFF1C9A5B),
            ),
          );
          // Re-fetch profile to update document status
          provider.fetchDriverProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to upload document'),
              backgroundColor: const Color(0xFFD90429),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingDocType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting/uploading document: $e'),
            backgroundColor: const Color(0xFFD90429),
          ),
        );
      }
    }
  }

  String _formatDocType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'DP';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);

    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    final driverName = profile?.name ?? user?.name ?? 'Partner';
    final driverPhone = profile?.phone ?? user?.phone ?? '';
    final approvalStatus = profile?.approvalStatus ?? 'PENDING';
    final profileImage = profile?.profileImage;

    final List<String> docTypes = [
      'AADHAAR_FRONT',
      'AADHAAR_BACK',
      'PAN_CARD',
      'DRIVING_LICENSE_FRONT',
      'DRIVING_LICENSE_BACK',
      'RC_BOOK',
      'INSURANCE',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                child: Text(
                  'Profile',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF121214),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF0F0F4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62E42).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: (profileImage != null && profileImage.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(profileImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: (profileImage == null || profileImage.isEmpty)
                          ? Text(
                              _getInitials(driverName),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  driverName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF121214),
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'PRO',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF664200),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+91 $driverPhone',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF6C6F79),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                approvalStatus == 'APPROVED' ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                size: 14,
                                color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  approvalStatus == 'APPROVED' ? 'Verified Partner' : 'Under Review',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: approvalStatus == 'APPROVED' ? const Color(0xFF1C9A5B) : const Color(0xFFB9700A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit Profile screen launcher icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverProfileScreen(startInEditMode: true),
                          ),
                        ).then((_) {
                          driverProvider.fetchDriverProfile();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3A3A42)),
                      ),
                    ),
                  ],
                ),
              ),

              // GENERAL Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'GENERAL',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9EA3AE),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildCard(
                children: [
                  _buildListItem(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverProfileScreen(),
                        ),
                      ).then((_) {
                        driverProvider.fetchDriverProfile();
                      });
                    },
                  ),
                   _buildListItem(
                    icon: Icons.account_balance_rounded,
                    label: 'Bank Accounts',
                    showBorder: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverBankAccountsPage(),
                        ),
                      );
                    },
                  ),
                  _buildListItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    showBorder: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportTicketsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /*
              // Switch Role Card
              GestureDetector(
                onTap: () => _handleRoleTransition(),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC62E42).withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Switch to Customer Mode',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Book rides and ship parcels',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              */

              // DOCUMENTS Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'DOCUMENTS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9EA3AE),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildCard(
                children: docTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;

                  DriverDocumentModel? doc;
                  if (profile?.documents != null) {
                    for (var d in profile!.documents) {
                      if (d.docType.toUpperCase() == type) {
                        if (doc == null || d.id > doc.id) {
                          doc = d;
                        }
                      }
                    }
                  }

                  return _buildDocTile(
                    context: context,
                    type: type,
                    doc: doc,
                    provider: driverProvider,
                    showBorder: index != docTypes.length - 1,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Logout Button
              GestureDetector(
                onTap: () => _showLogoutDialog(authProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E4F), Color(0xFFCC2D3B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E4F).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Version Info
              Center(
                child: Text(
                  'Riderzz Partner v1.0.0',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFFB0B5BF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBorder = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1F),
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B5BF), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocTile({
    required BuildContext context,
    required String type,
    required DriverDocumentModel? doc,
    required DriverHomeProvider provider,
    required bool showBorder,
  }) {
    final bool isUploaded = doc != null;
    final String status = doc != null ? doc.status.toUpperCase() : 'NOT_UPLOADED';
    final bool isUploading = _uploadingDocType == type;

    Color statusColor = const Color(0xFF64748B); // Not Uploaded (Gray)
    Color statusBg = const Color(0xFFF1F5F9);
    String statusText = 'Not Uploaded';

    if (status == 'APPROVED') {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
      statusText = 'Approved';
    } else if (status == 'PENDING' || status == 'PENDING_REVIEW' || status == 'UNDER_REVIEW') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusText = 'Under Review';
    } else if (status == 'REJECTED') {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusText = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFF0F0F4))) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: _iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDocType(type),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1F),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isUploading)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(6.0),
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_iconColor)),
              ),
            )
          else ...[
            if (isUploaded && doc.fileUrl.isNotEmpty) ...[
              // View Button
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDocType(type),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF121214)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                            child: Image.network(
                              doc.fileUrl,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  height: 200,
                                  child: Center(child: CircularProgressIndicator(color: _iconColor)),
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
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_outlined, color: Color(0xFF6C6F79), size: 16),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (status != 'APPROVED') ...[
              // Upload Button
              GestureDetector(
                onTap: () => _pickAndUploadDocument(type, provider),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: _iconColor, size: 16),
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }
}
