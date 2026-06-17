import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';

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
    final licenseNumber = profile?.licenseNumber ?? 'N/A';
    final vehicleNumber = profile?.vehicleNumber ?? 'N/A';
    final vehicleDetails = profile?.vehicle != null
        ? '${profile!.vehicle!.make} ${profile.vehicle!.model}'
        : 'N/A';
    final vehicleCategory = profile?.vehicle?.vehicleTypeName ?? 'N/A';
    final approvalStatus = profile?.approvalStatus ?? 'UNDER_REVIEW';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A3D6B),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    driverName.isNotEmpty ? driverName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+91 $driverPhone',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: approvalStatus == 'APPROVED' ? const Color(0xFFE6F7F2) : const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    approvalStatus,
                    style: TextStyle(
                      color: approvalStatus == 'APPROVED' ? const Color(0xFF0F9B6E) : const Color(0xFFF97316),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle Info Section
          const Text(
            'Vehicle Credentials',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('License Number', licenseNumber),
          _buildInfoRow('Vehicle Plate Number', vehicleNumber),
          _buildInfoRow('Vehicle Details', vehicleDetails),
          _buildInfoRow('Vehicle Category', vehicleCategory),

          const SizedBox(height: 24),

          // Uploaded Documents Section
          const Text(
            'Uploaded Documents',
            style: TextStyle(color: Color(0xFF1A2233), fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (profile?.documents != null && profile!.documents.isNotEmpty)
            ...profile.documents.map((doc) => _buildDocumentTile(
                  doc.docType.replaceAll('_', ' '),
                  doc.status,
                ))
          else ...[
            _buildDocumentTile('AADHAR CARD', 'APPROVED'),
            _buildDocumentTile('PAN CARD', 'APPROVED'),
            _buildDocumentTile('DRIVING LICENSE', 'APPROVED'),
          ],

          const SizedBox(height: 36),

          // Role Switching Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FB),
              foregroundColor: const Color(0xFF1A3D6B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => _handleRoleTransition(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.swap_horiz_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Switch to Customer Mode',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7785), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFF1A2233), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String name, String status) {
    final isApproved = status == 'APPROVED';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFF1A3D6B), size: 20),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                color: isApproved ? const Color(0xFF0F9B6E) : const Color(0xFFF97316),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: isApproved ? const Color(0xFF0F9B6E) : const Color(0xFFF97316),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
