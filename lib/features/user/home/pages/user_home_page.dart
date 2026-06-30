import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';
import 'package:riderzz_app/features/admin/vehicles/providers/admin_vehicles_provider.dart';
import 'package:riderzz_app/features/user/home/pages/choose_vehicle_screen.dart';

class UserHomePage extends StatefulWidget {
  final VoidCallback onBookingConfirmed;

  const UserHomePage({
    super.key,
    required this.onBookingConfirmed,
  });

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {


  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _goodsDescriptionController = TextEditingController();
  final _weightController = TextEditingController();

  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropLatitude;
  double? _dropLongitude;

  String? _parcelType;
  bool _isCreatingBooking = false;
  bool _showQuickBook = true;
  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
      Provider.of<SavedRouteProvider>(context, listen: false).fetchSavedRoutes();
      Provider.of<AdminVehiclesProvider>(context, listen: false).fetchVehicleTypes();
      
      _locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _locationProvider?.addListener(_onLocationChanged);
      
      _setCurrentLocationAsPickup();
    });
  }

  void _onLocationChanged() {
    if (mounted && _pickupController.text.isEmpty) {
      _setCurrentLocationAsPickup();
    }
  }

  /// If the user granted location permission, auto-fill pickup with current location.
  void _setCurrentLocationAsPickup() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.hasLocation) {
      setState(() {
        _pickupController.text = locationProvider.currentAddress ?? '';
        _pickupLatitude = locationProvider.currentLatitude;
        _pickupLongitude = locationProvider.currentLongitude;
      });
    }
  }

  @override
  void dispose() {
    _locationProvider?.removeListener(_onLocationChanged);
    _pickupController.dispose();
    _dropController.dispose();
    _goodsDescriptionController.dispose();
    _weightController.dispose();
    super.dispose();
  }



  Future<int?> _resolveOrCreateAddressId({
    required String addressText,
    required double? lat,
    required double? lng,
    required String label,
  }) async {
    if (addressText.isEmpty) return null;

    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    for (final addr in addressProvider.addresses) {
      if (addr['address'] == addressText || 
          (lat != null && lng != null && 
           ((addr['lat'] as num).toDouble() - lat).abs() < 0.005 && 
           ((addr['lng'] as num).toDouble() - lng).abs() < 0.005)) {
        return addr['id'] as int;
      }
    }

    final data = {
      'label': label,
      'addressLine1': addressText,
      'latitude': lat ?? 28.6139,
      'longitude': lng ?? 77.2090,
      'city': 'Delhi',
      'state': 'Delhi',
      'country': 'India',
      'postalCode': '110001',
      'addressType': 'OTHER',
    };

    try {
      final success = await addressProvider.addAddress(data);
      if (success) {
        final fresh = addressProvider.addresses;
        if (fresh.isNotEmpty) {
          final found = fresh.firstWhere(
            (a) => a['addressLine1'] == addressText || a['label'] == label,
            orElse: () => fresh.last,
          );
          return found['id'] as int;
        }
      }
    } catch (e) {
      debugPrint('Failed to save address on-the-fly: $e');
    }
    return null;
  }

  void _handleContinueFlow(BuildContext context) async {
    final pickupText = _pickupController.text.trim();
    final dropText = _dropController.text.trim();
    final weightText = _weightController.text.trim();
    final descriptionText = _goodsDescriptionController.text.trim();

    if (pickupText.isEmpty || dropText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and drop locations'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_parcelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goods type'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final double? weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter goods description'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isCreatingBooking = true;
    });

    final pickupId = await _resolveOrCreateAddressId(
      addressText: pickupText,
      lat: _pickupLatitude,
      lng: _pickupLongitude,
      label: 'Pickup Location',
    );

    final dropId = await _resolveOrCreateAddressId(
      addressText: dropText,
      lat: _dropLatitude,
      lng: _dropLongitude,
      label: 'Drop Location',
    );

    if (pickupId == null || dropId == null) {
      setState(() {
        _isCreatingBooking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resolve address coordinates. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() {
      _isCreatingBooking = false;
    });

    if (!mounted) return;

    final bookingData = {
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
      'weightKg': _weightController.text.trim(),
      'onBookingConfirmed': widget.onBookingConfirmed,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseVehicleScreen(
          bookingData: bookingData,
        ),
      ),
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
                  color: Color(0xFF1A2233),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.pin_drop_rounded, color: Color(0xFF0F9B6E)),
                title: const Text('Set as Pickup Location', style: TextStyle(fontSize: 14,color: Colors.black87,)),
                onTap: () {
                  setState(() {
                    _pickupController.text = item['address'] ?? '';
                    _pickupLatitude = item['lat'] is num ? (item['lat'] as num).toDouble() : null;
                    _pickupLongitude = item['lng'] is num ? (item['lng'] as num).toDouble() : null;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Pickup set to $label'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFE9ECF0)),
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: Color(0xFFF97316)),
                title: const Text('Set as Drop Location', style: TextStyle(fontSize: 14,color: Colors.black87,)),
                onTap: () {
                  setState(() {
                    _dropController.text = item['address'] ?? '';
                    _dropLatitude = item['lat'] is num ? (item['lat'] as num).toDouble() : null;
                    _dropLongitude = item['lng'] is num ? (item['lng'] as num).toDouble() : null;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Drop set to $label'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Booking card sitting below header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1A3D6B),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F9B6E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pickupController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          _pickupLatitude = null;
                          _pickupLongitude = null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Enter pickup location',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
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
                          setState(() {
                            _pickupController.text = result['address'] ?? '';
                            _pickupLatitude = result['latitude'];
                            _pickupLongitude = result['longitude'];
                          });
                        }
                      },
                      child: const Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: Color(0xFF1A3D6B),
                      ),
                    ),
                  ],
                ),
                // Connection line
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Container(
                    width: 1.5,
                    height: 20,
                    color: const Color(0xFFE9ECF0),
                  ),
                ),
                // Drop Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dropController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          _dropLatitude = null;
                          _dropLongitude = null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Add drop location',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
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
                          setState(() {
                            _dropController.text = result['address'] ?? '';
                            _dropLatitude = result['latitude'];
                            _dropLongitude = result['longitude'];
                          });
                        }
                      },
                      child: const Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: Color(0xFF1A3D6B),
                      ),
                    ),
                  ],
                ),
                // Collapsible Quick Saved destinations and routes dropdown
                Consumer2<AddressProvider, SavedRouteProvider>(
                  builder: (context, addressProvider, savedRouteProvider, _) {
                    final addresses = addressProvider.addresses;
                    final routes = savedRouteProvider.savedRoutes;
                    if (addresses.isEmpty && routes.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
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
                                      color: Color(0xFF1A3D6B),
                                    ),
                                  ),
                                Icon(
                                  _showQuickBook
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF1A3D6B),
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
                                color: Color(0xFF4A5568),
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
                                  Color chipBg = const Color(0xFFFFF3E8);
                                  Color chipIconColor = const Color(0xFFF97316);

                                  if (lowerLabel == 'home') {
                                    chipIcon = Icons.home_rounded;
                                    chipBg = const Color(0xFFE6F7F2);
                                    chipIconColor = const Color(0xFF0F9B6E);
                                  } else if (lowerLabel == 'office') {
                                    chipIcon = Icons.business_rounded;
                                    chipBg = const Color(0xFFE8F0FB);
                                    chipIconColor = const Color(0xFF1A3D6B);
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
                                          border: Border.all(color: chipIconColor.withValues(alpha: 0.15)),
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
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1A2233),
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
                                color: Color(0xFF4A5568),
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
                                  
                                  Color chipBg = const Color(0xFFFDF2F8);
                                  Color chipIconColor = const Color(0xFFDB2777);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: InkWell(
                                      onTap: () {
                                        final pickup = item['pickupAddress'] ?? {};
                                        final drop = item['dropAddress'] ?? {};
                                        setState(() {
                                          _pickupController.text = pickup['address'] ?? '';
                                          _pickupLatitude = pickup['lat'] is num ? (pickup['lat'] as num).toDouble() : null;
                                          _pickupLongitude = pickup['lng'] is num ? (pickup['lng'] as num).toDouble() : null;

                                          _dropController.text = drop['address'] ?? '';
                                          _dropLatitude = drop['lat'] is num ? (drop['lat'] as num).toDouble() : null;
                                          _dropLongitude = drop['lng'] is num ? (drop['lng'] as num).toDouble() : null;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Route set to "$routeName"'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: chipBg,
                                          border: Border.all(color: chipIconColor.withValues(alpha: 0.15)),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.directions_outlined, size: 14, color: chipIconColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              routeName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1A2233),
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
              ],
            ),
          ),

          // Goods & Payment details section card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1A3D6B),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _parcelType,
                        onChanged: (val) {
                          if (val != null) setState(() => _parcelType = val);
                        },
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A3D6B)),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233), fontWeight: FontWeight.w500),
                        items: ['DOCUMENT', 'CLOTHES', 'ELECTRONICS', 'GROCERY', 'MEDICINE', 'FOOD', 'OTHER'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233), fontWeight: FontWeight.w500)));
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Goods Type',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233), fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Weight (KG)',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _goodsDescriptionController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Goods Description',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECF0))),
                  ),
                ),
              ],
            ),
          ),

          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SizedBox(
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
                ),
                onPressed: _isCreatingBooking
                    ? null
                    : () => _handleContinueFlow(context),
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
          ),
        ],
      ),
    );
  }
}
