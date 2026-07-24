import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Custom App Header matching Admin theme
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F4),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE1E1E6)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF121214),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMISSION & FARES',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFD90429),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pricing Configuration',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF121214),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Segmented Modern Tab Bar with generous rounded padding
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFD90429),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF6C6F79),
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Vehicle Pricing'),
                        Tab(text: 'Pricing Rules'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _VehiclePricingTab(),
                  const _PricingRulesTab(),
                ],
              ),
            ),
          ],
        ),
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
      context.read<AdminVehiclesProvider>().fetchVehicleTypes();
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
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD90429)),
            const SizedBox(width: 8),
            Text(
              'Delete Tier',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF121214)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this pricing tier? (Distance: ${tier.fromDistance} - ${tier.toDistance ?? 'Max'} km)',
          style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD90429),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
                      backgroundColor: const Color(0xFFD90429),
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
      color: const Color(0xFFD90429),
      child: Column(
        children: [
          // Fully rounded Category Dropdown Selector (List popup is also rounded)
          if (vehicleTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF121214).withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedVehicleTypeId,
                    hint: Text(
                      'Select Category',
                      style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(20),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF121214)),
                    style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 14, fontWeight: FontWeight.w700),
                    dropdownColor: Colors.white,
                    items: vehicleTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.id,
                        child: Text('Category: ${type.name}'),
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
              ),
            ),

          // Header Row under Category Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DISTANCE-BASED PRICING TIERS',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: const Color(0xFFA2A5AE),
                    letterSpacing: 1.1,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: _selectedVehicleTypeId == null ? null : () => _showFormDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Add Tier', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          Expanded(
            child: _selectedVehicleTypeId == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEDF0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 42,
                              color: Color(0xFFD90429),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select Category',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF121214),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please select a vehicle category from the dropdown above to view or configure pricing tiers.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF6C6F79),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
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
                                style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD90429),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                ),
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
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEDF0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.request_quote_outlined, size: 44, color: Color(0xFFD90429)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pricing tiers configured',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF121214),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap "+ Add Tier" above to define distance fares',
                                      style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                            itemCount: provider.tiers.length,
                            itemBuilder: (context, index) {
                              final tier = provider.tiers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE1E1E6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF121214).withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Category + Distance pill tag
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          tier.vehicleTypeName ?? 'Category ID: ${tier.vehicleTypeId}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: const Color(0xFF121214),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F1F4),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: const Color(0xFFE1E1E6)),
                                          ),
                                          child: Text(
                                            '${tier.fromDistance} - ${tier.toDistance ?? 'Max'} km',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF121214),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Details Metrics (Commission as Currency Amount ₹!)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoCol('Base Fare', '₹${tier.baseFare.toStringAsFixed(0)}'),
                                        _buildInfoCol('Rate/Km', '₹${tier.perKmRate.toStringAsFixed(0)}'),
                                        _buildInfoCol('Commission', '₹${tier.commission.toStringAsFixed(0)}'),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Compact Action Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _showFormDialog(tier: tier),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              side: const BorderSide(color: Color(0xFFE1E1E6), width: 1.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                            ),
                                            child: Text(
                                              'Edit Pricing',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF121214),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _confirmDelete(tier),
                                          borderRadius: BorderRadius.circular(999),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDEBEC),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: const Color(0xFFE31C2E).withValues(alpha: 0.2)),
                                            ),
                                            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE31C2E), size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
        Text(label, style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF121214))),
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
      setState(() {
        _dynamicPricingEnabled = rule.dynamicPricingEnabled;
      });
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _nightController.dispose();
    super.dispose();
  }

  void _saveRules() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PricingProvider>();
    final success = await provider.updatePricingRule(
      rainMultiplier: double.parse(_rainController.text.trim()),
      nightMultiplier: double.parse(_nightController.text.trim()),
      heavyTrafficMultiplier: provider.rule?.heavyTrafficMultiplier ?? 1.0,
      fuelMultiplier: provider.rule?.fuelMultiplier ?? 1.0,
      waitingChargePerMinute: provider.rule?.waitingChargePerMinute ?? 0.0,
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
          SnackBar(content: Text(provider.errorMessage!), backgroundColor: const Color(0xFFD90429)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PricingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rule == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD90429)));
        }

        final rule = provider.rule;
        if (rule == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No Pricing Rules found', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79))),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () => provider.fetchPricingRule(),
                  child: Text('Fetch Rules', style: GoogleFonts.outfit(color: Colors.white)),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPricingRule(),
          color: const Color(0xFFD90429),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 32.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E1E6)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF121214).withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PRICING MULTIPLIERS',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: const Color(0xFFA2A5AE),
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (!_isEditing)
                              InkWell(
                                onTap: () {
                                  _populateFields();
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDF0),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFD90429).withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Color(0xFFD90429), size: 16),
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildMultiplierField(
                          controller: _rainController,
                          label: 'Rain Multiplier',
                          hint: 'e.g. 1.25',
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 10),
                        _buildMultiplierField(
                          controller: _nightController,
                          label: 'Night Multiplier',
                          hint: 'e.g. 1.35',
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dynamic Pricing Enabled', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF121214))),
                          subtitle: Text('Adjust fares automatically based on surge factors', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6C6F79))),
                          activeColor: const Color(0xFFD90429),
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
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE1E1E6), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD90429),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _saveRules,
                            child: Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
        Text(label, style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F1F4) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E1E6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFA2A5AE)),
              border: InputBorder.none,
              isDense: true,
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
          ),
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
            backgroundColor: const Color(0xFFD90429),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.tier == null ? 'Add Pricing Tier' : 'Edit Pricing Tier',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF121214)),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputLabel('Vehicle Category'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedVehicleTypeId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(20),
                    dropdownColor: Colors.white,
                    items: vehicleTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.id,
                        child: Text(type.name, style: GoogleFonts.outfit(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedVehicleTypeId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(_fromDistanceController, 'From Dist (km)', 'e.g. 0'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFormField(_toDistanceController, 'To Dist (Opt)', 'e.g. 5', isOptional: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(_baseFareController, 'Base Fare (₹)', 'e.g. 40'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFormField(_perKmRateController, 'Per Km (₹)', 'e.g. 12'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFormField(_commissionController, 'Commission Amount (₹)', 'e.g. 15'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD90429),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Text('Save Pricing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, String hint, {bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E1E6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFA2A5AE)),
              border: InputBorder.none,
              isDense: true,
            ),
            validator: (val) {
              if (isOptional) return null;
              return (val == null || val.trim().isEmpty) ? 'Required' : null;
            },
          ),
        ),
      ],
    );
  }
}