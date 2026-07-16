import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';

class DriverProfileScreen extends StatefulWidget {
  final bool startInEditMode;
  final bool expandDocuments;

  const DriverProfileScreen({
    super.key,
    this.startInEditMode = false,
    this.expandDocuments = false,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  late bool _isDocumentsExpanded;
  bool _isUploadingDoc = false;
  
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _licenseController;
  late TextEditingController _bioController;
  late TextEditingController _upiController;
  late TextEditingController _dobController;
  String _selectedGender = 'MALE';

  @override
  void initState() {
    _isEditing = widget.startInEditMode;
    _isDocumentsExpanded = widget.expandDocuments;
    super.initState();
    _licenseController = TextEditingController();
    _bioController = TextEditingController();
    _upiController = TextEditingController();
    _dobController = TextEditingController();
    
    // Fetch profile on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final profile = context.read<DriverHomeProvider>().profile;
    if (profile != null) {
      _licenseController.text = profile.licenseNumber;
      _bioController.text = profile.bio;
      _upiController.text = profile.upiId ?? '';
      _dobController.text = profile.dob ?? '';
      _selectedGender = ['MALE', 'FEMALE', 'OTHER'].contains(profile.gender.toUpperCase())
          ? profile.gender.toUpperCase()
          : 'MALE';
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _bioController.dispose();
    _upiController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18)); // 18 years ago
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Minimum 16 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD90429),
              onPrimary: Colors.white,
              onSurface: Color(0xFF121214),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD90429),
              ),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DriverHomeProvider>();
    final success = await provider.updateProfile(
      licenseNumber: _licenseController.text.trim(),
      bio: _bioController.text.trim(),
      gender: _selectedGender,
      dob: _dobController.text.trim(),
      upiId: _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF1C9A5B),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: const Color(0xFFD90429),
          ),
        );
      }
    }
  }

  void _showDocumentPreview(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: const Color(0xFFF1F1F4),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 300,
                    width: double.infinity,
                    color: const Color(0xFFFFF5F5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_rounded, color: Color(0xFFD90429), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load image preview',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFD90429),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
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
        _isUploadingDoc = true;
      });

      final success = await provider.uploadDocument(type, image.path);

      if (mounted) {
        setState(() {
          _isUploadingDoc = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_formatDocType(type)} uploaded successfully!'),
              backgroundColor: const Color(0xFF1C9A5B),
            ),
          );
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
          _isUploadingDoc = false;
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
    return type
        .replaceAll('_FRONT', ' Front')
        .replaceAll('_BACK', ' Back')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return const Color(0xFF1C9A5B);
      case 'PENDING':
        return const Color(0xFFB9700A);
      case 'REJECTED':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFF6C6F79);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final profile = driverProvider.profile;

    if (profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Profile',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF121214),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
          ),
        ),
      );
    }

    final String initials = profile.name.trim().isEmpty
        ? 'D'
        : profile.name.trim().split(' ').take(2).map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF121214),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: const Color(0xFF121214)),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _loadProfileData();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          driverProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isEditing) ...[
                          // Modern Left-Aligned Header Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 8)),
                              ],
                              border: Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD90429).withOpacity(0.1),
                                    border: Border.all(color: const Color(0xFFD90429), width: 2),
                                    image: profile.profileImage != null && profile.profileImage!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(profile.profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: profile.profileImage == null || profile.profileImage!.isEmpty
                                      ? Text(
                                          initials,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFFD90429),
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF121214),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(profile.approvalStatus).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              profile.approvalStatus.toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(profile.approvalStatus),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Mini Stats Row
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${profile.rating.toStringAsFixed(1)} Rating',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4A5568),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.local_shipping_rounded, color: Color(0xFF1C9A5B), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${profile.totalTrips} Trips',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4A5568),
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
                          const SizedBox(height: 24),
                        ],
                        if (!_isEditing) ...[
                          // View Mode Layout
                          _buildSectionTitle('PERSONAL DETAILS'),
                          _buildDetailCard([
                            _buildDetailItem('Phone Number', profile.phone, Icons.phone_android_rounded),
                            _buildDetailItem('Email Address', profile.email.isNotEmpty ? profile.email : 'N/A', Icons.email_outlined),
                            _buildDetailItem('UPI ID (for payments)', profile.upiId ?? 'N/A', Icons.account_balance_wallet_outlined),
                            _buildDetailItem('Gender', profile.gender, Icons.wc_rounded),
                            _buildDetailItem('Date of Birth', profile.dob ?? 'N/A', Icons.cake_outlined),
                            _buildDetailItem('Driver Bio', profile.bio.isNotEmpty ? profile.bio : 'No bio added.', Icons.info_outline_rounded, isLast: true),
                          ]),
                          const SizedBox(height: 24),

                          _buildSectionTitle('VEHICLE & LICENSE'),
                          _buildDetailCard([
                            _buildDetailItem('Vehicle Type', profile.vehicleTypeName.isNotEmpty ? profile.vehicleTypeName : 'N/A', Icons.category_outlined),
                            _buildDetailItem('Vehicle Details', profile.vehicle != null ? '${profile.vehicle!.make} ${profile.vehicle!.model}' : 'N/A', Icons.drive_eta_rounded),
                            _buildDetailItem('Registration Number', profile.vehicleNumber, Icons.pin_rounded),
                            _buildDetailItem('Vehicle Color', profile.color.isNotEmpty ? profile.color : 'N/A', Icons.palette_outlined),
                            _buildDetailItem('Manufacturing Year', profile.manufacturingYear > 0 ? '${profile.manufacturingYear}' : 'N/A', Icons.calendar_today_rounded),
                            _buildDetailItem('License Number', profile.licenseNumber, Icons.badge_outlined),
                            _buildDetailItem('License Expiry', profile.licenseExpiry.isNotEmpty ? profile.licenseExpiry : 'N/A', Icons.event_busy_rounded),
                            _buildDetailItem('Insurance Expiry', profile.insuranceExpiry.isNotEmpty ? profile.insuranceExpiry : 'N/A', Icons.security_rounded, isLast: true),
                          ]),
                          const SizedBox(height: 24),

                          _buildSectionTitle('VERIFICATION DOCUMENTS'),
                          _buildCollapsibleDocuments(profile, driverProvider),
                        ] else ...[
                          // Edit Mode Form Layout
                          _buildSectionTitle('EDIT PERSONAL DETAILS'),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bio
                                _buildTextField(
                                  label: 'Bio',
                                  controller: _bioController,
                                  icon: Icons.info_outline_rounded,
                                  maxLines: 3,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Bio cannot be empty' : null,
                                ),
                                const SizedBox(height: 16),
                                // License Number
                                _buildTextField(
                                  label: 'License Number',
                                  controller: _licenseController,
                                  icon: Icons.badge_outlined,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'License Number is required' : null,
                                ),
                                const SizedBox(height: 16),
                                // UPI ID
                                _buildTextField(
                                  label: 'UPI ID (for earnings payout)',
                                  controller: _upiController,
                                  icon: Icons.account_balance_wallet_outlined,
                                  hintText: 'e.g. name@upi',
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (!val.contains('@')) {
                                        return 'Please enter a valid UPI ID (must contain @)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Gender Dropdown
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gender',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6C6F79),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedGender,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.wc_rounded, color: Color(0xFF6C6F79)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        filled: true,
                                        fillColor: const Color(0xFFF1F1F4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      items: ['MALE', 'FEMALE', 'OTHER'].map((g) {
                                        return DropdownMenuItem<String>(
                                          value: g,
                                          child: Text(
                                            g,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedGender = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // DOB Date Picker
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: AbsorbPointer(
                                    child: _buildTextField(
                                      label: 'Date of Birth',
                                      controller: _dobController,
                                      icon: Icons.calendar_today_rounded,
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Date of birth is required' : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('VERIFICATION DOCUMENTS'),
                          _buildCollapsibleDocuments(profile, driverProvider),
                          const SizedBox(height: 28),
                          // Save Profile Button
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD90429),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          if (_isUploadingDoc)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                  margin: EdgeInsets.all(32),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Uploading document...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDocuments(DriverProfileModel profile, DriverHomeProvider provider) {
    final List<String> docTypes = [
      'AADHAAR_FRONT',
      'AADHAAR_BACK',
      'PAN_CARD',
      'DRIVING_LICENSE_FRONT',
      'DRIVING_LICENSE_BACK',
      'RC_BOOK',
      'INSURANCE',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isDocumentsExpanded,
          onExpansionChanged: (val) {
            setState(() {
              _isDocumentsExpanded = val;
            });
          },
          leading: const Icon(Icons.folder_shared_rounded, color: Color(0xFFD90429)),
          title: Text(
            'Manage Verification Documents',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF121214),
            ),
          ),
          subtitle: Text(
            '${profile.documents.length} of ${docTypes.length} documents uploaded',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF6C6F79),
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F1F4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: docTypes.map((type) {
                  DriverDocumentModel? matchingDoc;
                  for (final doc in profile.documents) {
                    if (doc.docType.toUpperCase() == type.toUpperCase() ||
                        (type == 'DRIVING_LICENSE_FRONT' && doc.docType.toUpperCase() == 'DRIVING_LICENSE')) {
                      matchingDoc = doc;
                      break;
                    }
                  }
                  return _buildDocumentSlotRow(type, matchingDoc, provider);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSlotRow(String type, DriverDocumentModel? doc, DriverHomeProvider provider) {
    final statusColor = doc != null ? _getStatusColor(doc.status) : const Color(0xFF6C6F79);
    final String statusText = doc != null ? doc.status.toUpperCase() : 'NOT UPLOADED';
    final bool isUploaded = doc != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDocType(type),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: const Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUploaded && doc.fileUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'View Document',
                      icon: const Icon(Icons.visibility_rounded, color: Color(0xFF1C9A5B), size: 20),
                      onPressed: () => _showDocumentPreview(context, doc.fileUrl, _formatDocType(type)),
                    ),
                  IconButton(
                    tooltip: isUploaded ? 'Update Document' : 'Upload Document',
                    icon: Icon(
                      isUploaded ? Icons.cached_rounded : Icons.upload_file_rounded,
                      color: const Color(0xFFD90429),
                      size: 20,
                    ),
                    onPressed: () => _pickAndUploadDocument(type, provider),
                  ),
                ],
              ),
            ],
          ),
          if (doc != null && doc.rejectionReason != null && doc.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD1D1)),
              ),
              child: Text(
                'Rejection Reason: ${doc.rejectionReason}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFD90429),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.ibmPlexMono(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: const Color(0xFF121214),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C6F79),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6C6F79),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6C6F79)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C6F79),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF1F1F4)),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6C6F79),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFB0B8C4), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF6C6F79)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF1F1F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFD90429), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
