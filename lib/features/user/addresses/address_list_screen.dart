import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/models/google_place.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';

class AddressListScreen extends StatefulWidget {
  final bool showBackButton;
  final int initialTabIndex;
  const AddressListScreen({
    super.key,
    this.showBackButton = true,
    this.initialTabIndex = 0,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late int _selectedTab;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
    _pageController = PageController(initialPage: _selectedTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().fetchAddresses();
      context.read<SavedRouteProvider>().fetchSavedRoutes();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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
    final formKey = GlobalKey<FormState>();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

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
    bool locationHasError = false;
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
    String? formErrorBanner;
    Timer? errorBannerTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalSheetContext) {
        return ScaffoldMessenger(
          key: messengerKey,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
              final double maxHeight = keyboardHeight > 0
                  ? (MediaQuery.of(context).size.height - keyboardHeight - 50)
                  : (MediaQuery.of(context).size.height * 0.85);

              void showModalAlert(String message) {
                setModalState(() {
                  formErrorBanner = message;
                  autovalidateMode = AutovalidateMode.onUserInteraction;
                  if (latitude == null || longitude == null || locationController.text.trim().isEmpty) {
                    locationHasError = true;
                  }
                });

                messengerKey.currentState?.hideCurrentSnackBar();
                messengerKey.currentState?.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1E1E24),
                    duration: const Duration(seconds: 4),
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31C2E).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFE31C2E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                errorBannerTimer?.cancel();
                errorBannerTimer = Timer(const Duration(seconds: 4), () {
                  if (context.mounted) {
                    setModalState(() {
                      formErrorBanner = null;
                    });
                  }
                });
              }

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
                    key: formKey,
                    autovalidateMode: autovalidateMode,
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
                                onPressed: () {
                                  errorBannerTimer?.cancel();
                                  Navigator.pop(context);
                                },
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
                          const SizedBox(height: 12),

                          // Dynamic Error Alert Banner (if any)
                          if (formErrorBanner != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                border: Border.all(color: const Color(0xFFE31C2E).withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE31C2E), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      formErrorBanner!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFE31C2E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Choose Location Trigger Card
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      locationHasError = false;
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
                                    border: Border.all(
                                      color: locationHasError
                                          ? const Color(0xFFE31C2E)
                                          : const Color(0xFFE7E7EB),
                                      width: locationHasError ? 1.5 : 1,
                                    ),
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
                                                : (locationHasError ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79)),
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
                              if (locationHasError)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Text(
                                    'Please choose location from map',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFE31C2E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
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
                            onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter Address Label';
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
                            onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter Address Line 1';
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
                            onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
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
                                  onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter City';
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
                                  onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter Postal Code';
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
                            onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(
                            label: 'Contact Person Phone (Optional)',
                            hint: '10-digit mobile number',
                            controller: contactPersonPhoneController,
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
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
                              onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                            ),
                            const SizedBox(height: 8),
                            _buildInputField(
                              label: 'State',
                              hint: 'State name',
                              controller: stateController,
                              prefixIcon: Icons.map_outlined,
                              onEmojiDetected: () => showModalAlert('Emojis are not allowed!'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter State';
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
                                final isFormValid = formKey.currentState?.validate() ?? false;
                                final hasLocation = latitude != null &&
                                    longitude != null &&
                                    locationController.text.trim().isNotEmpty;

                                setModalState(() {
                                  autovalidateMode = AutovalidateMode.onUserInteraction;
                                  locationHasError = !hasLocation;
                                });

                                if (!hasLocation) {
                                  showModalAlert('Please choose location from map');
                                  return;
                                }

                                if (labelController.text.trim().isEmpty) {
                                  showModalAlert('Please enter Address Label');
                                  return;
                                }

                                if (addressLine1Controller.text.trim().isEmpty) {
                                  showModalAlert('Please enter Address Line 1');
                                  return;
                                }

                                if (cityController.text.trim().isEmpty) {
                                  showModalAlert('Please enter City');
                                  return;
                                }

                                if (postalCodeController.text.trim().isEmpty) {
                                  showModalAlert('Please enter Postal Code');
                                  return;
                                }

                                if (stateController.text.trim().isEmpty) {
                                  showModalAlert('Please enter State');
                                  return;
                                }

                                if (!isFormValid) {
                                  showModalAlert('Please fill in all required fields correctly');
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
                                errorBannerTimer?.cancel();
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
          ),
        );
      },
    );
  }

  DateTime? _lastAlertTime;

  bool _containsEmoji(String? text) {
    if (text == null || text.isEmpty) return false;
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}'
      r'|\u{1F300}-\u{1F5FF}'
      r'|\u{1F680}-\u{1F6FF}'
      r'|\u{1F700}-\u{1F77F}'
      r'|\u{1F780}-\u{1F7FF}'
      r'|\u{1F800}-\u{1F8FF}'
      r'|\u{1F900}-\u{1F9FF}'
      r'|\u{1FA00}-\u{1FA6F}'
      r'|\u{1FA70}-\u{1FAFF}'
      r'|\u{2600}-\u{26FF}'
      r'|\u{2700}-\u{27BF}'
      r'|\u{2300}-\u{23FF}'
      r'|\u{2B50}'
      r'|\u{200D}'
      r'|\u{FE0E}-\u{FE0F}'
      r'|\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  String _removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}'
      r'|\u{1F300}-\u{1F5FF}'
      r'|\u{1F680}-\u{1F6FF}'
      r'|\u{1F700}-\u{1F77F}'
      r'|\u{1F780}-\u{1F7FF}'
      r'|\u{1F800}-\u{1F8FF}'
      r'|\u{1F900}-\u{1F9FF}'
      r'|\u{1FA00}-\u{1FA6F}'
      r'|\u{1FA70}-\u{1FAFF}'
      r'|\u{2600}-\u{26FF}'
      r'|\u{2700}-\u{27BF}'
      r'|\u{2300}-\u{23FF}'
      r'|\u{2B50}'
      r'|\u{200D}'
      r'|\u{FE0E}-\u{FE0F}'
      r'|\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '');
  }

