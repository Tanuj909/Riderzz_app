import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_list_provider.dart';
import 'package:riderzz_app/features/admin/commission/providers/pricing_provider.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PricingProvider>().fetchPricingTiers(1);
      context.read<AdminVehiclesProvider>().fetchVehicleTypes();
      // Fetch APPROVED vehicles with vehicleTypeId=1 as requested to initialize or verify
      context.read<AdminVehiclesListProvider>().fetchVehicles(status: 'APPROVED', vehicleTypeId: 1, isRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Pricing Configurations',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vehicle Pricing'),
            Tab(text: 'Pricing Rules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VehiclePricingTab(),
          const _PricingRulesTab(),
        ],
      ),
    );
  }
}

class _VehiclePricingTab extends StatefulWidget {
  @override
  State<_VehiclePricingTab> createState() => _VehiclePricingTabState();
}

class _VehiclePricingTabState extends State<_VehiclePricingTab> {
  int? _selectedVehicleTypeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehiclesProvider = context.read<AdminVehiclesProvider>();
      if (vehiclesProvider.vehicleTypes.isNotEmpty) {
        setState(() {
          _selectedVehicleTypeId = vehiclesProvider.vehicleTypes.first.id;
        });
        context.read<PricingProvider>().fetchPricingTiers(_selectedVehicleTypeId!);
      } else {
        vehiclesProvider.fetchVehicleTypes().then((_) {
          if (mounted && vehiclesProvider.vehicleTypes.isNotEmpty) {
            setState(() {
              _selectedVehicleTypeId = vehiclesProvider.vehicleTypes.first.id;
            });
            context.read<PricingProvider>().fetchPricingTiers(_selectedVehicleTypeId!);
          }
        });
      }
    });
  }

  void _showFormDialog({PricingTierModel? tier}) {
    showDialog(
      context: context,
      builder: (context) => PricingTierFormDialog(tier: tier, defaultVehicleTypeId: _selectedVehicleTypeId),
    );
  }

  void _confirmDelete(PricingTierModel tier) {
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
              'Delete Tier',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this pricing tier? (Distance: ${tier.fromDistance} - ${tier.toDistance ?? 'Max'} km)',
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
              final provider = context.read<PricingProvider>();
              final success = await provider.deletePricingTier(tier.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pricing tier deleted successfully!'),
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
    final vehicleTypes = Provider.of<AdminVehiclesProvider>(context).vehicleTypes;
    final provider = Provider.of<PricingProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedVehicleTypeId != null) {
          await provider.fetchPricingTiers(_selectedVehicleTypeId!);
        }
      },
      color: const Color(0xFFE31C2E),
      child: Column(
        children: [
          // Dropdown Selector for Vehicle Category
          if (vehicleTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DropdownButtonFormField<int>(
                value: _selectedVehicleTypeId,
                decoration: const InputDecoration(
                  labelText: 'Select Vehicle Category',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                dropdownColor: Colors.white,
                items: vehicleTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedVehicleTypeId = val;
                    });
                    provider.fetchPricingTiers(val);
                  }
                },
              ),
            ),
          // Top Action Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance-Based Pricing Tiers',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121214)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  onPressed: _selectedVehicleTypeId == null ? null : () => _showFormDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Tier', style: GoogleFonts.outfit(fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                    ),
                  )
                : provider.errorMessage != null && provider.tiers.isEmpty
                    ? Center(
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
                                onPressed: () {
                                  if (_selectedVehicleTypeId != null) {
                                    provider.fetchPricingTiers(_selectedVehicleTypeId!);
                                  }
                                },
                                child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : provider.tiers.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, size: 48, color: Color(0xFFB0B8C4)),
                                    SizedBox(height: 12),
                                    Text(
                                      'No pricing tiers found',
                                      style: GoogleFonts.outfit(color: Color(0xFF6C6F79)),
                                    )
                                  ],
                                ),
                              )
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.tiers.length,
                            itemBuilder: (context, index) {
                              final tier = provider.tiers[index];
                              return Card(
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tier.vehicleTypeName ?? 'Vehicle Type ID: ${tier.vehicleTypeId}',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121214)),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                                onPressed: () => _showFormDialog(tier: tier),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                onPressed: () => _confirmDelete(tier),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildInfoCol('Distance', '${tier.fromDistance} - ${tier.toDistance ?? 'Max'} km'),
                                          _buildInfoCol('Base Fare', '₹${tier.baseFare}'),
                                          _buildInfoCol('Per Km', '₹${tier.perKmRate}'),
                                          _buildInfoCol('Commission', '${tier.commission}%'),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Color(0xFF6C6F79))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121214))),
      ],
    );
  }
}

class _PricingRulesTab extends StatefulWidget {
  const _PricingRulesTab();

  @override
  State<_PricingRulesTab> createState() => _PricingRulesTabState();
}

