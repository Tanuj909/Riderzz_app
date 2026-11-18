import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';

class DriverTripEarningsScreen extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onDismiss;

  const DriverTripEarningsScreen({
    super.key,
    required this.booking,
    this.onDismiss,
  });

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Just now';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[date.month - 1];
      final day = date.day;
      final year = date.year;
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $period';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalFare = booking.totalFare;
    final double? rawCommission = booking.commissionAmount;
    final double commission = (rawCommission != null && rawCommission > 0)
        ? rawCommission
        : (totalFare * 0.10);
    final double driverEarnings = (totalFare - commission).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip Summary',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (onDismiss != null) {
                        onDismiss!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF475569),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: [
                    // Receipt Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Receipt Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'COMPLETED',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF334155),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(booking.createdAt),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Hero Section: Driver Net Earnings
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              children: [
                                Text(
                                  'YOUR NET EARNINGS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${driverEarnings.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Amount credited after commission deduction',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Breakdown Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earnings Breakdown',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Row 1: Booking Total Fare
                                _buildBreakdownRow(
                                  label: 'Booking Total Fare',
                                  amount: '₹${totalFare.toStringAsFixed(2)}',
                                  isNeutral: true,
                                ),
                                const SizedBox(height: 10),

                                // Row 2: Commission Deduction
                                _buildBreakdownRow(
                                  label: 'Platform Commission (10%)',
                                  amount: '- ₹${commission.toStringAsFixed(2)}',
                                  isDeduction: true,
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                ),

                                // Row 3: Net Take-Home Earnings
                                _buildBreakdownRow(
                                  label: 'Your Earnings',
                                  amount: '₹${driverEarnings.toStringAsFixed(2)}',
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Trip Info (Simple, clean, no colorful icons)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Payment Method', booking.paymentMode.toUpperCase()),
                                if (booking.estimatedDistanceKm != null && booking.estimatedDistanceKm! > 0) ...[
                                  const SizedBox(height: 10),
                                  _buildInfoRow('Total Distance', '${booking.estimatedDistanceKm!.toStringAsFixed(1)} km'),
                                ],
                                const SizedBox(height: 10),
                                _buildInfoRow('Pickup', booking.pickupAddressName),
                                const SizedBox(height: 10),
                                _buildInfoRow('Drop', booking.dropAddressName),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Full-Width Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onDismiss != null) {
                      onDismiss!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String amount,
    bool isDeduction = false,
    bool isTotal = false,
    bool isNeutral = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal
                ? const Color(0xFF0F172A)
                : (isDeduction ? const Color(0xFFB91C1C) : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

