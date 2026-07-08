import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';

class FindingDriverScreen extends StatefulWidget {
  final BookingModel booking;
  final String vehicleName;

  const FindingDriverScreen({
    Key? key,
    required this.booking,
    required this.vehicleName,
  }) : super(key: key);

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelBooking() async {
    setState(() {
      _isCancelling = true;
    });

    final bookingProvider = context.read<BookingProvider>();
    final success = await bookingProvider.cancelBooking(widget.booking.id, "Changed my mind");

    if (mounted) {
      setState(() {
        _isCancelling = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Failed to cancel booking'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF121214), size: 20),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Pulsing Animation Circle (Radar)
              SizedBox(
                height: 180,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final val = _animationController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120 + (60 * val),
                            height: 120 + (60 * val),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE31C2E).withOpacity(0.04 * (1.0 - val)),
                                width: 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 90 + (40 * val),
                            height: 90 + (40 * val),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE31C2E).withOpacity(0.08 * (1.0 - val)),
                                width: 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 70 + (20 * val),
                            height: 70 + (20 * val),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE31C2E).withOpacity(0.15 * (1.0 - val)),
                                width: 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF121214), // var(--black)
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33121214),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              const Text(
                'Finding nearby drivers…',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121214),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Matching you with the best ${widget.vehicleName} driver nearby',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6F79),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),

              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E7EB)), // var(--border)
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Booking ref', widget.booking.bookingId),
                    const SizedBox(height: 12),
                    _buildDetailRow('Vehicle', widget.vehicleName),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Est. Fare',
                      '₹${widget.booking.totalFare.toStringAsFixed(2)}',
                      isMono: true,
                    ),
                  ],
                ),
              ),
              
              // Cancel booking button
              _isCancelling
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14.0),
                        child: SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _handleCancelBooking,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE31C2E), // var(--red)
                          side: const BorderSide(color: Color(0xFFE31C2E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel booking',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
    bool isMono = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C6F79),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF121214),
            fontFamily: isMono ? 'Menlo' : null,
          ),
        ),
      ],
    );
  }
}
