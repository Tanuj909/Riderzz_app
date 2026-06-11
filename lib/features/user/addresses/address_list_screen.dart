import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
    });
  }

  void _deleteAddress(int id) async {
    final success = await Provider.of<AddressProvider>(context, listen: false).deleteAddress(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted successfully')),
      );
    } else if (mounted) {
      final error = Provider.of<AddressProvider>(context, listen: false).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to delete address')),
      );
    }
  }

  void _saveAddress({
    int? id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final provider = Provider.of<AddressProvider>(context, listen: false);
    bool success;
    if (id != null) {
      success = await provider.updateAddress(
        id: id,
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      success = await provider.addAddress(
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? 'Address updated successfully' : 'Address added successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save address')),
      );
    }
  }

  void _showAddressBottomSheet(BuildContext context, {Map<String, dynamic>? addressToEdit}) {
    final labelController = TextEditingController(text: addressToEdit?['label'] ?? '');
    final addressController = TextEditingController(text: addressToEdit?['address'] ?? '');
    final locationController = TextEditingController(text: addressToEdit?['address'] ?? '');
    double? latitude = addressToEdit != null ? (addressToEdit['lat'] is num ? (addressToEdit['lat'] as num).toDouble() : null) : null;
    double? longitude = addressToEdit != null ? (addressToEdit['lng'] is num ? (addressToEdit['lng'] as num).toDouble() : null) : null;

    String selectedType = 'other';
    if (addressToEdit != null) {
      final lbl = (addressToEdit['label'] ?? '').toString().toLowerCase();
      if (lbl == 'home') {
        selectedType = 'home';
      } else if (lbl == 'office') {
        selectedType = 'office';
      }
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
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          addressToEdit != null ? 'Edit Address' : 'Add New Address',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Top Field: Enter / Choose Location (Map trigger)
                    const Text(
                      'Choose Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              initialLatitude: latitude,
                              initialLongitude: longitude,
                              showSaveOption: false,
                            ),
                          ),
                        );
                        if (result != null) {
                          setModalState(() {
                            latitude = result['latitude'];
                            longitude = result['longitude'];
                            final addr = result['address'] ?? '';
                            locationController.text = addr;
                            // Pre-fill Full Address if it's currently empty
                            if (addressController.text.isEmpty) {
                              addressController.text = addr;
                            }
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 18, color: Color(0xFF1A3D6B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locationController.text.isNotEmpty
                                    ? locationController.text
                                    : 'Tap to choose from Map',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: locationController.text.isNotEmpty
                                      ? const Color(0xFF1A2233)
                                      : const Color(0xFFB0B8C4),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7785)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Second Field: Full Address (Manual Text Entry)
                    const Text(
                      'Full Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
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
                        controller: addressController,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233)),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter full location details manually',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Third Field: Address Type / Preset Chips
                    const Text(
                      'Address Type / Preset',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTypeChip(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          isSelected: selectedType == 'home',
                          onTap: () {
                            setModalState(() {
                              selectedType = 'home';
                              labelController.text = 'Home';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          label: 'Office',
                          icon: Icons.business_rounded,
                          isSelected: selectedType == 'office',
                          onTap: () {
                            setModalState(() {
                              selectedType = 'office';
                              labelController.text = 'Office';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          label: 'Other',
                          icon: Icons.location_on_rounded,
                          isSelected: selectedType == 'other',
                          onTap: () {
                            setModalState(() {
                              selectedType = 'other';
                              if (labelController.text == 'Home' || labelController.text == 'Office') {
                                labelController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Label Field
                    const Text(
                      'Address Label',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
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
                        controller: labelController,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233)),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Friend\'s House, Gym, Factory',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          final lower = val.trim().toLowerCase();
                          if (lower == 'home') {
                            if (selectedType != 'home') setModalState(() => selectedType = 'home');
                          } else if (lower == 'office') {
                            if (selectedType != 'office') setModalState(() => selectedType = 'office');
                          } else {
                            if (selectedType != 'other') setModalState(() => selectedType = 'other');
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final label = labelController.text.trim();
                          final address = addressController.text.trim();
                          if (label.isEmpty || address.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out all fields')),
                            );
                            return;
                          }
                          if (latitude == null || longitude == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coordinates are required. Please select a location using Choose From Map.')),
                            );
                            return;
                          }
                          _saveAddress(
                            id: addressToEdit?['id'],
                            label: label,
                            address: address,
                            latitude: latitude!,
                            longitude: longitude!,
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          addressToEdit != null ? 'Update Address' : 'Save Address',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F0FB) : const Color(0xFFF7F8FA),
            border: Border.all(
              color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final addresses = addressProvider.addresses;
    final isLoading = addressProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D6B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: isLoading && addresses.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
              ),
            )
          : addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        size: 80,
                        color: Color(0xFFB0B8C4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Saved Addresses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2233),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Save your locations for instant booking.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7785),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showAddressBottomSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Address'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final item = addresses[index];
                    final label = item['label'] ?? '';
                    final address = item['address'] ?? '';

                    IconData leadIcon = Icons.location_on_rounded;
                    Color leadBg = const Color(0xFFFFF3E8);
                    Color leadIconColor = const Color(0xFFF97316);

                    final lowerLabel = label.toLowerCase();
                    if (lowerLabel == 'home') {
                      leadIcon = Icons.home_rounded;
                      leadBg = const Color(0xFFE6F7F2);
                      leadIconColor = const Color(0xFF0F9B6E);
                    } else if (lowerLabel == 'office') {
                      leadIcon = Icons.business_rounded;
                      leadBg = const Color(0xFFE8F0FB);
                      leadIconColor = const Color(0xFF1A3D6B);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9ECF0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: leadBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(leadIcon, color: leadIconColor, size: 20),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7785),
                              height: 1.4,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showAddressBottomSheet(context, addressToEdit: item),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF1A3D6B),
                                size: 20,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteAddress(item['id']),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddressBottomSheet(context),
              backgroundColor: const Color(0xFF1A3D6B),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}