  void _showWarningSnackBar(BuildContext context, String message) {
    final now = DateTime.now();
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!).inMilliseconds < 1500) {
      return;
    }
    _lastAlertTime = now;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E24),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE31C2E).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE31C2E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiAlert(BuildContext context) {
    _showWarningSnackBar(context, 'Emojis are not allowed!');
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onEmojiDetected,
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
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (_containsEmoji(newValue.text)) {
                if (onEmojiDetected != null) {
                  onEmojiDetected();
                } else {
                  _showEmojiAlert(context);
                }
                final clean = _removeEmojis(newValue.text);
                return TextEditingValue(
                  text: clean,
                  selection: TextSelection.collapsed(
                    offset: clean.length >= newValue.selection.end
                        ? newValue.selection.end - (newValue.text.length - clean.length)
                        : clean.length,
                  ),
                );
              }
              return newValue;
            }),
            ...?inputFormatters,
          ],
          validator: (val) {
            if (_containsEmoji(val)) {
              return "Emojis are not allowed!";
            }
            if (validator != null) {
              return validator(val);
            }
            return null;
          },
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Color(0xFFE31C2E)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
            ),
            errorStyle: GoogleFonts.poppins(
              color: const Color(0xFFE31C2E),
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: routeToEdit?['routeName'] ?? '');

    final addressProvider = context.read<AddressProvider>();
    final addresses = addressProvider.addresses;

    if (addresses.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('You need to add at least one saved address before creating saved routes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C6F79))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31C2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _onTabChanged(0);
                _showAddressBottomSheet(context);
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
                    key: formKey,
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
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Route Name',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF6C6F79),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F8),
                                  border: Border.all(color: const Color(0xFFE7E7EB), width: 1.0),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: TextFormField(
                                  controller: nameController,
                                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.route_outlined, size: 18, color: Color(0xFF6C6F79)),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
                                    hintText: 'e.g. Home to Warehouse',
                                    hintStyle: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Route Name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pickup Address Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Pickup Address',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF6C6F79),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F8),
                                  border: Border.all(color: const Color(0xFFE7E7EB), width: 1.0),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButtonFormField<int>(
                                  value: selectedPickupId,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C6F79), size: 20),
                                  borderRadius: BorderRadius.circular(16),
                                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF1C9A5B)),
                                    prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 20),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  hint: Text('Select Pickup Location', style: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13)),
                                  items: addresses.map((addr) {
                                    final id = (addr['id'] as num).toInt();
                                    final label = addr['label'] ?? '';
                                    final details = addr['addressLine1'] ?? '';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        label.isNotEmpty ? '$label ($details)' : details,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Drop Address Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Drop Address',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF6C6F79),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F8),
                                  border: Border.all(color: const Color(0xFFE7E7EB), width: 1.0),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButtonFormField<int>(
                                  value: selectedDropId,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C6F79), size: 20),
                                  borderRadius: BorderRadius.circular(16),
                                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFE31C2E)),
                                    prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 20),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  hint: Text('Select Drop Location', style: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13)),
                                  items: addresses.map((addr) {
                                    final id = (addr['id'] as num).toInt();
                                    final label = addr['label'] ?? '';
                                    final details = addr['addressLine1'] ?? '';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        label.isNotEmpty ? '$label ($details)' : details,
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
                                if (!formKey.currentState!.validate()) return;

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

  Widget _buildTabBar(int addressCount, int routeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDF1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Addresses Tab (Left)
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(0),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: _selectedTab == 0 ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Addresses',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.w500,
                        color: _selectedTab == 0 ? const Color(0xFF121214) : const Color(0xFF6C6F79),
                      ),
                    ),
                    if (addressCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? const Color(0xFFE31C2E).withOpacity(0.12)
                              : const Color(0xFFDDDEE4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$addressCount',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0 ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Routes Tab (Right)
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alt_route_rounded,
                      size: 16,
                      color: _selectedTab == 1 ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Routes',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.w500,
                        color: _selectedTab == 1 ? const Color(0xFF121214) : const Color(0xFF6C6F79),
                      ),
                    ),
                    if (routeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? const Color(0xFFE31C2E).withOpacity(0.12)
                              : const Color(0xFFDDDEE4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$routeCount',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1 ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(AddressProvider addressProvider, List<dynamic> addresses) {
    final isLoading = addressProvider.isLoading;

    if (isLoading && addresses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
        ),
      );
    }

    if (addresses.isEmpty) {
      return Center(
        child: SingleChildScrollView(
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
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
    );
  }

  Widget _buildRoutesList(SavedRouteProvider routeProvider, List<dynamic> routes) {
    final isLoading = routeProvider.isLoading;

    if (isLoading && routes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
        ),
      );
    }

    if (routes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
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
                  Icons.alt_route_rounded,
                  size: 64,
                  color: Color(0xFFD0D5DD),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Saved Routes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121214),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Combine pickup and drop addresses into shortcuts.',
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
                onPressed: () => _showRouteBottomSheet(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Create New Route',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final item = routes[index];
        final name = item['routeName'] ?? '';
        final pickup = item['pickupAddress']?['address'] ?? '';
        final drop = item['dropAddress']?['address'] ?? '';

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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEBEC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.alt_route_rounded, color: Color(0xFFE31C2E), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF121214),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _showRouteBottomSheet(context, routeToEdit: item),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF121214),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _deleteRoute(item['id']),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFE31C2E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F1F4)),
                const SizedBox(height: 12),
                // Pickup Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F7EF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.circle, color: Color(0xFF1C9A5B), size: 8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6C6F79),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            pickup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF121214),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Drop Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDEBEC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFFE31C2E), size: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DROP',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6C6F79),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            drop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF121214),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final routeProvider = Provider.of<SavedRouteProvider>(context);
    final addresses = addressProvider.addresses;
    final routes = routeProvider.savedRoutes;

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
          _selectedTab == 0 ? 'Saved Addresses' : 'Saved Routes',
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
                onPressed: () {
                  if (_selectedTab == 0) {
                    _showAddressBottomSheet(context);
                  } else {
                    _showRouteBottomSheet(context);
                  }
                },
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
      body: Column(
        children: [
          _buildTabBar(addresses.length, routes.length),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              children: [
                _buildAddressList(addressProvider, addresses),
                _buildRoutesList(routeProvider, routes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

