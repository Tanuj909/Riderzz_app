import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/models/google_place.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class AddressListScreen extends StatefulWidget {
  final bool showBackButton;
  const AddressListScreen({super.key, this.showBackButton = true});

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
    final postalCodeController = TextEditingController(text: addressToEdit?['postalCode'] ?? '');
    final locationController = TextEditingController(text: addressToEdit?['address'] ?? '');
    final contactPersonNameController = TextEditingController(text: addressToEdit?['contactPersonName'] ?? '');
    final contactPersonPhoneController = TextEditingController(text: addressToEdit?['contactPersonPhone'] ?? '');

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
                : (MediaQuery.of(context).size.height * 0.85);

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
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Color(0xFFF1F1F4), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Color(0xFF121214), size: 18),
                              ),
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

                              final googlePlace = result['googlePlace'] as GooglePlace?;

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
                                    postalCodeController.text = pm.postalCode ?? '';
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

                              if (googlePlace != null) {
                                setModalState(() {
                                  if (googlePlace.street != null && googlePlace.street!.isNotEmpty) {
                                    addressLine1Controller.text = googlePlace.street!;
                                  }
                                  if (googlePlace.city != null && googlePlace.city!.isNotEmpty) {
                                    cityController.text = googlePlace.city!;
                                  }
                                  if (googlePlace.state != null && googlePlace.state!.isNotEmpty) {
                                    stateController.text = googlePlace.state!;
                                  }
                                  if (googlePlace.country != null && googlePlace.country!.isNotEmpty) {
                                    countryController.text = googlePlace.country!;
                                  }
                                  if (googlePlace.postalCode != null && googlePlace.postalCode!.isNotEmpty) {
                                    postalCodeController.text = googlePlace.postalCode!;
                                  }
                                });
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE7E7EB)),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFFE31C2E)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locationController.text.isNotEmpty
                                        ? locationController.text
                                        : 'Choose Location from Map',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: locationController.text.isNotEmpty
                                          ? const Color(0xFF121214)
                                          : const Color(0xFF6C6F79),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF6C6F79), size: 18),
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
                        const SizedBox(height: 8),

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
                        const SizedBox(height: 8),

                        // Landmark (Moved here)
                        _buildInputField(
                          label: 'Landmark (Optional)',
                          hint: 'Opposite, Near by reference point',
                          controller: landmarkController,
                          prefixIcon: Icons.flag_outlined,
                        ),
                        const SizedBox(height: 8),

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
                        const SizedBox(height: 8),

                        // Contact Person details placed outside dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final FlutterNativeContactPicker picker = FlutterNativeContactPicker();
                                  final contact = await picker.selectPhoneNumber();
                                  if (contact != null) {
                                    if (contact.fullName != null && contact.fullName!.isNotEmpty) {
                                      contactPersonNameController.text = contact.fullName!;
                                    }
                                    if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                      String? rawNumber = contact.selectedPhoneNumber;
                                      if (rawNumber != null) {
                                        String sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                        contactPersonPhoneController.text = sanitized;
                                      }
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error picking contact: $e');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4, right: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.contacts_rounded, color: Color(0xFFE31C2E), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Choose from contacts',
                                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFE31C2E), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildInputField(
                          label: 'Contact Person Name (Optional)',
                          hint: 'Name of the contact person',
                          controller: contactPersonNameController,
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          label: 'Contact Person Phone (Optional)',
                          hint: '10-digit mobile number',
                          controller: contactPersonPhoneController,
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.contacts_rounded, color: Color(0xFFE31C2E)),
                            onPressed: () async {
                              try {
                                final FlutterNativeContactPicker picker = FlutterNativeContactPicker();
                                final contact = await picker.selectPhoneNumber();
                                if (contact != null) {
                                  if (contact.fullName != null && contact.fullName!.isNotEmpty) {
                                    contactPersonNameController.text = contact.fullName!;
                                  }
                                  if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                    String? rawNumber = contact.selectedPhoneNumber;
                                    if (rawNumber != null) {
                                      String sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                      contactPersonPhoneController.text = sanitized;
                                    }
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error picking contact: $e');
                              }
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return null;
                            }
                            final regExp = RegExp(r'^(?:\+91|91)?[6-9]\d{9}$');
                            if (!regExp.hasMatch(val.trim())) {
                              return 'Enter a valid 10-digit Indian phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

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
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF121214),
                                  ),
                                ),
                                Icon(
                                  showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFFE31C2E),
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
                          const SizedBox(height: 8),
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
                            Text(
                              'Set as Default Address',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            Switch(
                              value: isDefault,
                              activeColor: const Color(0xFFE31C2E),
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
                              backgroundColor: const Color(0xFFE31C2E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
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
                                'contactPersonName': contactPersonNameController.text.trim(),
                                'contactPersonPhone': contactPersonPhoneController.text.trim(),
                              };

                              _saveAddress(
                                id: addressToEdit?['id'],
                                data: mapData,
                              );
                              Navigator.pop(context);
                            },
                            child: Text(
                              addressToEdit != null ? 'Update Address' : 'Save Address',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF121214),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF6C6F79)),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE31C2E) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF6C6F79),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6C6F79),
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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
              )
            : null,
        title: Text(
          'Saved Addresses',
          style: GoogleFonts.poppins(
            color: const Color(0xFF121214),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddressBottomSheet(context),
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
      body: isLoading && addresses.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
              ),
            )
          : addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_off_rounded,
                          size: 64,
                          color: Color(0xFFD0D5DD),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Saved Addresses',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121214),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your locations for instant booking.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6C6F79),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121214),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showAddressBottomSheet(context),
                        icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                        label: Text(
                          'Add New Address',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
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
                    Color leadBg = const Color(0xFFF1F1F4);
                    Color leadIconColor = const Color(0xFF121214);

                    final lowerLabel = label.toLowerCase();
                    if (lowerLabel == 'home') {
                      leadIcon = Icons.home_rounded;
                      leadBg = const Color(0xFFE7F7EF);
                      leadIconColor = const Color(0xFF1C9A5B);
                    } else if (lowerLabel == 'office') {
                      leadIcon = Icons.business_rounded;
                      leadBg = const Color(0xFFFDEBEC);
                      leadIconColor = const Color(0xFFE31C2E);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F1F4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: leadBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(leadIcon, color: leadIconColor, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF121214),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        address,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF6C6F79),
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showAddressBottomSheet(context, addressToEdit: item),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF121214),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () => _deleteAddress(item['id']),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE31C2E),
                                    ),
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
