import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';

void showBookingDetailsBottomSheet(BuildContext context, BookingModel initialBooking) async {
  final bookingFuture = context.read<BookingProvider>().fetchBookingById(initialBooking.id);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      String? generatedOtp;
      bool otpLoading = false;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<BookingModel?>(
            future: bookingFuture,
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final booking = snapshot.data ?? initialBooking;

              final statusUpper = booking.status.toUpperCase();
              final isCompleted = statusUpper == 'DELIVERED' || statusUpper == 'COMPLETED';
              final isCancelled = statusUpper == 'CANCELLED';
              final isPending = statusUpper == 'PENDING';

              Color statusColor = const Color(0xFF2563EB); // Active
              Color statusBg = const Color(0xFFEFF6FF);
              String userStatusLabel = 'Active';

              if (isCompleted) {
                statusColor = const Color(0xFF16A34A);
                statusBg = const Color(0xFFF0FDF4);
                userStatusLabel = 'Delivered';
              } else if (isCancelled) {
                statusColor = const Color(0xFFDC2626);
                statusBg = const Color(0xFFFEF2F2);
                userStatusLabel = 'Cancelled';
              } else if (isPending) {
                statusColor = const Color(0xFFD97706);
                statusBg = const Color(0xFFFEF3C7);
                userStatusLabel = 'Pending';
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Details',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF121214)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.bookingId,
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userStatusLabel,
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE7E7EB)),
                      const SizedBox(height: 16),
                      Text('ROUTE DETAILS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1C9A5B), shape: BoxShape.circle)),
                              Container(width: 1.5, height: 44, color: const Color(0xFFE7E7EB)),
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB9700A), shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PICKUP', style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(booking.pickupAddressName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
                                const SizedBox(height: 14),
                                Text('DROP', style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(booking.dropAddressName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE7E7EB)),
                      const SizedBox(height: 16),
                      Text('SHIPMENT & PARCEL INFO', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile('Parcel Type', booking.parcelType, Icons.inventory_2_outlined),
                          ),
                          Expanded(
                            child: _buildDetailTile('Weight', '${booking.weightKg.toStringAsFixed(1)} KG', Icons.scale_outlined, inline: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        'Goods Description',
                        booking.goodsDescription.isNotEmpty ? booking.goodsDescription : 'No description provided',
                        Icons.description_outlined,
                      ),
                      if (booking.driver != null) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE7E7EB)),
                        const SizedBox(height: 16),
                        Text('DRIVER DETAILS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailTile('Driver Name', booking.driver!.fullName, Icons.person_outline_rounded),
                            ),
                            Expanded(
                              child: _buildDetailTile('Phone Number', booking.driver!.phone, Icons.phone_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailTile('License Number', booking.driver!.licenseNumber ?? 'N/A', Icons.badge_outlined),
                            ),
                            Expanded(
                              child: _buildDetailTile('Rating', '${booking.driver!.rating.toStringAsFixed(1)} ★', Icons.star_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE7E7EB)),
                      const SizedBox(height: 16),
                      Text('PAYMENT & FARE BREAKDOWN', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile('Payment Mode', booking.paymentMode, Icons.payment_rounded),
                          ),
                          Expanded(
                            child: _buildDetailTile('Estimated Fare', '₹${booking.totalFare.toStringAsFixed(2)}', Icons.calculate_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7E7EB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Charged Fare', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF121214))),
                            Text(
                              '₹${booking.totalFare.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE31C2E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (booking.status.toUpperCase() == 'DRIVER_ARRIVED') ...[
                        if (generatedOtp != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.vpn_key_rounded, color: Color(0xFF0D9488), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PICKUP OTP: $generatedOtp',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F766E),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share this OTP with your driver to start the ride.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF0D9488),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: otpLoading
                                  ? null
                                  : () async {
                                      setSheetState(() {
                                        otpLoading = true;
                                      });
                                      final bookingProvider = context.read<BookingProvider>();
                                      final otpData = await bookingProvider.fetchBookingOtp(booking.id);
                                      setSheetState(() {
                                        otpLoading = false;
                                        if (otpData != null) {
                                          generatedOtp = otpData['otp']?.toString();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(bookingProvider.errorMessage ?? 'Failed to generate OTP'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      });
                                    },
                              icon: otpLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.pin_rounded, color: Colors.white, size: 16),
                              label: Text(
                                'Generate Pickup OTP',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31C2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: Text('Dismiss', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildDetailTile(String label, String value, IconData icon, {bool inline = false}) {
  return Row(
    crossAxisAlignment: inline ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF6C6F79)),
      const SizedBox(width: 8),
      Expanded(
        child: inline
            ? Row(
                children: [
                  Text('$label: ', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6C6F79))),
                  Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF121214))),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6C6F79))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
                ],
              ),
      ),
    ],
  );
}
