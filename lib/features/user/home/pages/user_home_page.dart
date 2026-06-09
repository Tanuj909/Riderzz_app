import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';

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

  final _pickupController = TextEditingController(text: 'Connaught Place, New Delhi');
  final _dropController = TextEditingController();

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
                        scrollPadding: const EdgeInsets.only(top: 80, bottom: 20),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter pickup location',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
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
                        scrollPadding: const EdgeInsets.only(top: 80, bottom: 20),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add drop location',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
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
                              final type = item['type'];

                              IconData chipIcon = Icons.location_on_rounded;
                              Color chipBg = const Color(0xFFFFF3E8);
                              Color chipIconColor = const Color(0xFFF97316);

                              if (type == 'home') {
                                chipIcon = Icons.home_rounded;
                                chipBg = const Color(0xFFE6F7F2);
                                chipIconColor = const Color(0xFF0F9B6E);
                              } else if (type == 'office') {
                                chipIcon = Icons.business_rounded;
                                chipBg = const Color(0xFFE8F0FB);
                                chipIconColor = const Color(0xFF1A3D6B);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pickupController.text = 'Current Location';
                                      _dropController.text = item['address'] ?? '';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Route set to ${item['title']}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: chipBg,
                                      border: Border.all(color: chipIconColor.withOpacity(0.15)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(chipIcon, size: 14, color: chipIconColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          item['title'] ?? '',
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
