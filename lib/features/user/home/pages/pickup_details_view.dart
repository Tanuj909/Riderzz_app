import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';
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

  String? _parcelType;
  bool _isCreatingBooking = false;
  bool _showQuickBook = true;
  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData != null && widget.initialData!.isNotEmpty) {
        // Restore from previous input
        _pickupController.text = widget.initialData!['pickupAddressText'] ?? '';
        final pickupLat = widget.initialData!['pickupLatitude'];
        final pickupLng = widget.initialData!['pickupLongitude'];
        if (pickupLat != null) _pickupLatitude = (pickupLat as num).toDouble();
        if (pickupLng != null) _pickupLongitude = (pickupLng as num).toDouble();

        _dropController.text = widget.initialData!['dropAddressText'] ?? '';
        final dropLat = widget.initialData!['dropLatitude'];
        final dropLng = widget.initialData!['dropLongitude'];
        if (dropLat != null) _dropLatitude = (dropLat as num).toDouble();
        if (dropLng != null) _dropLongitude = (dropLng as num).toDouble();

        _parcelType = widget.initialData!['goodsType'];
        _selectedWeight = widget.initialData!['weightKg']?.toString() ?? '0-5 Kg';
        _goodsDescriptionController.text = widget.initialData!['goodsDescription'] ?? '';
        setState(() {});

      } else if (widget.initialRoute != null) {
        final pickup = widget.initialRoute!['pickupAddress'];
        final drop = widget.initialRoute!['dropAddress'];
        
        if (pickup != null) {
          _pickupController.text = _formatAddress(pickup);
          _pickupLatitude = pickup['latitude'];
          _pickupLongitude = pickup['longitude'];
        }
        if (drop != null) {
          _dropController.text = _formatAddress(drop);
          _dropLatitude = drop['latitude'];
          _dropLongitude = drop['longitude'];
        }
        setState(() {});
      } else {
        _selectedWeight = '0-5 Kg';
        _locationProvider = Provider.of<LocationProvider>(context, listen: false);
        _locationProvider?.addListener(_onLocationChanged);
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
    final descriptionText = _goodsDescriptionController.text.trim();

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      setState(() {
        _showQuickBook = false; // ensures "Fill the details!" shows up for parcel type if null
      });
      return;
    }

    if (pickupText.isEmpty || dropText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and drop locations'), backgroundColor: Colors.redAccent),
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
      'weightKg': _selectedWeight,
    };

    widget.onContinue(bookingData);
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
              const Divider(height: 1, color: Color(0xFFE7E7EB)),
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: Color(0xFFB9700A)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF121214), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pickupController,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w400),
                          onChanged: (value) {
                            _pickupLatitude = null;
                            _pickupLongitude = null;
                          },
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Fill the details!' : null,
                          decoration: const InputDecoration(
                            hintText: 'Enter pickup location',
                            hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            errorStyle: TextStyle(height: 0.8),
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
                        child: const Icon(Icons.map_outlined, size: 20, color: Color(0xFFE31C2E)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Container(width: 1.5, height: 20, color: const Color(0xFFE7E7EB)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFE31C2E), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dropController,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF121214), fontWeight: FontWeight.w400),
                          onChanged: (value) {
                            _dropLatitude = null;
                            _dropLongitude = null;
                          },
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Fill the details!' : null,
                          decoration: const InputDecoration(
                            hintText: 'Add drop location',
                            hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            errorStyle: TextStyle(height: 0.8),
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
                        child: const Icon(Icons.map_outlined, size: 20, color: Color(0xFFE31C2E)),
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
