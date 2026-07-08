import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/core/models/customer_profile_model.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobController = TextEditingController();
  final _bioController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.fetchCustomerProfile();
    final profile = authProvider.customerProfile;
    if (profile != null) {
      setState(() {
        _dobController.text = profile.dob ?? '';
        _bioController.text = profile.bio ?? '';
        _emergencyNameController.text = profile.emergencyContactName ?? '';
        _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
        _selectedGender = (profile.gender == null || profile.gender!.isEmpty) 
            ? null 
            : profile.gender;
      });
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE31C2E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF121214),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickAndUploadImage(AuthProvider authProvider) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final success = await authProvider.updateProfileImage(image.path, image.name);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully!'),
                backgroundColor: Color(0xFF1C9A5B),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Failed to upload profile image'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _saveProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.updateCustomerProfile(
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      bio: _bioController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF1C9A5B),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'RK';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final profile = authProvider.customerProfile;
    final isLoading = authProvider.isLoading;

    final profileImageUrl = profile?.profileImage ?? user?.profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF121214)),
      ),
      body: isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E))))
          : RefreshIndicator(
              onRefresh: () async {
                _loadProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar Card
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: isLoading ? null : () => _pickAndUploadImage(authProvider),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE31C2E),
                                          shape: BoxShape.circle,
                                          image: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(profileImageUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                            ? Text(
                                                _getInitials(user?.name),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE31C2E),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user?.name ?? 'Customer Name',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.phone ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6C6F79),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildStatCard(
                              icon: Icons.local_shipping_rounded,
                              iconColor: const Color(0xFF1C9A5B),
                              value: profile != null ? profile.totalBookings.toString() : '0',
                              label: 'Bookings',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section Title: Personal Info
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 12),

                      // Gender field
                      _buildDropdownField(
                        label: 'Gender',
                        value: _selectedGender,
                        items: ['MALE', 'FEMALE', 'OTHER'],
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth field (Tap to pick)
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        style: const TextStyle(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          label: 'Date of Birth',
                          suffixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio field
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        style: const TextStyle(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          label: 'Bio',
                          hint: 'Describe yourself or details about your goods',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Title: Emergency Contacts
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 12),

                      // Emergency Contact Name
                      TextFormField(
                        controller: _emergencyNameController,
                        style: const TextStyle(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          label: 'Contact Person Name',
                          hint: 'e.g. Tanuj Kashyap',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Phone
                      TextFormField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w500),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 10) {
                            return 'Please enter a valid 10-digit number';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          label: 'Contact Person Phone',
                          hint: 'e.g. 9891004821',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _saveProfile(authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31C2E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6C6F79)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6C6F79)),
      borderRadius: BorderRadius.circular(12),
      style: const TextStyle(fontSize: 14, color: Color(0xFF121214), fontWeight: FontWeight.w500),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF121214),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: _buildInputDecoration(label: label),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF6C6F79), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF6C6F79), size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD2D6DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
