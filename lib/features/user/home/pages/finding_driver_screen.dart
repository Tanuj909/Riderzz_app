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
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2233), size: 20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),
              
              // Pulsing Animation Circle
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final val = _animationController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140 + (60 * val),
                            height: 140 + (60 * val),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3D6B).withValues(alpha: 0.04 * (1.0 - val)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 90 + (50 * val),
                            height: 90 + (50 * val),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3D6B).withValues(alpha: 0.1 * (1.0 - val)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A3D6B),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x201A3D6B),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              Column(
                children: [
                  const Text(
                    'Finding Nearby Driver',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2233),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecting you with the best driver',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7785),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Animated dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final currentActive = (_animationController.value * 5).floor();
                          final isActive = index == currentActive;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF1A3D6B)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Booking ID', widget.booking.bookingId),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        _buildDetailRow('Vehicle Type', widget.vehicleName),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        _buildDetailRow(
                          'Total Fare',
                          '₹${widget.booking.totalFare.toStringAsFixed(1)}',
                          valueColor: const Color(0xFF1A3D6B),
                          isBoldValue: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cancel Search button
                  _isCancelling
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                          ),
                        )
                      : TextButton(
                          onPressed: _handleCancelBooking,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF97316),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Cancel Search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                ],
              ),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7785),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A2233),
          ),
        ),
      ],
    );
  }
}
