import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';

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
        setState(() {
          _fullAddress = "Unknown Location";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
      setState(() {
        _fullAddress = "Unable to resolve address. Try panning the map.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D6B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Choose Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_latitude, _longitude),
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
          
          // Floating Search Bar Card with Autocomplete Suggestions Dropdown
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: googleApiKey,
                  inputDecoration: const InputDecoration(
                    hintText: 'Search for area, street, city...',
                    hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B7785),
                      size: 22,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 22,
                    ),
                  ),
                  debounceTime: 500,
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    if (prediction.lat != null && prediction.lng != null) {
                      double lat = double.parse(prediction.lat!);
                      double lng = double.parse(prediction.lng!);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(lat, lng),
                          16.0,
                        ),
                      );
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _searchController.text = prediction.description ?? '';
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: (prediction.description ?? '').length),
                    );
                  },
                  itemBuilder: (BuildContext context, int index, Prediction prediction) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF6B7785),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prediction.description ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A2233),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  seperatedBuilder: const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFE9ECF0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A2233),
                  ),
                  boxDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  isCrossBtnShown: true,
                ),
              ),
            ),
          ),
          
          // Fixed center pin 📍
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 36), // Align pin pointer precisely to the center coordinate
              child: const Icon(
                Icons.location_on_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),
          
          // Bottom Panel for Selected Address and Confirm Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
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
                          color: Color(0xFF6B7785),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3D6B)),
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
                        color: Color(0xFF1A3D6B),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isLoading ? "Locating..." : _fullAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isLoading ? const Color(0xFFB0B8C4) : const Color(0xFF1A2233),
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
                        backgroundColor: const Color(0xFF1A3D6B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: const Color(0xFFE9ECF0),
                        disabledForegroundColor: const Color(0xFFB0B8C4),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (widget.showSaveOption) {
                                _showSaveAddressBottomSheet(context);
                              } else {
                                Navigator.pop(context, {
                                  'latitude': _latitude,
                                  'longitude': _longitude,
                                  'address': _fullAddress,
                                });
                              }
                            },
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  void _showSaveAddressBottomSheet(BuildContext context) {
    final labelController = TextEditingController();
    final addressController = TextEditingController(text: _fullAddress);
    String selectedType = 'other';

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
                        const Text(
                          'Save this Location?',
                          style: TextStyle(
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

                    // Full Address field
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
                          hintText: 'Enter full location details',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preset chips
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
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'home';
                                labelController.text = 'Home';
                              });
                            },
                            child: _buildTypeChip('Home', Icons.home_rounded, selectedType == 'home'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'office';
                                labelController.text = 'Office';
                              });
                            },
                            child: _buildTypeChip('Office', Icons.business_rounded, selectedType == 'office'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'other';
                                if (labelController.text == 'Home' || labelController.text == 'Office') {
                                  labelController.clear();
                                }
                              });
                            },
                            child: _buildTypeChip('Other', Icons.location_on_rounded, selectedType == 'other'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Label input
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

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1A3D6B), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // close bottom sheet
                                Navigator.pop(this.context, {
                                  'latitude': _latitude,
                                  'longitude': _longitude,
                                  'address': _fullAddress,
                                }); // close map picker
                              },
                              child: const Text(
                                'Just Confirm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A3D6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
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
                              onPressed: () async {
                                final label = labelController.text.trim();
                                final address = addressController.text.trim();
                                if (label.isEmpty || address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill out all fields')),
                                  );
                                  return;
                                }

                                 String addressType = 'OTHER';
                                 final lowerLabel = label.toLowerCase();
                                 if (lowerLabel == 'home') {
                                   addressType = 'HOME';
                                 } else if (lowerLabel == 'office') {
                                   addressType = 'OFFICE';
                                 }

                                 String addressLine1 = address;
                                 String addressLine2 = '';
                                 String landmark = '';
                                 String city = 'Mumbai';
                                 String state = 'Maharashtra';
                                 String country = 'India';
                                 String postalCode = '400001';

                                 try {
                                   final placemarks = await placemarkFromCoordinates(_latitude, _longitude);
                                   if (placemarks.isNotEmpty) {
                                     final pm = placemarks.first;
                                     final street = pm.street ?? '';
                                     final subLocality = pm.subLocality ?? '';
                                     addressLine1 = street.isNotEmpty ? street : address;
                                     addressLine2 = street.isNotEmpty ? subLocality : '';
                                     landmark = pm.thoroughfare ?? '';
                                     city = pm.locality ?? city;
                                     state = pm.administrativeArea ?? state;
                                     country = pm.country ?? country;
                                     postalCode = pm.postalCode ?? postalCode;
                                   }
                                 } catch (_) {
                                   final parts = address.split(',');
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

                                 final data = {
                                   'addressType': addressType,
                                   'label': label,
                                   'addressLine1': addressLine1,
                                   'addressLine2': addressLine2,
                                   'landmark': landmark,
                                   'city': city,
                                   'state': state,
                                   'country': country,
                                   'postalCode': postalCode,
                                   'latitude': _latitude,
                                   'longitude': _longitude,
                                   'defaultAddress': false,
                                 };

                                 final provider = Provider.of<AddressProvider>(context, listen: false);
                                 final success = await provider.addAddress(data);

                                if (success) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Address saved successfully')),
                                    );
                                    Navigator.pop(context); // close bottom sheet
                                  }
                                  if (mounted) {
                                    Navigator.pop(this.context, {
                                      'latitude': _latitude,
                                      'longitude': _longitude,
                                      'address': address,
                                    }); // close map picker
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
                                'Save & Confirm',
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
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip(String label, IconData icon, bool isSelected) {
    return Container(
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
