// ========================================================================
// COMMENTED OUT: Original Photon-based SearchLocationScreen
// ========================================================================
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:riderzz_app/models/photon_place.dart';
// import 'package:riderzz_app/repositories/location_repository.dart';
// import 'package:riderzz_app/utils/debounce.dart';
// import 'package:riderzz_app/widgets/search_textfield.dart';
// import 'package:riderzz_app/widgets/search_result_tile.dart';
//
// class SearchLocationScreen extends StatefulWidget {
//   final String hintText;
//
//   const SearchLocationScreen({
//     super.key,
//     this.hintText = 'Search for area, street, city...',
//   });
//
//   @override
//   State<SearchLocationScreen> createState() => _SearchLocationScreenState();
// }
//
// class _SearchLocationScreenState extends State<SearchLocationScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   final LocationRepository _locationRepository = LocationRepository();
//   final Debouncer _debouncer = Debouncer(milliseconds: 400);
//
//   List<PhotonPlace> _suggestions = [];
//   bool _isLoading = false;
//   String _activeSearchQuery = '';
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNode.requestFocus();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _focusNode.dispose();
//     _debouncer.dispose();
//     super.dispose();
//   }
//
//   void _onSearchChanged(String query) {
//     debugPrint('SearchScreen: _onSearchChanged called with: "$query"');
//     if (query.trim().length < 3) {
//       _debouncer.run(() {});
//       setState(() {
//         _suggestions = [];
//         _isLoading = false;
//         _errorMessage = null;
//         _activeSearchQuery = '';
//       });
//       return;
//     }
//
//     debugPrint('SearchScreen: Scheduling debounced search for: "$query"');
//     _debouncer.run(() => _performSearch(query));
//   }
//
//   Future<void> _performSearch(String query) async {
//     debugPrint('SearchScreen: _performSearch called for: "$query"');
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _activeSearchQuery = query;
//     });
//
//     try {
//       final results = await _locationRepository.search(query);
//       debugPrint('SearchScreen: Got ${results.length} results for: "$query"');
//
//       if (_activeSearchQuery == query) {
//         setState(() {
//           _suggestions = results;
//           _isLoading = false;
//         });
//       } else {
//         debugPrint('SearchScreen: Stale response for "$query", active is "$_activeSearchQuery"');
//       }
//     } catch (e) {
//       debugPrint('SearchScreen: Error during search: $e');
//       if (_activeSearchQuery == query) {
//         setState(() {
//           _suggestions = [];
//           _isLoading = false;
//           _errorMessage = 'An error occurred while searching';
//         });
//         _showErrorSnackBar('Network error or search failed. Please try again.');
//       }
//     }
//   }
//
//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _clearSearch() {
//     _searchController.clear();
//     _onSearchChanged('');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Select Location',
//           style: GoogleFonts.plusJakartaSans(
//             color: const Color(0xFF121214),
//             fontSize: 16.5,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SearchTextField(
//               controller: _searchController,
//               focusNode: _focusNode,
//               hintText: widget.hintText,
//               onChanged: _onSearchChanged,
//               onClear: _clearSearch,
//             ),
//           ),
//           const Divider(height: 1, thickness: 0.5, color: Color(0xFFE1E1E6)),
//           Expanded(
//             child: _buildBody(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(
//           valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
//         ),
//       );
//     }
//
//     if (_errorMessage != null) {
//       return Center(
//         child: Text(
//           _errorMessage!,
//           style: GoogleFonts.outfit(
//             color: const Color(0xFF6C6F79),
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       );
//     }
//
//     if (_searchController.text.trim().length >= 3 && _suggestions.isEmpty) {
//       return Center(
//         child: Text(
//           'No places found',
//           style: GoogleFonts.outfit(
//             color: const Color(0xFF6C6F79),
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       );
//     }
//
//     return ListView.separated(
//       itemCount: _suggestions.length,
//       separatorBuilder: (context, index) => const Divider(
//         height: 1,
//         thickness: 0.5,
//         color: Color(0xFFE7E7EB),
//       ),
//       itemBuilder: (context, index) {
//         final place = _suggestions[index];
//         return SearchResultTile(
//           place: place,
//           onTap: () {
//             Navigator.pop(context, place);
//           },
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/models/google_place.dart';
import 'package:riderzz_app/repositories/location_repository.dart';
import 'package:riderzz_app/utils/debounce.dart';
import 'package:riderzz_app/widgets/search_textfield.dart';
import 'package:riderzz_app/widgets/search_result_tile.dart';

class SearchLocationScreen extends StatefulWidget {
  final String hintText;