class _PricingRulesTabState extends State<_PricingRulesTab> {
  final _formKey = GlobalKey<FormState>();
  final _rainController = TextEditingController();
  final _nightController = TextEditingController();
  final _trafficController = TextEditingController();
  final _fuelController = TextEditingController();
  final _waitingController = TextEditingController();
  bool _dynamicPricingEnabled = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PricingProvider>().fetchPricingRule().then((_) {
        _populateFields();
      });
    });
  }

  void _populateFields() {
    final rule = context.read<PricingProvider>().rule;
    if (rule != null) {
      _rainController.text = rule.rainMultiplier.toString();
      _nightController.text = rule.nightMultiplier.toString();
      _trafficController.text = rule.heavyTrafficMultiplier.toString();
      _fuelController.text = rule.fuelMultiplier.toString();
      _waitingController.text = rule.waitingChargePerMinute.toString();
      setState(() {
        _dynamicPricingEnabled = rule.dynamicPricingEnabled;
      });
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _nightController.dispose();
    _trafficController.dispose();
    _fuelController.dispose();
    _waitingController.dispose();
    super.dispose();
  }

  void _saveRules() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PricingProvider>();
    final success = await provider.updatePricingRule(
      rainMultiplier: double.parse(_rainController.text.trim()),
      nightMultiplier: double.parse(_nightController.text.trim()),
      heavyTrafficMultiplier: double.parse(_trafficController.text.trim()),
      fuelMultiplier: double.parse(_fuelController.text.trim()),
      waitingChargePerMinute: double.parse(_waitingController.text.trim()),
      dynamicPricingEnabled: _dynamicPricingEnabled,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing rules updated successfully!'), backgroundColor: Color(0xFF1C9A5B)),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PricingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rule == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE31C2E)));
        }

        final rule = provider.rule;
        if (rule == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No Pricing Rules found', style: GoogleFonts.outfit(color: Color(0xFF6C6F79))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.fetchPricingRule(),
                  child: Text('Fetch Rules'),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPricingRule(),
          color: const Color(0xFFE31C2E),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFE7E7EB)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pricing Multipliers',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF121214)),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Color(0xFFE31C2E)),
                                  onPressed: () {
                                    _populateFields();
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                )
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE7E7EB)),
                          _buildMultiplierField(
                            controller: _rainController,
                            label: 'Rain Multiplier',
                            hint: 'e.g. 1.25',
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 12),
                          _buildMultiplierField(
                            controller: _nightController,
                            label: 'Night Multiplier',
                            hint: 'e.g. 1.35',
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 12),
                          _buildMultiplierField(
                            controller: _trafficController,
                            label: 'Heavy Traffic Multiplier',
                            hint: 'e.g. 1.20',
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 12),
                          _buildMultiplierField(
                            controller: _fuelController,
                            label: 'Fuel Surge Multiplier',
                            hint: 'e.g. 1.15',
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 12),
                          _buildMultiplierField(
                            controller: _waitingController,
                            label: 'Waiting Charge Per Minute (₹)',
                            hint: 'e.g. 3.00',
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Dynamic Pricing Enabled', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF121214))),
                            activeColor: const Color(0xFFE31C2E),
                            value: _dynamicPricingEnabled,
                            onChanged: _isEditing
                                ? (val) {
                                    setState(() {
                                      _dynamicPricingEnabled = val;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE7E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            child: Text('Cancel', style: GoogleFonts.outfit(color: Color(0xFF6C6F79))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31C2E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _saveRules,
                            child: Text('Save Changes'),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiplierField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Color(0xFF6C6F79), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

class PricingTierFormDialog extends StatefulWidget {
  final PricingTierModel? tier;
  final int? defaultVehicleTypeId;

  const PricingTierFormDialog({super.key, this.tier, this.defaultVehicleTypeId});

  @override
  State<PricingTierFormDialog> createState() => _PricingTierFormDialogState();
}

class _PricingTierFormDialogState extends State<PricingTierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fromDistanceController = TextEditingController();
  final _toDistanceController = TextEditingController();
  final _baseFareController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _commissionController = TextEditingController();
  int? _selectedVehicleTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      final t = widget.tier!;
      _selectedVehicleTypeId = t.vehicleTypeId;
      _fromDistanceController.text = t.fromDistance.toString();
      _toDistanceController.text = t.toDistance?.toString() ?? '';
      _baseFareController.text = t.baseFare.toString();
      _perKmRateController.text = t.perKmRate.toString();
      _commissionController.text = t.commission.toString();
    } else {
      _selectedVehicleTypeId = widget.defaultVehicleTypeId;
    }
  }

  @override
  void dispose() {
    _fromDistanceController.dispose();
    _toDistanceController.dispose();
    _baseFareController.dispose();
    _perKmRateController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehicleTypeId == null) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<PricingProvider>();
    final double fromDist = double.parse(_fromDistanceController.text.trim());
    final double? toDist = _toDistanceController.text.trim().isNotEmpty
        ? double.parse(_toDistanceController.text.trim())
        : null;
    final double baseFare = double.parse(_baseFareController.text.trim());
    final double perKm = double.parse(_perKmRateController.text.trim());
    final double comm = double.parse(_commissionController.text.trim());

    final success = widget.tier == null
        ? await provider.createPricingTier(
            vehicleTypeId: _selectedVehicleTypeId!,
            fromDistance: fromDist,
            toDistance: toDist,
            baseFare: baseFare,
            perKmRate: perKm,
            commission: comm,
          )
        : await provider.updatePricingTier(
            tierId: widget.tier!.id,
            vehicleTypeId: _selectedVehicleTypeId!,
            fromDistance: fromDist,
            toDistance: toDist,
            baseFare: baseFare,
            perKmRate: perKm,
            commission: comm,
          );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.tier == null
                ? 'Pricing tier created successfully!'
                : 'Pricing tier updated successfully!'),
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

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.tier == null ? 'Add Pricing Tier' : 'Edit Pricing Tier',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF121214)),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedVehicleTypeId,
                decoration: const InputDecoration(labelText: 'Select Vehicle Category'),
                dropdownColor: Colors.white,
                items: vehicleTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedVehicleTypeId = val;
                  });
                },
                validator: (val) => val == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromDistanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'From Distance (km)'),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _toDistanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'To Distance (Optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseFareController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Base Fare (₹)'),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _perKmRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Per Km Rate (₹)'),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commissionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Commission Percentage (%)'),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit(color: Color(0xFF6C6F79))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31C2E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Text('Save'),
        ),
      ],
    );
  }
}