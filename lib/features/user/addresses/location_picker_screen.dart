import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/screens/search_location_screen.dart';
import 'package:riderzz_app/models/google_place.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/core/services/location_service.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool showSaveOption;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.showSaveOption = true,
  });

  static Future<Map<String, dynamic>?> showSaveAddressBottomSheet({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String fullAddress,
    String? searchQuery,
    Placemark? placemark,
    GooglePlace? googlePlace,
  }) async {
    String addressLine1 = fullAddress;
    String addressLine2 = '';
    String landmark = '';
    String city = 'Mumbai';
    String state = 'Maharashtra';
    String country = 'India';
    String postalCode = ''; // Default to empty

    if (placemark != null) {
      final pm = placemark;
      final street = pm.street ?? '';
      final subLocality = pm.subLocality ?? '';
      addressLine1 = street.isNotEmpty ? street : fullAddress;
      addressLine2 = subLocality;
      landmark = pm.thoroughfare ?? '';
      city = pm.locality ?? city;
      state = pm.administrativeArea ?? state;
      country = pm.country ?? country;
      postalCode = pm.postalCode ?? postalCode;
    } else {
      final parts = fullAddress.split(',');
      if (parts.isNotEmpty) {
        addressLine1 = parts[0].trim();
        if (parts.length > 1) {
          addressLine2 = parts[1].trim();
        }
        if (parts.length > 2) {
          city = parts[parts.length - 2].trim();
        }
      }
    }

    if (googlePlace != null) {
      if (googlePlace.street != null && googlePlace.street!.isNotEmpty) addressLine1 = googlePlace.street!;
      if (googlePlace.city != null && googlePlace.city!.isNotEmpty) city = googlePlace.city!;
      if (googlePlace.state != null && googlePlace.state!.isNotEmpty) state = googlePlace.state!;
      if (googlePlace.country != null && googlePlace.country!.isNotEmpty) country = googlePlace.country!;
      if (googlePlace.postalCode != null && googlePlace.postalCode!.isNotEmpty) postalCode = googlePlace.postalCode!;
    }

    final formKey = GlobalKey<FormState>();
    
    // Auto-fill Address Label with search query if available, otherwise initial name segment
    String initialLabel = '';
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      initialLabel = searchQuery.split(',').first.trim();
    } else {
      final parts = fullAddress.split(',');
      if (parts.isNotEmpty) {
        initialLabel = parts[0].trim();
      }
    }
    
    final labelController = TextEditingController(text: initialLabel);
    final addressLine1Controller = TextEditingController(text: addressLine1);
    final addressLine2Controller = TextEditingController(text: addressLine2);
    final landmarkController = TextEditingController(text: landmark);
    final cityController = TextEditingController(text: city);
    final stateController = TextEditingController(text: state);
    final countryController = TextEditingController(text: country);
    final postalCodeController = TextEditingController(text: postalCode);
    final contactPersonNameController = TextEditingController();
    final contactPersonPhoneController = TextEditingController();

    // Default preset type depending on auto-fill
    String selectedType = 'OTHER';
    if (initialLabel.toLowerCase() == 'home') {
      selectedType = 'HOME';
    } else if (initialLabel.toLowerCase() == 'office') {
      selectedType = 'OFFICE';
    }
    
    bool isDefault = false;
    bool showAdvanced = false;

    if (!context.mounted) return null;

    return showModalBottomSheet<Map<String, dynamic>>(
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
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Save this Location?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121214),
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
                        const SizedBox(height: 16),

                        // Preset chips row
                        Row(
                          children: [
                            _buildStaticModalTypeChip(
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
                            _buildStaticModalTypeChip(
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
                            _buildStaticModalTypeChip(
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
                        _buildStaticInputField(
                          label: 'Address Label',
                          hint: 'e.g. Friend\'s House, Gym, Factory',
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

                        // Highlighted and Shifted fields above Address Line 1
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: GestureDetector(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.contacts_rounded, color: Color(0xFFE31C2E), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Choose from contacts',
                                  style: TextStyle(fontSize: 10, color: const Color(0xFFE31C2E), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildStaticInputField(
                          label: 'Contact Person Name (Optional)',
                          hint: 'Name of the contact person',
                          controller: contactPersonNameController,
                          prefixIcon: Icons.person_outline_rounded,
                          isHighlighted: true,
                        ),
                        const SizedBox(height: 8),
                        _buildStaticInputField(
                          label: 'Contact Person Phone (Optional)',
                          hint: '10-digit mobile number',
                          controller: contactPersonPhoneController,
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          isHighlighted: true,
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

                        // Address Line 1
                        _buildStaticInputField(
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
                        _buildStaticInputField(
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
                              child: _buildStaticInputField(
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
                              child: _buildStaticInputField(
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
                                    color: Color(0xFFE31C2E),
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
                          _buildStaticInputField(
                            label: 'Address Line 2 (Optional)',
                            hint: 'Locality, Sector, Area',
                            controller: addressLine2Controller,
                            prefixIcon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 8),
                          _buildStaticInputField(
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
                          const SizedBox(height: 8),
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
                                color: Color(0xFF121214),
                              ),
                            ),
                            Switch(
                              value: isDefault,
                              activeThumbColor: const Color(0xFFE31C2E),
                              activeTrackColor: const Color(0xFFE31C2E).withValues(alpha: 0.5),
                              onChanged: (val) {
                                setModalState(() {
                                  isDefault = val;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE31C2E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;

                                    final label = labelController.text.trim();
                                    final addrLine1 = addressLine1Controller.text.trim();
                                    final addrLine2 = addressLine2Controller.text.trim();
                                    final landm = landmarkController.text.trim();
                                    final cit = cityController.text.trim();
                                    final stat = stateController.text.trim();
                                    final postCode = postalCodeController.text.trim();
                                    final countr = countryController.text.trim();

                                    final data = {
                                      'addressType': selectedType,
                                      'label': label,
                                      'addressLine1': addrLine1,
                                      'addressLine2': addrLine2,
                                      'landmark': landm,
                                      'city': cit,
                                      'state': stat,
                                      'country': countr,
                                      'postalCode': postCode,
                                      'latitude': latitude,
                                      'longitude': longitude,
                                      'defaultAddress': isDefault,
                                      'contactPersonName': contactPersonNameController.text.trim(),
                                      'contactPersonPhone': contactPersonPhoneController.text.trim(),
                                    };

                                    final provider = Provider.of<AddressProvider>(context, listen: false);
                                    final success = await provider.addAddress(data);

                                    if (success) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Address saved successfully')),
                                        );
                                        // Construct full address line for UI
                                        final fullAddrString = [
                                          addrLine1,
                                          if (addrLine2.isNotEmpty) addrLine2,
                                          if (landm.isNotEmpty) landm,
                                          cit,
                                          postCode,
                                        ].join(', ');
                                        Navigator.pop(context, {
                                          'latitude': latitude,
                                          'longitude': longitude,
                                          'address': fullAddrString,
                                        });
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(provider.errorMessage ?? 'Failed to save address')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
          },
        );
      },
    );
  }

  static Widget _buildStaticModalTypeChip({
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
            color: isSelected ? const Color(0xFFFDEBEC) : const Color(0xFFF6F6F8),
            border: Border.all(
              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStaticInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    bool isHighlighted = false,
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

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  late double _latitude;
  late double _longitude;
  
  String _fullAddress = "Fetching location details...";
  bool _isLoading = false;
  Placemark? _currentPlacemark;
  GooglePlace? _selectedGooglePlace;

  bool _isMapAtSelectedPlace() {
    if (_selectedGooglePlace == null || _selectedGooglePlace!.latitude == null || _selectedGooglePlace!.longitude == null) return false;
    final latDiff = (_latitude - _selectedGooglePlace!.latitude!).abs();
    final lngDiff = (_longitude - _selectedGooglePlace!.longitude!).abs();
    return latDiff < 0.0001 && lngDiff < 0.0001;
  }

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude ?? _getDefaultLatitude();
    _longitude = widget.initialLongitude ?? _getDefaultLongitude();
  }

  /// Falls back to current GPS location, then hardcoded Delhi coordinates.
  double _getDefaultLatitude() {
    try {
      final locProvider = Provider.of<LocationProvider>(context, listen: false);
      return locProvider.currentLatitude ?? 28.6139;
    } catch (_) {
      return 28.6139;
    }
  }

  double _getDefaultLongitude() {
    try {
      final locProvider = Provider.of<LocationProvider>(context, listen: false);
      return locProvider.currentLongitude ?? 77.2090;
    } catch (_) {
      return 77.2090;
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        _currentPlacemark = pm;
        List<String> parts = [];
        
        // Construct a clean, comprehensive address format
        if (pm.name != null && pm.name!.isNotEmpty && pm.name != pm.subLocality) {
          parts.add(pm.name!);
        }
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
          parts.add(pm.subLocality!);
        }
        if (pm.locality != null && pm.locality!.isNotEmpty) {
          parts.add(pm.locality!);
        }
        if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) {
          parts.add(pm.administrativeArea!);
        }
        if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
          parts.add(pm.postalCode!);
        }
        if (pm.country != null && pm.country!.isNotEmpty) {
          parts.add(pm.country!);
        }
        
        setState(() {
          _fullAddress = parts.isEmpty ? "Unknown Location" : parts.join(', ');
          _isLoading = false;
        });
      } else {
        _currentPlacemark = null;
        setState(() {
          _fullAddress = "Unknown Location";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
      _currentPlacemark = null;
      setState(() {
        _fullAddress = "Unable to resolve address. Try panning the map.";
        _isLoading = false;
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = LocationService();
      final permission = await service.requestPermission();
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await service.getCurrentPosition();
        if (position != null) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16.0),
          );
          
          await _reverseGeocode(position.latitude, position.longitude);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to retrieve GPS coordinates. Please turn on device location services.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is denied. Please enable it in system settings.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error moving to current location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Google Map Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_latitude, _longitude),
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // Perform geocoding on the starting position
              _reverseGeocode(_latitude, _longitude);
            },
            onCameraMove: (CameraPosition position) {
              _latitude = position.target.latitude;
              _longitude = position.target.longitude;
            },
            onCameraIdle: () {
              _reverseGeocode(_latitude, _longitude);
            },
          ),
          
          // Top Row: Back Button + Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 18),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        final place = await Navigator.push<GooglePlace>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchLocationScreen(),
                          ),
                        );
                        if (place != null && mounted && place.latitude != null && place.longitude != null) {
                          setState(() {
                            _searchController.text = place.displayName;
                            _latitude = place.latitude!;
                            _longitude = place.longitude!;
                            _selectedGooglePlace = place;
                          });
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(place.latitude!, place.longitude!),
                              16.0,
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF6C6F79),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _searchController.text.isNotEmpty
                                    ? _searchController.text
                                    : 'Search for area, street, city...',
                                style: GoogleFonts.outfit(
                                  color: _searchController.text.isNotEmpty
                                      ? const Color(0xFF121214)
                                      : const Color(0xFFB0B8C4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
          
          // Fixed center pin 📍
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 40), // Align pin pointer precisely to the center coordinate
              child: const Icon(
                Icons.location_on_rounded,
                size: 40,
                color: Color(0xFFB31222), // Darker red
              ),
            ),
          ),
          
          // Bottom Panel for Selected Address and Confirm Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                  child: FloatingActionButton(
                    heroTag: 'current_location_fab',
                    onPressed: _moveToCurrentLocation,
                    backgroundColor: Colors.white,
                    mini: true,
                    elevation: 4,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFFE31C2E),
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SELECTED LOCATION',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C6F79),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFFE31C2E),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isLoading ? "Locating..." : _fullAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isLoading ? const Color(0xFFB0B8C4) : const Color(0xFF121214),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31C2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        disabledBackgroundColor: const Color(0xFFE7E7EB),
                        disabledForegroundColor: const Color(0xFFB0B8C4),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (widget.showSaveOption) {
                                final navigator = Navigator.of(context);
                                final result = await LocationPickerScreen.showSaveAddressBottomSheet(
                                  context: context,
                                  latitude: _latitude,
                                  longitude: _longitude,
                                  fullAddress: _fullAddress,
                                  searchQuery: _searchController.text,
                                  placemark: _currentPlacemark,
                                  googlePlace: _isMapAtSelectedPlace() ? _selectedGooglePlace : null,
                                );
                                if (result != null && mounted) {
                                  navigator.pop(result);
                                }
                              } else {
                                Navigator.pop(context, {
                                  'latitude': _latitude,
                                  'longitude': _longitude,
                                  'address': _fullAddress,
                                  'googlePlace': _isMapAtSelectedPlace() ? _selectedGooglePlace : null,
                                });
                              }
                            },
                      child: Text(
                        'Confirm Location',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
