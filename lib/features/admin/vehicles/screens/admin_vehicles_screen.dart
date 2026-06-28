import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';

class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVehiclesProvider>().fetchVehicleTypes();
    });
  }

  void _showFormBottomSheet({VehicleTypeModel? vehicleType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleTypeFormBottomSheet(vehicleType: vehicleType),
    );
  }

  void _confirmDelete(BuildContext context, VehicleTypeModel vehicleType) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the vehicle type "${vehicleType.name}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF4A5568), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<AdminVehiclesProvider>();
              final success = await provider.deleteVehicleType(vehicleType.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle type deleted successfully!')),
                  );
                } else if (provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage!)),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<AdminVehiclesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vehicleTypes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
              ),
            );
          }

          if (provider.errorMessage != null && provider.vehicleTypes.isEmpty) {
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
                      style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3D6B)),
                      onPressed: () => provider.fetchVehicleTypes(),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchVehicleTypes(),
            color: const Color(0xFF1A3D6B),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Managment',
                                  style: TextStyle(
                                    color: Color(0xFF1A2233),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${provider.vehicleTypes.length} Active Types',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7785),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3D6B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _showFormBottomSheet(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (provider.vehicleTypes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F0FB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.airport_shuttle_outlined, size: 48, color: Color(0xFF1A3D6B)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Vehicle Categories',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create categories to configure pricing, commission, and weight capacities for booking dispatches.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7785), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final vehicle = provider.vehicleTypes[index];
                        return _buildVehicleCard(vehicle);
                      },
                      childCount: provider.vehicleTypes.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('bike') || name.contains('motorcycle') || name.contains('two wheeler')) {
      return Icons.motorcycle_rounded;
    } else if (name.contains('scooty') || name.contains('scooter') || name.contains('vespa') || name.contains('moped')) {
      return Icons.two_wheeler_rounded;
    } else if (name.contains('auto') || name.contains('rickshaw')) {
      return Icons.electric_rickshaw_rounded;
    } else if (name.contains('car') || name.contains('sedan') || name.contains('suv') || name.contains('cab')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('truck') || name.contains('lorry') || name.contains('pickup') || name.contains('tempo') || name.contains('load')) {
      return Icons.local_shipping_rounded;
    } else if (name.contains('cycle') || name.contains('bicycle')) {
      return Icons.pedal_bike_rounded;
    } else {
      return Icons.airport_shuttle_rounded; // default generic vehicle icon
    }
  }

  Widget _buildVehicleCard(VehicleTypeModel vehicle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: (vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.network(
                            vehicle.iconUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(_getVehicleIcon(vehicle.name), color: const Color(0xFF1A3D6B), size: 20),
                          ),
                        ),
                      )
                    : Icon(_getVehicleIcon(vehicle.name), color: const Color(0xFF1A3D6B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        color: Color(0xFF1A2233),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacity: ${vehicle.maxWeightKg} kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7785),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vehicle.isActive ? const Color(0xFFEBFDF6) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vehicle.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: vehicle.isActive ? const Color(0xFF0F9B6E) : Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFE9ECF0)),
          ),
          // Parameters Grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildParamItem('Base Fare', '₹${vehicle.baseFare.toStringAsFixed(1)}')),
                  Expanded(child: _buildParamItem('Rate/Km', '₹${vehicle.perKmRate.toStringAsFixed(1)}')),
                  Expanded(child: _buildParamItem('Max Weight', '${vehicle.maxWeightKg} kg')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildParamItem('Min Wallet Bal.', '₹${vehicle.minWalletBalance.toStringAsFixed(1)}')),
                  Expanded(child: _buildParamItem('Toll Fee', (vehicle.tollEnabled ?? false) ? 'Enabled' : 'Disabled')),
                  Expanded(child: _buildParamItem('Dynamic pricing', (vehicle.dynamicPricingEnabled ?? false) ? 'Active' : 'Inactive')),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFE9ECF0)),
          ),
          // Action buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF1A3D6B), size: 14),
                label: const Text('Edit', style: TextStyle(color: Color(0xFF1A3D6B), fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showFormBottomSheet(vehicleType: vehicle),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFFE8F0FB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7785),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// FORM BOTTOM SHEET STATEFUL WIDGET
class VehicleTypeFormBottomSheet extends StatefulWidget {
  final VehicleTypeModel? vehicleType;

  const VehicleTypeFormBottomSheet({super.key, this.vehicleType});

  @override
  State<VehicleTypeFormBottomSheet> createState() => _VehicleTypeFormBottomSheetState();
}

class _VehicleTypeFormBottomSheetState extends State<VehicleTypeFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconUrlController = TextEditingController();
  final _baseFareController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _minWalletController = TextEditingController();

  bool _tollEnabled = false;
  bool _dynamicPricingEnabled = false;
  bool _active = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleType != null) {
      final v = widget.vehicleType!;
      _nameController.text = v.name;
      _iconUrlController.text = v.iconUrl ?? '';
      _baseFareController.text = v.baseFare.toStringAsFixed(1);
      _perKmRateController.text = v.perKmRate.toStringAsFixed(1);
      _maxWeightController.text = v.maxWeightKg.toString();
      _minWalletController.text = v.minWalletBalance.toStringAsFixed(1);
      _tollEnabled = v.tollEnabled ?? false;
      _dynamicPricingEnabled = v.dynamicPricingEnabled ?? false;
      _active = v.isActive;
    } else {
      _iconUrlController.text = 'https://cdn-icons-png.flaticon.com/128/11432/11432322.png';
      _tollEnabled = false;
      _dynamicPricingEnabled = false;
      _active = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    _baseFareController.dispose();
    _perKmRateController.dispose();
    _maxWeightController.dispose();
    _minWalletController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<AdminVehiclesProvider>();
    final success = widget.vehicleType == null
        ? await provider.createVehicleType(
            name: _nameController.text.trim(),
            iconUrl: _iconUrlController.text.trim(),
            maxWeightKg: int.parse(_maxWeightController.text.trim()),
            baseFare: double.parse(_baseFareController.text.trim()),
            perKmRate: double.parse(_perKmRateController.text.trim()),
            minimumWalletBalance: double.parse(_minWalletController.text.trim()),
            tollEnabled: _tollEnabled,
            dynamicPricingEnabled: _dynamicPricingEnabled,
            active: _active,
          )
        : await provider.updateVehicleType(
            id: widget.vehicleType!.id,
            name: _nameController.text.trim(),
            iconUrl: _iconUrlController.text.trim(),
            maxWeightKg: int.parse(_maxWeightController.text.trim()),
            baseFare: double.parse(_baseFareController.text.trim()),
            perKmRate: double.parse(_perKmRateController.text.trim()),
            minimumWalletBalance: double.parse(_minWalletController.text.trim()),
            tollEnabled: _tollEnabled,
            dynamicPricingEnabled: _dynamicPricingEnabled,
            active: _active,
          );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicleType == null
                  ? 'Vehicle type created successfully!'
                  : 'Vehicle type updated successfully!',
            ),
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }
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
              // Pull Bar indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECF0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.vehicleType == null ? 'Create Vehicle Type' : 'Edit Vehicle Type',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
              ),
              const SizedBox(height: 20),

              // Inputs
              _buildTextField(_nameController, 'Type Name', 'e.g. Bike'),
              const SizedBox(height: 12),
              _buildTextField(_iconUrlController, 'Icon URL', 'e.g. https://...'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNumField(_baseFareController, 'Base Fare (₹)', 'e.g. 20')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNumField(_perKmRateController, 'Rate/Km (₹)', 'e.g. 13')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNumField(_maxWeightController, 'Max Weight (kg)', 'e.g. 20', isInteger: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNumField(_minWalletController, 'Min Wallet Balance (₹)', 'e.g. 100')),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Settings & Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF1A3D6B),
                title: const Text('Toll Enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A2233))),
                subtitle: const Text('Calculate toll fees on this vehicle type', style: TextStyle(fontSize: 11, color: Color(0xFF6B7785))),
                value: _tollEnabled,
                onChanged: (val) {
                  setState(() {
                    _tollEnabled = val;
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF1A3D6B),
                title: const Text('Dynamic Pricing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A2233))),
                subtitle: const Text('Adjust fare based on demand / peak hours', style: TextStyle(fontSize: 11, color: Color(0xFF6B7785))),
                value: _dynamicPricingEnabled,
                onChanged: (val) {
                  setState(() {
                    _dynamicPricingEnabled = val;
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF1A3D6B),
                title: const Text('Active Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A2233))),
                subtitle: const Text('Allow new bookings with this vehicle type', style: TextStyle(fontSize: 11, color: Color(0xFF6B7785))),
                value: _active,
                onChanged: (val) {
                  setState(() {
                    _active = val;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE9ECF0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7785), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D6B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSaving ? null : _submitForm,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border.all(color: const Color(0xFFE9ECF0)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB0B8C4)),
              border: InputBorder.none,
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border.all(color: const Color(0xFFE9ECF0)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextFormField(
            controller: controller,
            keyboardType: isInteger ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB0B8C4)),
              border: InputBorder.none,
              isDense: true,
            ),
            inputFormatters: [
              if (isInteger) FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              if (isInteger) {
                if (int.tryParse(value.trim()) == null) {
                  return 'Invalid integer';
                }
              } else {
                if (double.tryParse(value.trim()) == null) {
                  return 'Invalid decimal';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
