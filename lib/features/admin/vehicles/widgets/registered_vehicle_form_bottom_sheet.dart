import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/core/models/admin_registered_vehicle_model.dart';

class RegisteredVehicleFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const RegisteredVehicleFormBottomSheet({super.key, required this.vehicle});

  @override
  State<RegisteredVehicleFormBottomSheet> createState() => _RegisteredVehicleFormBottomSheetState();
}

class _RegisteredVehicleFormBottomSheetState extends State<RegisteredVehicleFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconUrlController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _minWalletController = TextEditingController();

  bool _tollEnabled = false;
  bool _dynamicPricingEnabled = false;
  bool _active = true;
  String _selectedStatus = 'PENDING';
  bool _isSaving = false;

  String? _selectedTypeName;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final int fileSizeInBytes = await file.length();
      
      if (fileSizeInBytes > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Image is too large. Please select an image under 10MB.',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFD90429),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImageFile = file;
        _iconUrlController.text = pickedFile.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final AdminRegisteredVehicleModel model = AdminRegisteredVehicleModel.fromJson(widget.vehicle);
    
    // Initialize with data from model (some fields are dummy for now as backend doesn't provide them)
    final name = model.vehicleTypeName ?? 'Others';
    if (['Two-Wheeler', '3wheeler', 'EECO', 'ATA ACE', 'E loader', '8ft pick up', '10fit Truck', 'Truck 14ft', 'Truck 17ft', 'Truck 20ft'].contains(name)) {
      _selectedTypeName = name;
      _nameController.text = '';
    } else {
      _selectedTypeName = 'Others';
      _nameController.text = name;
    }
    
    _selectedStatus = model.status;
    _maxWeightController.text = widget.vehicle['maxWeightKg']?.toString() ?? '500';
    _minWalletController.text = widget.vehicle['minimumWalletBalance']?.toString() ?? '100.0';
    _tollEnabled = widget.vehicle['tollEnabled'] ?? false;
    _dynamicPricingEnabled = widget.vehicle['dynamicPricingEnabled'] ?? false;
    _active = widget.vehicle['active'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    _maxWeightController.dispose();
    _minWalletController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final String finalName = _selectedTypeName == 'Others'
        ? _nameController.text.trim()
        : (_selectedTypeName ?? '');

    if (finalName.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<AdminVehiclesProvider>();
    // For now, we only update the status since that's what the backend supports for registered vehicles
    final success = await provider.updateRegisteredVehicleStatus(widget.vehicle['id'], _selectedStatus);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vehicle updated successfully!',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1C9A5B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD90429),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isInteger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isInteger ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFB0B8C4), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF6F6F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFE7E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFE7E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD90429), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNumField(TextEditingController controller, String label, String hint, {bool isInteger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFB0B8C4), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF6F6F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFE7E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFE7E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD90429), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Icon',
          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F8),
              border: Border.all(color: const Color(0xFFE7E7EB)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                        )
                      : (_iconUrlController.text.isNotEmpty && !_iconUrlController.text.startsWith('/'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(_iconUrlController.text, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.image_outlined, color: Color(0xFFB0B8C4)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Icon',
                        style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PNG or JPG, max 10MB',
                        style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8C4)),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Vehicle Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type Name',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F8),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      value: _selectedTypeName,
                      hint: Text(
                        'Choose Type Name',
                        style: GoogleFonts.outfit(color: const Color(0xFFB0B8C4), fontSize: 14),
                      ),
                      style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 220,
                      items: [
                        'Two-Wheeler',
                        '3wheeler',
                        'EECO',
                        'ATA ACE',
                        'E loader',
                        '8ft pick up',
                        '10fit Truck',
                        'Truck 14ft',
                        'Truck 17ft',
                        'Truck 20ft',
                        'Others'
                      ]
                          .map((val) => DropdownMenuItem<String>(
                                value: val,
                                child: Text(val, style: GoogleFonts.outfit(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTypeName = val;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a type name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedTypeName == 'Others') ...[
                _buildTextField(_nameController, 'Custom Type Name', 'e.g. E-Rickshaw'),
                const SizedBox(height: 12),
              ],
              _buildIconSelector(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNumField(_maxWeightController, 'Max Weight (kg)', 'e.g. 20', isInteger: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNumField(_minWalletController, 'Min Wallet Balance (₹)', 'e.g. 100')),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Settings & Status',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFE31C2E),
                title: Text('Toll Enabled', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF121214))),
                subtitle: Text('Calculate toll fees on this vehicle type', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79))),
                value: _tollEnabled,
                onChanged: (val) {
                  setState(() {
                    _tollEnabled = val;
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFE31C2E),
                title: Text('Dynamic Pricing', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF121214))),
                subtitle: Text('Adjust fare based on demand / peak hours', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79))),
                value: _dynamicPricingEnabled,
                onChanged: (val) {
                  setState(() {
                    _dynamicPricingEnabled = val;
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFE31C2E),
                title: Text('Active Status', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF121214))),
                subtitle: Text('Allow new bookings with this vehicle type', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79))),
                value: _active,
                onChanged: (val) {
                  setState(() {
                    _active = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Status',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F8),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                        DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                        DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
