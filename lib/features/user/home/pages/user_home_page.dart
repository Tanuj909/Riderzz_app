import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/features/user/addresses/location_picker_screen.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';

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
  int _selectedVehicleIndex = 1; // Default to Mini Truck

  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();

  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropLatitude;
  double? _dropLongitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
      Provider.of<SavedRouteProvider>(context, listen: false).fetchSavedRoutes();
      _setCurrentLocationAsPickup();
    });
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
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }



  void _showBookingConfirmDialog(BuildContext context, VehicleInfo vehicle) {
    final dropText = _dropController.text.trim();
    if (dropText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a drop location to book')),
      );
      return;
    }

    if (_pickupLatitude != null && _pickupLongitude != null) {
      debugPrint('Booking Pickup Coordinates: $_pickupLatitude, $_pickupLongitude');
    }
    if (_dropLatitude != null && _dropLongitude != null) {
      debugPrint('Booking Drop Coordinates: $_dropLatitude, $_dropLongitude');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0F9B6E), size: 48),
            SizedBox(height: 12),
            Text('Booking Confirmed! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your ride with ${vehicle.name} has been booked.', style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233))),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('PICKUP', style: TextStyle(fontSize: 10, color: Color(0xFF6B7785), fontWeight: FontWeight.w500)),
            Text(_pickupController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text('DROP', style: TextStyle(fontSize: 10, color: Color(0xFF6B7785), fontWeight: FontWeight.w500)),
            Text(dropText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text('ESTIMATED FARE', style: TextStyle(fontSize: 10, color: Color(0xFF6B7785), fontWeight: FontWeight.w500)),
            Text(vehicle.basePrice, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A3D6B))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBookingConfirmed();
            },
            child: const Text('Track Booking', style: TextStyle(color: Color(0xFF1A3D6B), fontWeight: FontWeight.bold)),
          ),
        ],
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
                // Horizontal Quick Saved Addresses
                Consumer<AddressProvider>(
                  builder: (context, addressProvider, _) {
                    final addresses = addressProvider.addresses;
                    if (addresses.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        const Text(
                          'QUICK BOOK SAVED DESTINATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7785),
                            letterSpacing: 0.06,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                    );
                  },
                ),
                Consumer<SavedRouteProvider>(
                  builder: (context, savedRouteProvider, _) {
                    final routes = savedRouteProvider.savedRoutes;
                    if (routes.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        const Text(
                          'QUICK BOOK SAVED ROUTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7785),
                            letterSpacing: 0.06,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE9ECF0)),
                const SizedBox(height: 8),
                // Goods type & Weight indicators
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFFB0B8C4)),
                            SizedBox(width: 6),
                            Text('Goods type', style: TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.scale_outlined, size: 14, color: Color(0xFFB0B8C4)),
                            SizedBox(width: 6),
                            Text('Weight (KG)', style: TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vehicle choice section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Vehicle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A2233),
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    final isSelected = _selectedVehicleIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVehicleIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F0FB) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                vehicle.icon,
                                size: 28,
                                color: const Color(0xFF1A3D6B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A2233),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.scale_outlined, size: 11, color: Color(0xFF6B7785)),
                                          const SizedBox(width: 3),
                                          Text(
                                            vehicle.maxLoad,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF6B7785)),
                                          const SizedBox(width: 3),
                                          Text(
                                            vehicle.eta,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  vehicle.basePrice,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A2233),
                                  ),
                                ),
                                Text(
                                  vehicle.rate,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 12),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A3D6B),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Book Ride Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3D6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showBookingConfirmDialog(context, _vehicles[_selectedVehicleIndex]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Continue with ${_vehicles[_selectedVehicleIndex].name}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleInfo {
  final String name;
  final IconData icon;
  final String maxLoad;
  final String eta;
  final String basePrice;
  final String rate;

  const VehicleInfo({
    required this.name,
    required this.icon,
    required this.maxLoad,
    required this.eta,
    required this.basePrice,
    required this.rate,
  });
}

final List<VehicleInfo> _vehicles = const [
  VehicleInfo(
    name: 'Bike / Scooter',
    icon: Icons.motorcycle_rounded,
    maxLoad: 'Max 20 KG',
    eta: '5 min',
    basePrice: '₹40',
    rate: '+₹8/km',
  ),
  VehicleInfo(
    name: 'Mini Truck',
    icon: Icons.local_shipping_rounded,
    maxLoad: 'Max 750 KG',
    eta: '8 min',
    basePrice: '₹180',
    rate: '+₹18/km',
  ),
  VehicleInfo(
    name: 'Pickup Truck',
    icon: Icons.local_shipping_outlined,
    maxLoad: 'Max 1500 KG',
    eta: '12 min',
    basePrice: '₹280',
    rate: '+₹25/km',
  ),
  VehicleInfo(
    name: 'Large Truck',
    icon: Icons.airport_shuttle_rounded,
    maxLoad: 'Max 5000 KG',
    eta: '20 min',
    basePrice: '₹650',
    rate: '+₹45/km',
  ),
];
