import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';

class ConfirmBookingView extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Function(BookingModel) onConfirm;
  final VoidCallback onBack;

  const ConfirmBookingView({
    super.key,
    required this.bookingData,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<ConfirmBookingView> createState() => _ConfirmBookingViewState();
}

class _ConfirmBookingViewState extends State<ConfirmBookingView> {
  String _selectedPaymentMethod = 'CASH'; // 'CASH' or 'WALLET'
  bool _isBookingInProgress = false;

  void _handleConfirmBooking(BuildContext context) async {
    setState(() {
      _isBookingInProgress = true;
    });

    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final pickupId = widget.bookingData['pickupAddressId'] as int;
    final dropId = widget.bookingData['dropAddressId'] as int;
    double weight = 10.0;
    final wStr = widget.bookingData['weightKg']?.toString().toLowerCase() ?? '';
    if (wStr.contains('0-5')) weight = 5.0;
    else if (wStr.contains('5-10')) weight = 10.0;
    else if (wStr.contains('10-50')) weight = 50.0;
    else if (wStr.contains('50-200')) weight = 200.0;
    else if (wStr.contains('200-500')) weight = 500.0;
    else if (wStr.contains('500+')) weight = 1000.0;
    else weight = double.tryParse(wStr) ?? 10.0;

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
      widget.onConfirm(result);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create booking')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData['vehicleType'] as VehicleTypeModel;
    final String pickupText = widget.bookingData['pickupAddressText'] as String? ?? 'Pickup Location';
    final String dropText = widget.bookingData['dropAddressText'] as String? ?? 'Drop Location';
    final double finalFare = widget.bookingData['finalFare'] as double? ?? 0.0;
    final String goodsType = widget.bookingData['goodsType'] as String? ?? 'OTHER';
    final int estimatedTime = widget.bookingData['estimatedTimeMin'] as int? ?? 0;

    return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Layout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Booking summary',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C6F79),
                                letterSpacing: 1.0,
                                textBaseline: TextBaseline.alphabetic,
                              ),
                            ),
                            Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: Color(0xFF6C6F79),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Pickup Stop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 10),
                              child: Icon(
                                Icons.circle_outlined,
                                size: 16,
                                color: const Color(0xFFE31C2E), // --red
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pickupText,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF121214),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pickup · Goods Type: $goodsType',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF6C6F79),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Dashed connecting line
                        Container(
                          height: 16,
                          margin: const EdgeInsets.only(left: 7),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Color(0xFFE7E7EB),
                                width: 2,
                                style: BorderStyle.solid, // Flutter dashed border requires custom painter, solid is fallback
                              ),
                            ),
                          ),
                        ),
                        // Drop Stop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 10),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: Color(0xFF121214),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dropText,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF121214),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Drop · Est. Time: $estimatedTime min',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF6C6F79),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7EB)), // Dashed equivalent
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total payable',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6C6F79),
                              ),
                            ),
                            Text(
                              '₹${finalFare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method Selector Card
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C6F79),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  _buildPaymentMethodOption(
                    value: 'WALLET',
                    title: 'Online Payment (Wallet, UPI)',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _buildPaymentMethodOption(
                    value: 'CASH',
                    title: 'Cash on delivery',
                    icon: Icons.money_rounded,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF121214)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31C2E), // var(--red)
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
          ),
        ],
      );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDEBEC) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFA2A5AE),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE31C2E),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Icon(icon, color: const Color(0xFF121214), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF121214),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
