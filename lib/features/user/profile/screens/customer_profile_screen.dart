import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Modern Color Palette
  static const Color _primaryColor = Color(0xFFC62E42);
  static const Color _accentBg = Color(0xFFFDF2F4);
  static const Color _inputBorderColor = Color(0xFFE2E8F0);
  static const Color _textColor = Color(0xFF1E293B);
  static const Color _subtitleColor = Color(0xFF64748B);

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
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: _textColor,
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
              SnackBar(
                content: Text('Profile image updated successfully!', style: GoogleFonts.outfit()),
                backgroundColor: const Color(0xFF1C9A5B),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Failed to upload profile image', style: GoogleFonts.outfit()),
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
            content: Text('Error picking image: $e', style: GoogleFonts.outfit()),
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
          SnackBar(
            content: Text('Profile updated successfully!', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF1C9A5B),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: _textColor,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textColor),
        shape: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      body: isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
          : RefreshIndicator(
              onRefresh: () async {
                _loadProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Bookings Count Row
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
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFC62E42), Color(0xFFA31E30)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          image: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(profileImageUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryColor.withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                            ? (_getInitials(profile?.fullName ?? user?.name).isNotEmpty
                                                ? Text(
                                                    _getInitials(profile?.fullName ?? user?.name),
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person_rounded,
                                                    color: Colors.white,
                                                    size: 32,
                                                  ))
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: _primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user?.name ?? 'User Name',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.phone ?? 'No Contact Info',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: _subtitleColor,
                                          fontWeight: FontWeight.w500,
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
                          const SizedBox(width: 12),
                          // Custom modern Bookings block without truck icon
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
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
                                Text(
                                  'My Bookings:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile != null ? profile.totalBookings.toString() : '0',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Section Title: Personal Info
                      Text(
                        'Personal Information',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender field (rounded selection box)
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
                      const SizedBox(height: 20),

                      // Date of Birth field (Tap to pick)
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        style: GoogleFonts.outfit(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Date of Birth',
                          hint: 'Select your date of birth',
                          suffixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bio field
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        style: GoogleFonts.outfit(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Bio',
                          hint: 'Enter a short bio or details about your goods',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section Title: Emergency Contacts
                      Text(
                        'Emergency Contact',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Name
                      TextFormField(
                        controller: _emergencyNameController,
                        style: GoogleFonts.outfit(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Contact Person Name',
                          hint: 'Enter emergency contact name',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Emergency Contact Phone
                      TextFormField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.outfit(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 10) {
                            return 'Please enter a valid 10-digit number';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          label: 'Contact Person Phone',
                          hint: 'Enter emergency contact phone number',
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _saveProfile(authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
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
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _subtitleColor),
      borderRadius: BorderRadius.circular(16),
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: _textColor,
        fontWeight: FontWeight.w600,
      ),
      items: items.map((String item) {
        // Display nice title-case item labels
        final formattedItem = item[0] + item.substring(1).toLowerCase();
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            formattedItem,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: _textColor,
              fontWeight: FontWeight.w600,
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
      labelStyle: GoogleFonts.outfit(color: _subtitleColor, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: _subtitleColor, size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
