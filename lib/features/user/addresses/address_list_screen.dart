import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
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
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  void _deleteAddress(int id) async {
    final provider = context.read<AddressProvider>();
    final success = await provider.deleteAddress(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete address')),
      );
    }
  }

  void _saveAddress({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final provider = context.read<AddressProvider>();
    bool success;
    if (id != null) {
      success = await provider.updateAddress(
        id: id,
        data: data,
      );
    } else {
      success = await provider.addAddress(data);
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
    final _formKey = GlobalKey<FormState>();

    final labelController = TextEditingController(text: addressToEdit?['label'] ?? '');
    final addressLine1Controller = TextEditingController(text: addressToEdit?['addressLine1'] ?? addressToEdit?['address'] ?? '');
    final addressLine2Controller = TextEditingController(text: addressToEdit?['addressLine2'] ?? '');
    final landmarkController = TextEditingController(text: addressToEdit?['landmark'] ?? '');
    final cityController = TextEditingController(text: addressToEdit?['city'] ?? 'Mumbai');
    final stateController = TextEditingController(text: addressToEdit?['state'] ?? 'Maharashtra');
    final countryController = TextEditingController(text: 'India');
    final postalCodeController = TextEditingController(text: addressToEdit?['postalCode'] ?? '400001');
    final locationController = TextEditingController(text: addressToEdit?['address'] ?? '');

    double? latitude = addressToEdit != null ? (addressToEdit['lat'] is num ? (addressToEdit['lat'] as num).toDouble() : null) : null;
    double? longitude = addressToEdit != null ? (addressToEdit['lng'] is num ? (addressToEdit['lng'] as num).toDouble() : null) : null;

    String selectedType = 'HOME';
    if (addressToEdit != null) {
      selectedType = (addressToEdit['addressType'] ?? 'HOME').toString().toUpperCase();
    }
    bool isDefault = addressToEdit?['defaultAddress'] ?? false;
    bool showAdvanced = false;

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
                : (MediaQuery.of(context).size.height * 0.60);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                keyboardHeight + 24,
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bottom Sheet header
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
                        const SizedBox(height: 16),

                        // Choose Location Trigger Card
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
                              });

                              try {
                                final placemarks = await placemarkFromCoordinates(latitude!, longitude!);
                                if (placemarks.isNotEmpty) {
                                  final pm = placemarks.first;
                                  setModalState(() {
                                    final street = pm.street ?? '';
                                    final subLocality = pm.subLocality ?? '';
                                    addressLine1Controller.text = street.isNotEmpty ? street : (result['address'] ?? '');
                                    addressLine2Controller.text = subLocality;
                                    landmarkController.text = pm.thoroughfare ?? '';
                                    cityController.text = pm.locality ?? 'Mumbai';
                                    stateController.text = pm.administrativeArea ?? 'Maharashtra';
                                    postalCodeController.text = pm.postalCode ?? '400001';
                                  });
                                }
                              } catch (_) {
                                final parts = (result['address'] ?? '').toString().split(',');
                                if (parts.isNotEmpty) {
                                  setModalState(() {
                                    addressLine1Controller.text = parts[0].trim();
                                    if (parts.length > 1) {
                                      addressLine2Controller.text = parts[1].trim();
                                    }
                                    if (parts.length > 2) {
                                      cityController.text = parts[parts.length - 2].trim();
                                    }
                                  });
                                }
                              }
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
                                const Icon(Icons.map_outlined, size: 20, color: Color(0xFF1A3D6B)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    locationController.text.isNotEmpty
                                        ? locationController.text
                                        : 'Choose Location from Map',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: locationController.text.isNotEmpty
                                          ? const Color(0xFF1A2233)
                                          : const Color(0xFF6B7785),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7785), size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Preset chips row
                        Row(
                          children: [
                            _buildTypeChip(
                              label: 'Home',
                              icon: Icons.home_rounded,
                              isSelected: selectedType == 'HOME',
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'HOME';
                                  labelController.text = 'Home';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              label: 'Office',
                              icon: Icons.business_rounded,
                              isSelected: selectedType == 'OFFICE',
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'OFFICE';
                                  labelController.text = 'Office';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              label: 'Other',
                              icon: Icons.location_on_rounded,
                              isSelected: selectedType == 'OTHER',
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'OTHER';
                                  if (labelController.text == 'Home' || labelController.text == 'Office') {
                                    labelController.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Label Input
                        _buildInputField(
                          label: 'Address Label',
                          hint: 'e.g. Friend\'s House, Factory',
                          controller: labelController,
                          prefixIcon: Icons.bookmark_border_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Label is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Address Line 1
                        _buildInputField(
                          label: 'Address Line 1',
                          hint: 'Flat/House No., Building, Street',
                          controller: addressLine1Controller,
                          prefixIcon: Icons.location_on_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Address Line 1 is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // City & Postal Code Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'City',
                                hint: 'City name',
                                controller: cityController,
                                prefixIcon: Icons.location_city_outlined,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                label: 'Postal Code',
                                hint: 'Pin code',
                                controller: postalCodeController,
                                prefixIcon: Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Accordion Toggle for Optional Details
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              showAdvanced = !showAdvanced;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  showAdvanced ? 'Hide Optional Details' : 'Show Optional Details',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3D6B),
                                  ),
                                ),
                                Icon(
                                  showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF1A3D6B),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Optional Advanced Fields (Collapsed/Expanded)
                        if (showAdvanced) ...[
                          const SizedBox(height: 8),
                          _buildInputField(
                            label: 'Address Line 2 (Optional)',
                            hint: 'Locality, Sector, Area',
                            controller: addressLine2Controller,
                            prefixIcon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            label: 'Landmark (Optional)',
                            hint: 'Opposite, Near by reference point',
                            controller: landmarkController,
                            prefixIcon: Icons.flag_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            label: 'State',
                            hint: 'State name',
                            controller: stateController,
                            prefixIcon: Icons.map_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Set Default Address Switch Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Set as Default Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2233),
                              ),
                            ),
                            Switch(
                              value: isDefault,
                              activeColor: const Color(0xFF1A3D6B),
                              onChanged: (val) {
                                setModalState(() {
                                  isDefault = val;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Save Button Card
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3D6B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;

                              if (latitude == null || longitude == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coordinates are required. Please choose from Map.')),
                                );
                                return;
                              }

                              final mapData = {
                                'addressType': selectedType,
                                'label': labelController.text.trim(),
                                'addressLine1': addressLine1Controller.text.trim(),
                                'addressLine2': addressLine2Controller.text.trim(),
                                'landmark': landmarkController.text.trim(),
                                'city': cityController.text.trim(),
                                'state': stateController.text.trim(),
                                'country': countryController.text.trim(),
                                'postalCode': postalCodeController.text.trim(),
                                'latitude': latitude!,
                                'longitude': longitude!,
                                'defaultAddress': isDefault,
                              };

                              _saveAddress(
                                id: addressToEdit?['id'],
                                data: mapData,
                              );
                              Navigator.pop(context);
                            },
                            child: Text(
                              addressToEdit != null ? 'Update Address' : 'Save Address',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7785),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border.all(color: const Color(0xFFE9ECF0)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233), fontWeight: FontWeight.w500),
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF6B7785)),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
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
