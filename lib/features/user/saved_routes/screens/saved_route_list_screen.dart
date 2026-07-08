import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';

class SavedRouteListScreen extends StatefulWidget {
  const SavedRouteListScreen({super.key});

  @override
  State<SavedRouteListScreen> createState() => _SavedRouteListScreenState();
}

class _SavedRouteListScreenState extends State<SavedRouteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedRouteProvider>().fetchSavedRoutes();
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  void _deleteRoute(int id) async {
    final provider = context.read<SavedRouteProvider>();
    final success = await provider.deleteSavedRoute(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved route deleted successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete saved route')),
      );
    }
  }

  void _saveRoute({
    int? id,
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    final provider = context.read<SavedRouteProvider>();
    bool success;
    if (id != null) {
      success = await provider.updateSavedRoute(
        id: id,
        routeName: routeName,
        pickupAddressId: pickupAddressId,
        dropAddressId: dropAddressId,
      );
    } else {
      success = await provider.createSavedRoute(
        routeName: routeName,
        pickupAddressId: pickupAddressId,
        dropAddressId: dropAddressId,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? 'Route updated successfully' : 'Route saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save route')),
      );
    }
  }

  void _showRouteBottomSheet(BuildContext context, {Map<String, dynamic>? routeToEdit}) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: routeToEdit?['routeName'] ?? '');

    final addressProvider = context.read<AddressProvider>();
    final addresses = addressProvider.addresses;

    if (addresses.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('You need to add at least one saved address before creating saved routes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C6F79))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31C2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddressListScreen()),
                );
              },
              child: const Text('Add Address', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    int? selectedPickupId = routeToEdit != null ? (routeToEdit['pickupAddress']['id'] as num).toInt() : null;
    int? selectedDropId = routeToEdit != null ? (routeToEdit['dropAddress']['id'] as num).toInt() : null;

    // Validate that the ID actually exists in address list
    if (selectedPickupId != null && !addresses.any((e) => e['id'] == selectedPickupId)) {
      selectedPickupId = null;
    }
    if (selectedDropId != null && !addresses.any((e) => e['id'] == selectedDropId)) {
      selectedDropId = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final double maxHeight = keyboardHeight > 0
                ? (MediaQuery.of(context).size.height - keyboardHeight - 50)
                : (MediaQuery.of(context).size.height * 0.50);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                keyboardHeight + 24,
              ),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              routeToEdit != null ? 'Edit Route' : 'Add New Route',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Route Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Name',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF121214),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: nameController,
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.edit_road_rounded, size: 18, color: Color(0xFF6C6F79)),
                                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                hintText: 'e.g. Home to Warehouse, Gym to Office',
                                hintStyle: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF121214)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Route Name is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pickup Address Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup Address',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF121214),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: selectedPickupId,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6C6F79)),
                              borderRadius: BorderRadius.circular(24),
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.circle_outlined, size: 16, color: Color(0xFF1C9A5B)),
                                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF121214)),
                                ),
                              ),
                              hint: Text('Select Pickup Location', style: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13)),
                              items: addresses.map((addr) {
                                final id = (addr['id'] as num).toInt();
                                final label = addr['label'] ?? '';
                                final details = addr['address'] ?? '';
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(
                                    '$label ($details)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF121214),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedPickupId = val;
                                });
                              },
                              validator: (val) {
                                if (val == null) return 'Pickup Location is required';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Drop Address Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Drop Address',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF121214),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: selectedDropId,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6C6F79)),
                              borderRadius: BorderRadius.circular(24),
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFB9700A)),
                                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF121214)),
                                ),
                              ),
                              hint: Text('Select Drop Location', style: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13)),
                              items: addresses.map((addr) {
                                final id = (addr['id'] as num).toInt();
                                final label = addr['label'] ?? '';
                                final details = addr['address'] ?? '';
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(
                                    '$label ($details)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF121214),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedDropId = val;
                                });
                              },
                              validator: (val) {
                                if (val == null) return 'Drop Location is required';
                                if (val == selectedPickupId) return 'Pickup & Drop cannot be identical';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31C2E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;

                              _saveRoute(
                                id: routeToEdit?['id'],
                                routeName: nameController.text.trim(),
                                pickupAddressId: selectedPickupId!,
                                dropAddressId: selectedDropId!,
                              );
                              Navigator.pop(context);
                            },
                            child: Text(
                              routeToEdit != null ? 'Update Route' : 'Save Route',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<SavedRouteProvider>(context);
    final routes = routeProvider.savedRoutes;
    final isLoading = routeProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
        ),
        title: Text(
          'Saved Routes',
          style: GoogleFonts.poppins(
            color: const Color(0xFF121214),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (routes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showRouteBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Add', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: isLoading && routes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
              ),
            )
          : routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_outlined,
                        size: 80,
                        color: Color(0xFFB0B8C4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Saved Routes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121214),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Combine pickup and drop addresses into shortcuts.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6C6F79),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31C2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showRouteBottomSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Create Route'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final item = routes[index];
                    final name = item['routeName'] ?? '';
                    final pickup = item['pickupAddress']?['address'] ?? '';
                    final drop = item['dropAddress']?['address'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE7E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.directions_outlined, color: Color(0xFFE31C2E), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF121214),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showRouteBottomSheet(context, routeToEdit: item),
                                      child: Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF121214),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => _deleteRoute(item['id']),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFE31C2E),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE7E7EB)),
                            const SizedBox(height: 12),
                            
                            // Pickup Info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.circle_outlined, color: Color(0xFF1C9A5B), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    pickup,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Drop Info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, color: Color(0xFFB9700A), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    drop,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6C6F79)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
