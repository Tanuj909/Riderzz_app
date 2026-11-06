import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';
import 'package:riderzz_app/screens/search_location_screen.dart';
import 'package:riderzz_app/models/google_place.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riderzz_app/core/widgets/app_snackbar.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

class PickupDetailsView extends StatefulWidget {
  final Map<String, dynamic>? initialRoute;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onContinue;

  const PickupDetailsView({
    super.key,
    this.initialRoute,
    this.initialData,
    required this.onContinue,
  });

  @override
  State<PickupDetailsView> createState() => _PickupDetailsViewState();
}

class _PickupDetailsViewState extends State<PickupDetailsView> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _goodsDescriptionController = TextEditingController();
  String? _selectedWeight = '0-5 Kg';

  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropLatitude;
  double? _dropLongitude;

  int? _pickupAddressId;
  int? _dropAddressId;
  String? _pickupPlaceId;
  String? _dropPlaceId;

  String? _pickupCity;
  String? _pickupState;
  String? _pickupCountry;
  String? _pickupPostalCode;

  String? _dropCity;
  String? _dropState;
  String? _dropCountry;
  String? _dropPostalCode;

  String? _pickupContactName;
  String? _pickupContactPhone;
  String? _dropContactName;
  String? _dropContactPhone;

  String? _parcelType;
  bool _isCreatingBooking = false;
  bool _showQuickBook = true;
  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedWeight = '0-5 Kg';
      _locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _locationProvider?.addListener(_onLocationChanged);

      if (widget.initialData != null && widget.initialData!.isNotEmpty) {
        // Restore from previous input
        _pickupController.text = widget.initialData!['pickupAddressText'] ?? '';
        final pickupLat = widget.initialData!['pickupLatitude'];
        final pickupLng = widget.initialData!['pickupLongitude'];
        if (pickupLat != null) _pickupLatitude = (pickupLat as num).toDouble();
        if (pickupLng != null) _pickupLongitude = (pickupLng as num).toDouble();
        if (widget.initialData!['pickupAddressId'] is num) {
          _pickupAddressId = (widget.initialData!['pickupAddressId'] as num).toInt();
        }
        _pickupCity = widget.initialData!['pickupCity']?.toString();
        _pickupState = widget.initialData!['pickupState']?.toString();
        _pickupCountry = widget.initialData!['pickupCountry']?.toString();
        _pickupPostalCode = widget.initialData!['pickupPostalCode']?.toString();

        _dropController.text = widget.initialData!['dropAddressText'] ?? '';
        final dropLat = widget.initialData!['dropLatitude'];
        final dropLng = widget.initialData!['dropLongitude'];
        if (dropLat != null) _dropLatitude = (dropLat as num).toDouble();
        if (dropLng != null) _dropLongitude = (dropLng as num).toDouble();
        if (widget.initialData!['dropAddressId'] is num) {
          _dropAddressId = (widget.initialData!['dropAddressId'] as num).toInt();
        }
        _dropCity = widget.initialData!['dropCity']?.toString();
        _dropState = widget.initialData!['dropState']?.toString();
        _dropCountry = widget.initialData!['dropCountry']?.toString();
        _dropPostalCode = widget.initialData!['dropPostalCode']?.toString();

        _parcelType = widget.initialData!['goodsType'];
        if (widget.initialData!['weightKg'] != null) {
          _selectedWeight = widget.initialData!['weightKg']?.toString();
        }
        _goodsDescriptionController.text = widget.initialData!['goodsDescription'] ?? '';
        
        _pickupContactName = widget.initialData!['pickupContactName'];
        _pickupContactPhone = widget.initialData!['pickupContactPhone'];
        _dropContactName = widget.initialData!['dropContactName'];
        _dropContactPhone = widget.initialData!['dropContactPhone'];
        
        // If pickup controller text is empty, fill it with current location as fallback
        if (_pickupController.text.trim().isEmpty) {
          _setCurrentLocationAsPickup();
        }
        setState(() {});

      } else if (widget.initialRoute != null) {
        final pickup = widget.initialRoute!['pickupAddress'];
        final drop = widget.initialRoute!['dropAddress'];
        
        if (pickup != null) {
          _pickupController.text = _formatAddress(pickup);
          _pickupLatitude = pickup['latitude'];
          _pickupLongitude = pickup['longitude'];
          if (pickup['id'] is num) {
            _pickupAddressId = (pickup['id'] as num).toInt();
          }
          _pickupCity = pickup['city']?.toString();
          _pickupState = pickup['state']?.toString();
          _pickupCountry = pickup['country']?.toString();
          _pickupPostalCode = pickup['postalCode']?.toString();
          _pickupContactName = pickup['contactPersonName'] ?? pickup['contactName'] ?? pickup['pickupContactName'];
          _pickupContactPhone = pickup['contactPersonPhone'] ?? pickup['contactPhone'] ?? pickup['pickupContactPhone'];
        } else {
          _setCurrentLocationAsPickup();
        }
        if (drop != null) {
          _dropController.text = _formatAddress(drop);
          _dropLatitude = drop['latitude'];
          _dropLongitude = drop['longitude'];
          if (drop['id'] is num) {
            _dropAddressId = (drop['id'] as num).toInt();
          }
          _dropCity = drop['city']?.toString();
          _dropState = drop['state']?.toString();
          _dropCountry = drop['country']?.toString();
          _dropPostalCode = drop['postalCode']?.toString();
          _dropContactName = drop['contactPersonName'] ?? drop['contactName'] ?? drop['dropContactName'];
          _dropContactPhone = drop['contactPersonPhone'] ?? drop['contactPhone'] ?? drop['dropContactPhone'];
        }
        setState(() {});
      } else {
        _setCurrentLocationAsPickup();
      }
    });
  }

  String _formatAddress(Map<String, dynamic> addr) {
    if (addr['address'] != null && addr['address'].toString().trim().isNotEmpty) {
      return addr['address'].toString().trim();
    }
    List<String> parts = [];
    if (addr['addressLine1'] != null && addr['addressLine1'].toString().trim().isNotEmpty) {
      parts.add(addr['addressLine1'].toString().trim());
    }
    if (addr['addressLine2'] != null && addr['addressLine2'].toString().trim().isNotEmpty) {
      parts.add(addr['addressLine2'].toString().trim());
    }
    if (addr['city'] != null && addr['city'].toString().trim().isNotEmpty) {
      parts.add(addr['city'].toString().trim());
    }
    if (addr['state'] != null && addr['state'].toString().trim().isNotEmpty) {
      parts.add(addr['state'].toString().trim());
    }
    
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return addr['label'] ?? '';
  }

  void _onLocationChanged() {
    if (mounted && _pickupController.text.isEmpty) {
      _setCurrentLocationAsPickup();
    }
  }

  void _setCurrentLocationAsPickup() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (locationProvider.hasLocation) {
      final pm = locationProvider.currentPlacemark;
      setState(() {
        _pickupController.text = locationProvider.currentAddress ?? '';
        _pickupLatitude = locationProvider.currentLatitude;
        _pickupLongitude = locationProvider.currentLongitude;
        _pickupAddressId = null;
        _pickupPlaceId = null;
        _pickupCity = pm?.locality ?? pm?.subAdministrativeArea;
        _pickupState = pm?.administrativeArea;
        _pickupCountry = pm?.country;
        _pickupPostalCode = pm?.postalCode;
        
        final user = authProvider.currentUser;
        if (user != null) {
          _pickupContactName = user.name ?? authProvider.customerProfile?.fullName;
          _pickupContactPhone = user.phone;
        }
      });
    }
  }

  bool _isDuplicateLocation({
    required double? lat1,
    required double? lng1,
    required String text1,
    int? addressId1,
    String? placeId1,
    required double? lat2,
    required double? lng2,
    required String text2,
    int? addressId2,
    String? placeId2,
  }) {
    // 1. If both locations have valid saved address IDs:
    if (addressId1 != null && addressId2 != null) {
      if (addressId1 == addressId2) {
        return true;
      }
      return false;
    }

    final t1 = text1.trim();
    final t2 = text2.trim();

    // 2. Identity-aware normalized text comparison (including flat, unit, tower, building details)
    if (t1.isNotEmpty && t2.isNotEmpty) {
      final norm1 = _normalizeAddressText(t1);
      final norm2 = _normalizeAddressText(t2);

      if (norm1 == norm2) {
        if (lat1 != null && lng1 != null && lat2 != null && lng2 != null) {
          if ((lat1 - lat2).abs() < 0.0005 && (lng1 - lng2).abs() < 0.0005) {
            return true;
          }
        } else {
          return true;
        }
      } else {
        // Different unit, flat, tower or street details mean different locations
        // (e.g. Pickup: Flat 101, Tower A vs Drop: Flat 205, Tower B - 20m apart)
        return false;
      }
    }

    // 3. If Google Place IDs are available:
    final cleanPlace1 = (placeId1 != null && placeId1 != 'current_location' && !placeId1.startsWith('saved_address_')) ? placeId1 : null;
    final cleanPlace2 = (placeId2 != null && placeId2 != 'current_location' && !placeId2.startsWith('saved_address_')) ? placeId2 : null;

    if (cleanPlace1 != null && cleanPlace2 != null) {
      if (cleanPlace1 != cleanPlace2) {
        return false;
      }
      // Same Google Place ID without distinguishing unit details on either side
      return true;
    }

    // 4. Where reliable identity information is unavailable:
    // Handle ambiguity safely rather than automatically declaring both locations identical.
    // Do NOT reject two locations solely because GPS coordinates are close.
    if (lat1 != null && lng1 != null && lat2 != null && lng2 != null) {
      final isExactSameCoord = (lat1 - lat2).abs() < 0.00001 && (lng1 - lng2).abs() < 0.00001;
      if (isExactSameCoord && (t1.isEmpty || t2.isEmpty || _normalizeAddressText(t1) == _normalizeAddressText(t2))) {
        return true;
      }
    }

    return false;
  }

  bool _validateAndApplyLocation({
    required bool isPickup,
    required String address,
    required double? lat,
    required double? lng,
    String? contactName,
    String? contactPhone,
    int? addressId,
    String? placeId,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    final otherText = isPickup ? _dropController.text : _pickupController.text;
    final otherLat = isPickup ? _dropLatitude : _pickupLatitude;
    final otherLng = isPickup ? _dropLongitude : _pickupLongitude;
    final otherAddressId = isPickup ? _dropAddressId : _pickupAddressId;
    final otherPlaceId = isPickup ? _dropPlaceId : _pickupPlaceId;

    if (otherText.trim().isNotEmpty || (otherLat != null && otherLng != null)) {
      final isSame = _isDuplicateLocation(
        lat1: lat,
        lng1: lng,
        text1: address,
        addressId1: addressId,
        placeId1: placeId,
        lat2: otherLat,
        lng2: otherLng,
        text2: otherText,
        addressId2: otherAddressId,
        placeId2: otherPlaceId,
      );

      if (isSame) {
        final message = isPickup
            ? 'Please choose a different pickup location. It cannot be the same as the drop location.'
            : 'Please choose a different drop location. It cannot be the same as the pickup location.';
        _showValidationErrorDialog('Same Location', message);
        return false;
      }
    }

    setState(() {
      if (isPickup) {
        _pickupController.text = address;
        _pickupLatitude = lat;
        _pickupLongitude = lng;
        _pickupAddressId = addressId;
        _pickupPlaceId = placeId;
        _pickupCity = city;
        _pickupState = state;
        _pickupCountry = country;
        _pickupPostalCode = postalCode;
        if (contactName != null && contactName.trim().isNotEmpty) {
          _pickupContactName = contactName.trim();
        }
        if (contactPhone != null && contactPhone.trim().isNotEmpty) {
          _pickupContactPhone = contactPhone.trim();
        }
      } else {
        _dropController.text = address;
        _dropLatitude = lat;
        _dropLongitude = lng;
        _dropAddressId = addressId;
        _dropPlaceId = placeId;
        _dropCity = city;
        _dropState = state;
        _dropCountry = country;
        _dropPostalCode = postalCode;
        if (contactName != null && contactName.trim().isNotEmpty) {
          _dropContactName = contactName.trim();
        }
        if (contactPhone != null && contactPhone.trim().isNotEmpty) {
          _dropContactPhone = contactPhone.trim();
        }
      }
    });
    return true;
  }

  Future<void> _openSearchScreen({required bool isPickup}) async {
    final place = await Navigator.push<GooglePlace>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchLocationScreen(
          hintText: isPickup ? 'Search pickup location...' : 'Search drop location...',
        ),
      ),
    );
    if (place != null && mounted) {
      int? addressId;
      if (place.placeId.startsWith('saved_address_')) {
        addressId = int.tryParse(place.placeId.replaceFirst('saved_address_', ''));
      }
      _validateAndApplyLocation(
        isPickup: isPickup,
        address: place.displayName,
        lat: place.latitude,
        lng: place.longitude,
        contactName: place.contactPersonName,
        contactPhone: place.contactPersonPhone,
        addressId: addressId,
        placeId: place.placeId,
        city: place.city,
        state: place.state,
        country: place.country,
        postalCode: place.postalCode,
      );
    }
  }

  @override
  void dispose() {
    _locationProvider?.removeListener(_onLocationChanged);
    _pickupController.dispose();
    _dropController.dispose();
    _goodsDescriptionController.dispose();
    super.dispose();
  }

  String _normalizeAddressText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  Future<int?> _resolveOrCreateAddressId({
    required String addressText,
    required double? lat,
    required double? lng,
    required String label,
    int? knownAddressId,
    String? placeId,
    String? contactName,
    String? contactPhone,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) async {
    final trimmedText = addressText.trim();
    if (trimmedText.isEmpty) return null;

    // Reject and abort if latitude or longitude is unavailable; do not use hardcoded coordinates
    if (lat == null || lng == null) {
      debugPrint('[_resolveOrCreateAddressId] Aborting: latitude or longitude is null');
      return null;
    }

    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    // 1. If explicit verified address ID was provided (e.g. from saved address or route), verify it
    if (knownAddressId != null) {
      for (final addr in addressProvider.addresses) {
        if (addr['id'] == knownAddressId) {
          return knownAddressId;
        }
      }
    }

    // 2. If placeId references a saved address ('saved_address_<id>'), verify and return it
    if (placeId != null && placeId.startsWith('saved_address_')) {
      final savedId = int.tryParse(placeId.replaceFirst('saved_address_', ''));
      if (savedId != null) {
        for (final addr in addressProvider.addresses) {
          if (addr['id'] == savedId) {
            return savedId;
          }
        }
      }
    }

    // 3. Safe identity matching against existing addresses:
    // Only reuse an existing address when its identity reliably matches.
    // Never reuse an address solely because coordinates or Google Place IDs are nearby.
    // Considers Google Place ID, full formatted address, flat/unit details, and tower/building details.
    // Never use Place ID alone to identify an individual flat or unit.
    final targetNorm = _normalizeAddressText(trimmedText);
    final cleanPlaceId = (placeId != null && placeId != 'current_location' && !placeId.startsWith('saved_address_')) ? placeId : null;

    for (final addr in addressProvider.addresses) {
      final addrId = addr['id'] as int?;
      if (addrId == null) continue;

      final addrLat = (addr['lat'] ?? addr['latitude'] as num?)?.toDouble();
      final addrLng = (addr['lng'] ?? addr['longitude'] as num?)?.toDouble();

      if (addrLat == null || addrLng == null) continue;

      final coordsMatch = (addrLat - lat).abs() < 0.0005 && (addrLng - lng).abs() < 0.0005;
      final fullNorm = _normalizeAddressText(addr['address']?.toString() ?? '');
      final line1Norm = _normalizeAddressText(addr['addressLine1']?.toString() ?? '');

      // Check Google Place ID if available on saved address
      final addrPlaceId = addr['placeId']?.toString();
      final placeIdMatches = cleanPlaceId != null && addrPlaceId != null && cleanPlaceId == addrPlaceId;

      if (placeIdMatches || coordsMatch) {
        // Unit-level details (flat number, tower, building) must reliably match.
        // Never reuse Place ID alone to identify an individual flat or unit.
        if (targetNorm.isNotEmpty && (targetNorm == fullNorm || targetNorm == line1Norm)) {
          return addrId;
        }
      }
    }

    // 4. No reliable match found -> Create a new address via the address API.
    // Extract metadata from available selected location details or geocoding data without fabricating fake defaults.
    String? resolvedCity = (city != null && city.trim().isNotEmpty) ? city.trim() : null;
    String? resolvedState = (state != null && state.trim().isNotEmpty) ? state.trim() : null;
    String? resolvedCountry = (country != null && country.trim().isNotEmpty) ? country.trim() : null;
    String? resolvedPostalCode = (postalCode != null && postalCode.trim().isNotEmpty) ? postalCode.trim() : null;

    if (resolvedCity == null || resolvedState == null || resolvedCountry == null || resolvedPostalCode == null) {
      final parts = trimmedText.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (resolvedPostalCode == null) {
        final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(trimmedText);
        if (pinMatch != null) {
          resolvedPostalCode = pinMatch.group(0);
        }
      }
      if (parts.length >= 2) {
        resolvedCountry ??= parts.last;
        if (parts.length >= 3) {
          final beforeCountry = parts[parts.length - 2];
          final stateCandidate = beforeCountry.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
          if (stateCandidate.isNotEmpty) {
            resolvedState ??= stateCandidate;
          }
          if (parts.length >= 4) {
            resolvedCity ??= parts[parts.length - 3];
          } else {
            resolvedCity ??= stateCandidate;
          }
        }
      }
    }

    final data = {
      'label': label,
      'addressLine1': trimmedText,
      'latitude': lat,
      'longitude': lng,
      'city': resolvedCity ?? '',
      'state': resolvedState ?? '',
      'country': resolvedCountry ?? '',
      'postalCode': resolvedPostalCode ?? '',
      'addressType': 'OTHER',
      if (contactName != null && contactName.trim().isNotEmpty)
        'contactPersonName': contactName.trim(),
      if (contactPhone != null && contactPhone.trim().isNotEmpty)
        'contactPersonPhone': contactPhone.trim(),
    };

    try {
      final newId = await addressProvider.createAddress(data);
      if (newId != null) {
        return newId;
      }
      debugPrint('Failed to create address via API: ${addressProvider.errorMessage}');
    } catch (e) {
      debugPrint('Failed to save address on-the-fly: $e');
    }
    return null;
  }

  void _showValidationErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE31C2E),
              size: 38,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF121214),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF6C6F79),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31C2E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinueFlow(BuildContext context) async {
    final pickupText = _pickupController.text.trim();
    final dropText = _dropController.text.trim();
    final descriptionText = _goodsDescriptionController.text.trim();

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      setState(() {
        _showQuickBook = false; // ensures "Fill the details!" shows up for parcel type if null
      });
      return;
    }

    if (pickupText.isEmpty || dropText.isEmpty) {
      _showValidationErrorDialog(
        'Missing Locations',
        'Please select both pickup and drop-off locations to estimate fare.',
      );
      return;
    }

    if (_isDuplicateLocation(
      lat1: _pickupLatitude,
      lng1: _pickupLongitude,
      text1: pickupText,
      addressId1: _pickupAddressId,
      placeId1: _pickupPlaceId,
      lat2: _dropLatitude,
      lng2: _dropLongitude,
      text2: dropText,
      addressId2: _dropAddressId,
      placeId2: _dropPlaceId,
    )) {
      _showValidationErrorDialog(
        'Same Location',
        'Please choose a different drop location. It cannot be the same as the pickup location.',
      );
      return;
    }

    if (_parcelType == null) {
      _parcelType = 'OTHER';
    }

    if (_selectedWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an approximate weight'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isCreatingBooking = true;
    });

    // 1. Resolve pickup address first
    final pickupId = await _resolveOrCreateAddressId(
      addressText: pickupText,
      lat: _pickupLatitude,
      lng: _pickupLongitude,
      label: 'Pickup Location',
      knownAddressId: _pickupAddressId,
      placeId: _pickupPlaceId,
      contactName: _pickupContactName,
      contactPhone: _pickupContactPhone,
      city: _pickupCity,
      state: _pickupState,
      country: _pickupCountry,
      postalCode: _pickupPostalCode,
    );

    // If pickup creation succeeded, preserve it immediately so retries won't duplicate it
    if (pickupId != null) {
      _pickupAddressId = pickupId;
    }

    if (pickupId == null) {
      setState(() {
        _isCreatingBooking = false;
      });
      if (mounted) {
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        final errorMsg = (_pickupLatitude == null || _pickupLongitude == null)
            ? 'Pickup coordinates are missing. Please re-select the pickup location.'
            : (addressProvider.errorMessage ?? 'Failed to resolve pickup address. Please try again.');
        AppSnackBar.showError(context, errorMsg);
      }
      return;
    }

    // 2. Resolve drop address next
    final dropId = await _resolveOrCreateAddressId(
      addressText: dropText,
      lat: _dropLatitude,
      lng: _dropLongitude,
      label: 'Drop Location',
      knownAddressId: _dropAddressId,
      placeId: _dropPlaceId,
      contactName: _dropContactName,
      contactPhone: _dropContactPhone,
      city: _dropCity,
      state: _dropState,
      country: _dropCountry,
      postalCode: _dropPostalCode,
    );

    // If drop creation succeeded, preserve it
    if (dropId != null) {
      _dropAddressId = dropId;
    }

    if (dropId == null) {
      setState(() {
        _isCreatingBooking = false;
      });
      if (mounted) {
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        final errorMsg = (_dropLatitude == null || _dropLongitude == null)
            ? 'Drop coordinates are missing. Please re-select the drop location.'
            : (addressProvider.errorMessage ?? 'Failed to resolve drop address. Please try again.');
        AppSnackBar.showError(context, errorMsg);
      }
      return;
    }

    if (pickupId == dropId) {
      setState(() {
        _isCreatingBooking = false;
      });
      if (mounted) {
        AppSnackBar.showError(context, 'Pickup and drop addresses cannot be the same');
      }
      return;
    }

    setState(() {
      _isCreatingBooking = false;
    });

    if (!mounted) return;

    final bookingData = {
      if (widget.initialData != null) ...widget.initialData!,
      'pickupAddressId': pickupId,
      'dropAddressId': dropId,
      'pickupAddressText': pickupText,
      'dropAddressText': dropText,
      'pickupLatitude': _pickupLatitude,
      'pickupLongitude': _pickupLongitude,
      'dropLatitude': _dropLatitude,
      'dropLongitude': _dropLongitude,
      'goodsType': _parcelType,
      'goodsDescription': _goodsDescriptionController.text.trim(),
      'weightKg': _selectedWeight,
      'pickupContactName': _pickupContactName,
      'pickupContactPhone': _pickupContactPhone,
      'dropContactName': _dropContactName,
      'dropContactPhone': _dropContactPhone,
    };

    widget.onContinue(bookingData);
  }

  void _showContactDetailsPopup(BuildContext context, Map<String, dynamic> item, String label, bool isPickup) {
    final itemAddress = item['address'] ?? '';
    final itemLat = item['lat'] is num ? (item['lat'] as num).toDouble() : null;
    final itemLng = item['lng'] is num ? (item['lng'] as num).toDouble() : null;

    final otherText = isPickup ? _dropController.text : _pickupController.text;
    final otherLat = isPickup ? _dropLatitude : _pickupLatitude;
    final otherLng = isPickup ? _dropLongitude : _pickupLongitude;
    final otherAddressId = isPickup ? _dropAddressId : _pickupAddressId;
    final otherPlaceId = isPickup ? _dropPlaceId : _pickupPlaceId;

    if (otherText.trim().isNotEmpty || (otherLat != null && otherLng != null)) {
      final isSame = _isDuplicateLocation(
        lat1: itemLat,
        lng1: itemLng,
        text1: itemAddress,
        addressId1: item['id'] as int?,
        placeId1: null,
        lat2: otherLat,
        lng2: otherLng,
        text2: otherText,
        addressId2: otherAddressId,
        placeId2: otherPlaceId,
      );

      if (isSame) {
        final message = isPickup
            ? 'Please choose a different pickup location. It cannot be the same as the drop location.'
            : 'Please choose a different drop location. It cannot be the same as the pickup location.';
        _showValidationErrorDialog('Same Location', message);
        return;
      }
    }

    final nameController = TextEditingController(text: item['contactPersonName'] ?? '');
    final phoneController = TextEditingController(text: item['contactPersonPhone'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    showDialog(
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
                  onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
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
                            if (nameController.text.trim() != (item['contactPersonName'] ?? '') ||
                                phoneController.text.trim() != (item['contactPersonPhone'] ?? '')) {
                              
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final userId = authProvider.currentUser?.userId;
                              if (userId == null) {
                                setDialogState(() => isUpdating = false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
                                return;
                              }

                              final updatedData = {
                                'contactPersonName': nameController.text.trim(),
                                'contactPersonPhone': phoneController.text.trim(),
                              };
                              
                              final success = await provider.updateAddressContact(id: item['id'], userId: userId, data: updatedData);
                              
                              if (!success) {
                                setDialogState(() => isUpdating = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(provider.errorMessage ?? 'Failed to update address')),
                                );
                                return;
                              }
                            }
                            
                            // Set location
                            final applied = _validateAndApplyLocation(
                              isPickup: isPickup,
                              address: item['address'] ?? '',
                              lat: item['lat'] is num ? (item['lat'] as num).toDouble() : null,
                              lng: item['lng'] is num ? (item['lng'] as num).toDouble() : null,
                              contactName: nameController.text.trim(),
                              contactPhone: phoneController.text.trim(),
                              addressId: item['id'] as int?,
                              placeId: null,
                              city: item['city']?.toString(),
                              state: item['state']?.toString(),
                              country: item['country']?.toString(),
                              postalCode: item['postalCode']?.toString(),
                            );

                            Navigator.pop(dialogContext); // close dialog

                            if (!applied) return;
                            
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('${isPickup ? "Pickup" : "Drop"} set to $label'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
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
  }

  void _showRouteContactDetailsPopup(BuildContext context, Map<String, dynamic> item) {
    final routeName = item['routeName'] ?? '';
    final pickup = item['pickupAddress'] ?? {};
    final drop = item['dropAddress'] ?? {};

    final pLat = pickup['lat'] is num ? (pickup['lat'] as num).toDouble() : null;
    final pLng = pickup['lng'] is num ? (pickup['lng'] as num).toDouble() : null;
    final pAddr = pickup['address'] ?? '';
    final dLat = drop['lat'] is num ? (drop['lat'] as num).toDouble() : null;
    final dLng = drop['lng'] is num ? (drop['lng'] as num).toDouble() : null;
    final dAddr = drop['address'] ?? '';

    if (_isDuplicateLocation(
      lat1: pLat,
      lng1: pLng,
      text1: pAddr,
      lat2: dLat,
      lng2: dLng,
      text2: dAddr,
    )) {
      _showValidationErrorDialog(
        'Invalid Route',
        'Pickup and drop locations in this route are the same. Please choose different locations.',
      );
      return;
    }

    final pickupNameController = TextEditingController(text: pickup['contactPersonName'] ?? '');
    final pickupPhoneController = TextEditingController(text: pickup['contactPersonPhone'] ?? '');

    final dropNameController = TextEditingController(text: drop['contactPersonName'] ?? '');
    final dropPhoneController = TextEditingController(text: drop['contactPersonPhone'] ?? '');

    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    showDialog(
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
                'Confirm Contacts',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup Contact
                        Text('Pickup Contact', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1C9A5B))),
                        const SizedBox(height: 8),
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
                                    pickupNameController.text = contact.fullName!;
                                  }
                                  if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                    String? rawNumber = contact.selectedPhoneNumber;
                                    if (rawNumber != null) {
                                      String sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                      pickupPhoneController.text = sanitized;
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
                                const Icon(Icons.contacts_rounded, color: Color(0xFF1C9A5B), size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Choose from contacts',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF1C9A5B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: pickupNameController,
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
                          controller: pickupPhoneController,
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
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE7E7EB), height: 1),
                        const SizedBox(height: 16),
                        
                        // Drop Contact
                        Text('Drop Contact', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFB9700A))),
                        const SizedBox(height: 8),
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
                                    dropNameController.text = contact.fullName!;
                                  }
                                  if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                    String? rawNumber = contact.selectedPhoneNumber;
                                    if (rawNumber != null) {
                                      String sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                      dropPhoneController.text = sanitized;
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
                                const Icon(Icons.contacts_rounded, color: Color(0xFFB9700A), size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Choose from contacts',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFB9700A), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: dropNameController,
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
                          controller: dropPhoneController,
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isUpdating = true);
                            final provider = Provider.of<AddressProvider>(context, listen: false);
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final userId = authProvider.currentUser?.userId;
                            
                            if (userId == null) {
                              setDialogState(() => isUpdating = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
                              return;
                            }
                            
                            bool pickupChanged = pickupNameController.text.trim() != (pickup['contactPersonName'] ?? '') ||
                                                 pickupPhoneController.text.trim() != (pickup['contactPersonPhone'] ?? '');
                            bool dropChanged = dropNameController.text.trim() != (drop['contactPersonName'] ?? '') ||
                                               dropPhoneController.text.trim() != (drop['contactPersonPhone'] ?? '');

                            if (pickupChanged && pickup['id'] != null) {
                              final updatedData = {
                                'contactPersonName': pickupNameController.text.trim(),
                                'contactPersonPhone': pickupPhoneController.text.trim(),
                              };
                              await provider.updateAddressContact(id: pickup['id'], userId: userId, data: updatedData);
                            }

                            if (dropChanged && drop['id'] != null) {
                              final updatedData = {
                                'contactPersonName': dropNameController.text.trim(),
                                'contactPersonPhone': dropPhoneController.text.trim(),
                              };
                              await provider.updateAddressContact(id: drop['id'], userId: userId, data: updatedData);
                            }
                            
                            final pLat = pickup['lat'] is num ? (pickup['lat'] as num).toDouble() : null;
                            final pLng = pickup['lng'] is num ? (pickup['lng'] as num).toDouble() : null;
                            final pAddr = pickup['address'] ?? '';
                            final dLat = drop['lat'] is num ? (drop['lat'] as num).toDouble() : null;
                            final dLng = drop['lng'] is num ? (drop['lng'] as num).toDouble() : null;
                            final dAddr = drop['address'] ?? '';

                            if (_isDuplicateLocation(
                              lat1: pLat,
                              lng1: pLng,
                              text1: pAddr,
                              addressId1: pickup['id'] is num ? (pickup['id'] as num).toInt() : null,
                              lat2: dLat,
                              lng2: dLng,
                              text2: dAddr,
                              addressId2: drop['id'] is num ? (drop['id'] as num).toInt() : null,
                            )) {
                              Navigator.pop(dialogContext);
                              _showValidationErrorDialog(
                                'Invalid Route',
                                'Pickup and drop locations in this route are the same. Please choose different locations.',
                              );
                              return;
                            }

                            setState(() {
                              _pickupController.text = pAddr;
                              _pickupLatitude = pLat;
                              _pickupLongitude = pLng;
                              _pickupAddressId = pickup['id'] is num ? (pickup['id'] as num).toInt() : null;
                              _pickupPlaceId = null;
                              _pickupCity = pickup['city']?.toString();
                              _pickupState = pickup['state']?.toString();
                              _pickupCountry = pickup['country']?.toString();
                              _pickupPostalCode = pickup['postalCode']?.toString();
                              _pickupContactName = pickupNameController.text.trim();
                              _pickupContactPhone = pickupPhoneController.text.trim();

                              _dropController.text = dAddr;
                              _dropLatitude = dLat;
                              _dropLongitude = dLng;
                              _dropAddressId = drop['id'] is num ? (drop['id'] as num).toInt() : null;
                              _dropPlaceId = null;
                              _dropCity = drop['city']?.toString();
                              _dropState = drop['state']?.toString();
                              _dropCountry = drop['country']?.toString();
                              _dropPostalCode = drop['postalCode']?.toString();
                              _dropContactName = dropNameController.text.trim();
                              _dropContactPhone = dropPhoneController.text.trim();
                            });
                            
                            Navigator.pop(dialogContext); // close dialog
                            
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Route set to "$routeName"'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
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
  }

  void _showLocationActionSheet(BuildContext context, Map<String, dynamic> item, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Location: $label',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121214),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.pin_drop_rounded, color: Color(0xFF1C9A5B)),
                title: const Text('Set as Pickup Location', style: TextStyle(fontSize: 14,color: Colors.black87,)),
                onTap: () {
                  Navigator.pop(context);
                  _showContactDetailsPopup(context, item, label, true);
                },
              ),
              const Divider(height: 1, color: Color(0xFFE7E7EB)),
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: Color(0xFFB9700A)),
                title: const Text('Set as Drop Location', style: TextStyle(fontSize: 14,color: Colors.black87,)),
                onTap: () {
                  Navigator.pop(context);
                  _showContactDetailsPopup(context, item, label, false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 0,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup/Drop
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7E7EB)),
                boxShadow: const [BoxShadow(color: Color(0x0D121214), offset: Offset(0, 1), blurRadius: 2)],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 6.25,
                    top: (_pickupContactName != null && _pickupContactName!.isNotEmpty) ? 28.0 : 12.0,
                    bottom: 12.0,
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE7E7EB),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_pickupContactName != null && _pickupContactName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 26, bottom: 0),
                          child: Text(
                            '$_pickupContactName${_pickupContactPhone != null && _pickupContactPhone!.isNotEmpty ? ' • $_pickupContactPhone' : ''}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1C9A5B)),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFF121214), shape: BoxShape.circle)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pickupController,
                              readOnly: true,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w400),
                              onTap: () => _openSearchScreen(isPickup: true),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Fill the details!' : null,
                              decoration: const InputDecoration(
                                hintText: 'Enter pickup location',
                                hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 2, bottom: 8),
                                errorStyle: TextStyle(height: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openSearchScreen(isPickup: true),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.search_rounded, size: 20, color: Color(0xFFE31C2E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationPickerScreen(
                                    initialLatitude: _pickupLatitude,
                                    initialLongitude: _pickupLongitude,
                                  ),
                                ),
                              );
                              if (result != null) {
                                String? placeId;
                                String? city = result['city']?.toString();
                                String? state = result['state']?.toString();
                                String? country = result['country']?.toString();
                                String? postalCode = result['postalCode']?.toString();
                                if (result['googlePlace'] is GooglePlace) {
                                  final gp = result['googlePlace'] as GooglePlace;
                                  placeId = gp.placeId;
                                  city ??= gp.city;
                                  state ??= gp.state;
                                  country ??= gp.country;
                                  postalCode ??= gp.postalCode;
                                }
                                _validateAndApplyLocation(
                                  isPickup: true,
                                  address: result['address'] ?? '',
                                  lat: result['latitude'],
                                  lng: result['longitude'],
                                  contactName: result['contactPersonName'],
                                  contactPhone: result['contactPersonPhone'],
                                  addressId: null,
                                  placeId: placeId,
                                  city: city,
                                  state: state,
                                  country: country,
                                  postalCode: postalCode,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFE31C2E)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_dropContactName != null && _dropContactName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 26, bottom: 0, top: 0),
                          child: Text(
                            '$_dropContactName${_dropContactPhone != null && _dropContactPhone!.isNotEmpty ? ' • $_dropContactPhone' : ''}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB9700A)),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFE31C2E), shape: BoxShape.circle)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dropController,
                              readOnly: true,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w400),
                              onTap: () => _openSearchScreen(isPickup: false),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Fill the details!' : null,
                              decoration: const InputDecoration(
                                hintText: 'Add drop location',
                                hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 2, bottom: 8),
                                errorStyle: TextStyle(height: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openSearchScreen(isPickup: false),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.search_rounded, size: 20, color: Color(0xFFE31C2E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationPickerScreen(
                                    initialLatitude: _dropLatitude,
                                    initialLongitude: _dropLongitude,
                                  ),
                                ),
                              );
                              if (result != null) {
                                String? placeId;
                                String? city = result['city']?.toString();
                                String? state = result['state']?.toString();
                                String? country = result['country']?.toString();
                                String? postalCode = result['postalCode']?.toString();
                                if (result['googlePlace'] is GooglePlace) {
                                  final gp = result['googlePlace'] as GooglePlace;
                                  placeId = gp.placeId;
                                  city ??= gp.city;
                                  state ??= gp.state;
                                  country ??= gp.country;
                                  postalCode ??= gp.postalCode;
                                }
                                _validateAndApplyLocation(
                                  isPickup: false,
                                  address: result['address'] ?? '',
                                  lat: result['latitude'],
                                  lng: result['longitude'],
                                  contactName: result['contactPersonName'],
                                  contactPhone: result['contactPersonPhone'],
                                  addressId: null,
                                  placeId: placeId,
                                  city: city,
                                  state: state,
                                  country: country,
                                  postalCode: postalCode,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFE31C2E)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Goods type
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: Text('Goods type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6C6F79))),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['DOCUMENT', 'CLOTHES', 'ELECTRONICS', 'GROCERY', 'MEDICINE', 'FOOD', 'OTHER'].map((type) {
                  bool isActive = _parcelType == type;
                  String display = type[0] + type.substring(1).toLowerCase();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _parcelType = type;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: isActive 
                          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
                          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isActive ? const LinearGradient(
                          colors: [Color(0xFFE31C2E), Color(0xFFE31C2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        color: isActive ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE7E7EB)),
                      ),
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.white : const Color(0xFF121214),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Weight (approx.)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: Text('Weight (approx.)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6C6F79))),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['0-5 Kg', '5-10 Kg', '10-50 Kg', '50-200 Kg', '200-500 Kg', '500+ Kg'].map((weight) {
                    final isActive = _selectedWeight == weight;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedWeight = weight;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: isActive 
                            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
                            : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isActive ? const LinearGradient(
                            colors: [Color(0xFFE31C2E), Color(0xFFE31C2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) : null,
                          color: isActive ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE7E7EB)),
                        ),
                        child: Text(
                          weight,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive ? Colors.white : const Color(0xFF121214),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_selectedWeight == null && _showQuickBook == false) 
              const Padding(
                padding: EdgeInsets.only(left: 14, bottom: 16, top: -8),
                child: Text('Fill the details!', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Description (optional)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: Text('Description (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6C6F79))),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7EB)),
              ),
              child: TextFormField(
                controller: _goodsDescriptionController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14, color: Color(0xFF121214), fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Fragile items, packing notes...',
                  hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
            if (_parcelType == null && _showQuickBook == false) 
              const Padding(
                padding: EdgeInsets.only(left: 14, bottom: 8),
                child: Text('Fill the details!', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Quick Options
            Consumer2<AddressProvider, SavedRouteProvider>(
              builder: (context, addressProvider, savedRouteProvider, _) {
                final addresses = addressProvider.addresses;
                final routes = savedRouteProvider.savedRoutes;
                if (addresses.isEmpty && routes.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showQuickBook = !_showQuickBook;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Book Options',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF121214),
                              ),
                            ),
                            Icon(
                              _showQuickBook
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF121214),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showQuickBook) ...[
                      if (addresses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Saved Destinations',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C6F79),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final item = addresses[index];
                              final label = item['label'] ?? '';
                              final lowerLabel = label.toLowerCase();

                              IconData chipIcon = Icons.location_on_rounded;
                              Color chipBg = const Color(0xFFF1F1F4);
                              Color chipIconColor = const Color(0xFF121214);

                              if (lowerLabel == 'home') {
                                chipIcon = Icons.home_rounded;
                              } else if (lowerLabel == 'office') {
                                chipIcon = Icons.business_rounded;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () => _showLocationActionSheet(context, item, label),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: chipBg,
                                      border: Border.all(color: const Color(0xFFE7E7EB)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(chipIcon, size: 14, color: chipIconColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6C6F79),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (routes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Saved Routes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C6F79),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: routes.length,
                            itemBuilder: (context, index) {
                              final item = routes[index];
                              final routeName = item['routeName'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    _showRouteContactDetailsPopup(context, item);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F1F4),
                                      border: Border.all(color: const Color(0xFFE7E7EB)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.directions_outlined, size: 14, color: Color(0xFF121214)),
                                        const SizedBox(width: 5),
                                        Text(
                                          routeName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6C6F79),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31C2E), // var(--red)
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: const Color(0x8C7E22CE), // rgba(227,28,46,.55) equivalent roughly
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isCreatingBooking
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _handleContinueFlow(context);
                        }
                      },
                child: _isCreatingBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
