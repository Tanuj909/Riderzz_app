import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/commission_config_model.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/commission/providers/commission_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommissionProvider>().fetchCommissionConfigs();
      context.read<AdminVehiclesProvider>().fetchVehicleTypes();
    });
  }

  void _showFormDialog({CommissionConfigModel? config}) {
    showDialog(
      context: context,
      builder: (context) => CommissionFormDialog(config: config),
    );
  }

  void _confirmDelete(CommissionConfigModel config) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Delete Config',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete commission config for "${config.vehicleTypeName}" (${config.commissionPercent}%)? This action cannot be undone.',
          style: GoogleFonts.outfit(color: Color(0xFF4A5568), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Color(0xFF6C6F79))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<CommissionProvider>();
              final success = await provider.deleteCommissionConfig(config.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commission config deleted successfully!'),
                      backgroundColor: Color(0xFF1C9A5B),
                    ),
                  );
                } else if (provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage!),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE31C2E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Commission Configurations',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: Consumer<CommissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.configs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
              ),
            );
          }

          if (provider.errorMessage != null && provider.configs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Color(0xFF4A5568), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31C2E)),
                      onPressed: () => provider.fetchCommissionConfigs(),
                      child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.configs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.percent_rounded, color: Color(0xFFB0B8C4), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No configurations found',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF121214), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create custom commission percentages for your vehicle types.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Color(0xFF6C6F79), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31C2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text('Add Configuration', style: GoogleFonts.outfit(color: Colors.white)),
                      onPressed: () => _showFormDialog(),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCommissionConfigs(),
            color: const Color(0xFFE31C2E),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.configs.length,
              itemBuilder: (context, index) {
                final config = provider.configs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDEBEC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.airport_shuttle_rounded, color: Color(0xFFE31C2E), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                config.vehicleTypeName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBFDF6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${config.commissionPercent.toStringAsFixed(1)}% Commission',
                                      style: GoogleFonts.outfit(
                                        color: Color(0xFF1C9A5B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF6C6F79), size: 20),
                          onPressed: () => _showFormDialog(config: config),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmDelete(config),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CommissionFormDialog extends StatefulWidget {
  final CommissionConfigModel? config;

  const CommissionFormDialog({super.key, this.config});

  @override
  State<CommissionFormDialog> createState() => _CommissionFormDialogState();
}

class _CommissionFormDialogState extends State<CommissionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _percentController;

  int? _selectedVehicleTypeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _percentController = TextEditingController(
      text: widget.config != null ? widget.config!.commissionPercent.toString() : '',
    );
    _selectedVehicleTypeId = widget.config?.vehicleTypeId;
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final percent = double.parse(_percentController.text.trim());
    final provider = context.read<CommissionProvider>();
    bool success;

    if (widget.config != null) {
      success = await provider.updateCommissionConfig(
        configId: widget.config!.id,
        vehicleTypeId: _selectedVehicleTypeId!,
        commissionPercent: percent,
      );
    } else {
      success = await provider.createCommissionConfig(
        vehicleTypeId: _selectedVehicleTypeId!,
        commissionPercent: percent,
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.config != null
                  ? 'Commission config updated successfully!'
                  : 'Commission config created successfully!',
            ),
            backgroundColor: const Color(0xFF1C9A5B),
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = Provider.of<AdminVehiclesProvider>(context).vehicleTypes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.config != null ? 'Edit Configuration' : 'Add Configuration',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF121214)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79), size: 20),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Vehicle Type Dropdown
                Text(
                  'Vehicle Type',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _selectedVehicleTypeId,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C6F79)),
                  borderRadius: BorderRadius.circular(20),
                  onChanged: (val) {
                    setState(() {
                      _selectedVehicleTypeId = val;
                    });
                  },
                  style: GoogleFonts.outfit(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
                    ),
                  ),
                  items: vehicleTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type.id,
                      child: Text(
                        type.name,
                        style: GoogleFonts.outfit(color: Color(0xFF121214), fontSize: 13),
                      ),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Vehicle type is required' : null,
                ),
                
                const SizedBox(height: 16),

                // Commission Percent
                Text(
                  'Commission Percent (%)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121214)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _percentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'e.g., 15.5',
                    hintStyle: GoogleFonts.outfit(color: Color(0xFFB0B8C4), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Commission percent is required';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0 || parsed > 100) {
                      return 'Enter a valid percent between 0 and 100';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFE7E7EB)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: Color(0xFF4A5568))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31C2E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('Save', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}