  const SearchLocationScreen({
    super.key,
    this.hintText = 'Search for area, street, city...',
  });

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocationRepository _locationRepository = LocationRepository();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  List<GooglePlace> _suggestions = [];
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  String _activeSearchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    debugPrint('SearchScreen: _onSearchChanged called with: "$query"');
    if (query.trim().length < 3) {
      _debouncer.run(() {}); // cancel any pending timer
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _errorMessage = null;
        _activeSearchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('SearchScreen: Scheduling debounced search for: "$query"');
    _debouncer.run(() => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    debugPrint('SearchScreen: _performSearch called for: "$query"');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeSearchQuery = query;
    });

    try {
      final results = await _locationRepository.search(query);
      debugPrint('SearchScreen: Got ${results.length} results for: "$query"');

      // Verify that this response is still for the most recent query
      if (_activeSearchQuery == query) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      } else {
        debugPrint(
            'SearchScreen: Stale response for "$query", active is "$_activeSearchQuery"');
      }
    } catch (e) {
      debugPrint('SearchScreen: Error during search: $e');
      if (_activeSearchQuery == query) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _errorMessage = 'An error occurred while searching';
        });
        _showErrorSnackBar('Network error or search failed. Please try again.');
      }
    }
  }

  /// Fetches full place details (lat/lng) from Google Places API
  /// and pops back with the completed GooglePlace.
  Future<void> _onPlaceSelected(GooglePlace suggestion) async {
    if (_isFetchingDetails) return; // prevent double-taps

    setState(() {
      _isFetchingDetails = true;
    });

    try {
      final details =
          await _locationRepository.getPlaceDetails(suggestion.placeId);
      if (details != null && mounted) {
        final result = await LocationPickerScreen.showSaveAddressBottomSheet(
          context: context,
          latitude: details.latitude ?? 0.0,
          longitude: details.longitude ?? 0.0,
          fullAddress: details.displayName,
          googlePlace: details,
        );
        if (result != null && mounted) {
          final place = GooglePlace(
            placeId: suggestion.placeId,
            displayName: result['address'] ?? details.displayName,
            name: result['address'] ?? details.displayName,
            latitude: result['latitude'] ?? details.latitude,
            longitude: result['longitude'] ?? details.longitude,
            contactPersonName: result['contactPersonName'],
            contactPersonPhone: result['contactPersonPhone'],
          );
          Navigator.pop(context, place);
        } else {
          setState(() {
            _isFetchingDetails = false;
          });
        }
      } else if (mounted) {
        _showErrorSnackBar('Could not fetch place details. Please try again.');
        setState(() {
          _isFetchingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('SearchScreen: Error fetching place details: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to get location. Please try again.');
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isFetchingDetails = true;
    });
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Force refresh current location to get the latest accurate location
      await locationProvider.refresh();
      
      if (locationProvider.hasLocation && mounted) {
        final lat = locationProvider.currentLatitude ?? 0.0;
        final lng = locationProvider.currentLongitude ?? 0.0;
        final address = locationProvider.currentAddress ?? 'Current Location';
        final result = await LocationPickerScreen.showSaveAddressBottomSheet(
          context: context,
          latitude: lat,
          longitude: lng,
          fullAddress: address,
          placemark: locationProvider.currentPlacemark,
        );
        if (result != null && mounted) {
          final currentPlace = GooglePlace(
            placeId: 'current_location',
            displayName: result['address'] ?? address,
            name: 'Current Location',
            latitude: result['latitude'] ?? lat,
            longitude: result['longitude'] ?? lng,
            contactPersonName: result['contactPersonName'],
            contactPersonPhone: result['contactPersonPhone'],
          );
          Navigator.pop(context, currentPlace);
        } else {
          setState(() {
            _isFetchingDetails = false;
          });
        }
      } else if (mounted) {
        _showErrorSnackBar('Unable to fetch current location. Please verify GPS permission.');
        setState(() {
          _isFetchingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('SearchScreen: Error using current location: $e');
      if (mounted) {
        _showErrorSnackBar('Error fetching current location.');
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF121214), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF121214),
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchTextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  hintText: widget.hintText,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ),
              // Current Location Selector option (visible only when search query is empty)
              if (_searchController.text.trim().isEmpty)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFFE31C2E),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Use Current Location',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF121214),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Set your current location as address',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6C6F79),
                      fontSize: 11.5,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA2A5AE),
                  ),
                  onTap: _useCurrentLocation,
                ),
              const Divider(
                  height: 1, thickness: 0.5, color: Color(0xFFE1E1E6)),
              Expanded(
                child: _searchController.text.trim().isNotEmpty
                    ? _buildBody()
                    : _buildAddressesList(),
              ),
            ],
          ),
          // Full-screen loading overlay while fetching place details
          if (_isFetchingDetails)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E))));
        }

        final addresses = provider.addresses;
        if (addresses.isEmpty) {
          return Center(
            child: Text(
              'No saved addresses',
              style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 14),
            ),
          );
        }

        return ListView.separated(
          itemCount: addresses.length,
          padding: const EdgeInsets.symmetric(vertical: 12),
          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFE7E7EB)),
          itemBuilder: (context, index) {
            final address = addresses[index];
            final label = address['label'] ?? address['addressType'] ?? 'Saved Address';
            
            // Construct a meaningful subtitle
            final parts = <String>[];
            if (address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
              parts.add(address['addressLine1']);
            }
            if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
              parts.add(address['addressLine2']);
            }
            if (address['city'] != null && address['city'].toString().isNotEmpty) {
              parts.add(address['city']);
            }
            final addressString = (address['address'] != null && address['address'].toString().trim().isNotEmpty)
                ? address['address'].toString().trim()
                : parts.join(', ');

            final lowerLabel = label.toString().toLowerCase();
            IconData iconData = Icons.location_on_rounded;
            if (lowerLabel == 'home') {
              iconData = Icons.home_rounded;
            } else if (lowerLabel == 'office') {
              iconData = Icons.business_rounded;
            }

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1F4),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: const Color(0xFF121214), size: 20),
              ),
              title: Text(
                label.toString().isNotEmpty ? label.toString() : addressString,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF121214)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: label.toString().isNotEmpty && addressString.isNotEmpty
                  ? Text(
                      addressString,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => _onSavedAddressSelected(address),
            );
          },
        );
      },
    );
  }

  Future<void> _onSavedAddressSelected(Map<String, dynamic> address) async {
    final double? lat = address['lat'] is num
        ? (address['lat'] as num).toDouble()
        : (address['latitude'] is num ? (address['latitude'] as num).toDouble() : null);
    final double? lng = address['lng'] is num
        ? (address['lng'] as num).toDouble()
        : (address['longitude'] is num ? (address['longitude'] as num).toDouble() : null);

    final label = address['label'] ?? address['addressType'] ?? 'Saved Address';

    String addressString = (address['address'] != null && address['address'].toString().trim().isNotEmpty)
        ? address['address'].toString().trim()
        : '';

    if (addressString.isEmpty) {
      final parts = <String>[];
      if (address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
        parts.add(address['addressLine1']);
      }
      if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
        parts.add(address['addressLine2']);
      }
      if (address['city'] != null && address['city'].toString().isNotEmpty) {
        parts.add(address['city']);
      }
      addressString = parts.join(', ');
    }

    final nameController = TextEditingController(text: address['contactPersonName'] ?? '');
    final phoneController = TextEditingController(text: address['contactPersonPhone'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Confirm Contact Person',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          try {
                            final FlutterNativeContactPicker picker = FlutterNativeContactPicker();
                            final contact = await picker.selectPhoneNumber();
                            if (contact != null) {
                              if (contact.fullName != null && contact.fullName!.isNotEmpty) {
                                nameController.text = contact.fullName!;
                              }
                              if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                String? rawNumber = contact.selectedPhoneNumber;
                                if (rawNumber != null) {
                                  String sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                  phoneController.text = sanitized;
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
                            const Text(
                              'Choose from contacts',
                              style: TextStyle(fontSize: 12, color: Color(0xFFE31C2E), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Contact Person Name',
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE7E7EB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE7E7EB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF121214))),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Contact Person Phone',
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFFB0B8C4), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE7E7EB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE7E7EB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF121214))),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isUpdating = true);
                            final provider = Provider.of<AddressProvider>(context, listen: false);
                            
                            // Check if changed
                            if (nameController.text.trim() != (address['contactPersonName'] ?? '') ||
                                phoneController.text.trim() != (address['contactPersonPhone'] ?? '')) {
                              
                              final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);
                              final userId = authProvider.currentUser?.userId;
                              if (userId != null && address['id'] != null) {
                                final updatedData = {
                                  'contactPersonName': nameController.text.trim(),
                                  'contactPersonPhone': phoneController.text.trim(),
                                };
                                final int addressId = address['id'] is int
                                    ? address['id'] as int
                                    : (int.tryParse(address['id'].toString()) ?? 0);
                                if (addressId != 0) {
                                  await provider.updateAddressContact(
                                    id: addressId,
                                    userId: userId,
                                    data: updatedData,
                                  );
                                }
                              }
                            }
                            
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31C2E),
                    foregroundColor: Colors.white,
                  ),
                  child: isUpdating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final place = GooglePlace(
        placeId: 'saved_address_${address['id']}',
        name: label.toString(),
        displayName: addressString,
        latitude: lat,
        longitude: lng,
        contactPersonName: nameController.text.trim(),
        contactPersonPhone: phoneController.text.trim(),
      );
      Navigator.pop(context, place);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_searchController.text.trim().length >= 3 && _suggestions.isEmpty) {
      return Center(
        child: Text(
          'No places found',
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE7E7EB),
      ),
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        return SearchResultTile(
          place: place,
          onTap: () => _onPlaceSelected(place),
        );
      },
    );
  }
}
