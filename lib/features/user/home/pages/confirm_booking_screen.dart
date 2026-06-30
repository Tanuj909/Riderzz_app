import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/user/home/pages/finding_driver_screen.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const ConfirmBookingScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  String _selectedPaymentMethod = 'CASH'; // 'CASH' or 'WALLET'
  bool _isBookingInProgress = false;

  void _handleConfirmBooking(BuildContext context) async {
    setState(() {
      _isBookingInProgress = true;
    });

    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final pickupId = widget.bookingData['pickupAddressId'] as int;
    final dropId = widget.bookingData['dropAddressId'] as int;
    final weight = double.tryParse(widget.bookingData['weightKg']?.toString() ?? '10.0') ?? 10.0;

    final requestData = {
      'pickupAddressId': pickupId,
      'dropAddressId': dropId,
      'vehicleTypeId': vehicle.id,
      'parcelType': widget.bookingData['goodsType'] ?? 'OTHER',
      'goodsDescription': widget.bookingData['goodsDescription'] ?? '',
      'weightKg': weight,
      'paymentMode': _selectedPaymentMethod,
      'rainApplied': false,
      'trafficApplied': false,
      'nightChargeApplied': false,
      'promoCode': null,
      'estimatedDistanceKm': widget.bookingData['estimatedDistanceKm'] as double? ?? 0.0,
    };

    final bookingProvider = context.read<BookingProvider>();
    final result = await bookingProvider.createBooking(requestData);

    setState(() {
      _isBookingInProgress = false;
    });

    if (result != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FindingDriverScreen(
            booking: result,
            vehicleName: vehicle.name,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'Failed to create booking'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final pickupText = widget.bookingData['pickupAddressText'] as String;
    final dropText = widget.bookingData['dropAddressText'] as String;
    final finalFare = widget.bookingData['finalFare'] as double;
    final goodsType = widget.bookingData['goodsType'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2233), size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Route Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ROUTE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7785),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup Stop
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Column(
                                    children: [
                                      const SizedBox(height: 3), // Align visually with label
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F9B6E), // Green dot
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 1.5,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PICKUP',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6B7785),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          pickupText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1A2233),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Connecting line in between pickup and drop blocks
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: 10,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 1.5,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const SizedBox(height: 12), // Height of spacing between blocks
                                ],
                              ),
                            ),
                            // Drop Stop
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 3), // Align visually with label
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF97316), // Orange dot
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DROP',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6B7785),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        dropText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1A2233),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Goods, Vehicle, Total row Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryColumn('GOODS', goodsType),
                        _buildSummaryColumn('VEHICLE', vehicle.name),
                        _buildSummaryColumn('TOTAL', '₹${finalFare.toStringAsFixed(0)}', isPrice: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Selector Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethodOption(
                          value: 'WALLET',
                          title: 'Online Payment',
                          subtitle: 'UPI, Card, Net Banking',
                          icon: Icons.credit_card_rounded,
                        ),
                        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                        _buildPaymentMethodOption(
                          value: 'CASH',
                          title: 'Cash on Delivery',
                          subtitle: 'Pay driver directly',
                          icon: Icons.payments_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isBookingInProgress ? null : () => _handleConfirmBooking(context),
                child: _isBookingInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, {bool isPrice = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7785),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isPrice ? const Color(0xFF1A3D6B) : const Color(0xFF1A2233),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFB0B8C4),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3D6B),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF1A3D6B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2233),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7785),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
