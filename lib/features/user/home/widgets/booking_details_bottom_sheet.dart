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
      return FutureBuilder<BookingModel?>(
        future: bookingFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final booking = snapshot.data ?? initialBooking;

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
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF121214)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${booking.bookingId}',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6C6F79)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: booking.status == 'COMPLETED'
                              ? const Color(0xFFE7F7EF)
                              : booking.status == 'CANCELLED'
                                  ? const Color(0xFFFDEBEC)
                                  : const Color(0xFFFDEBEC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.status,
                          style: GoogleFonts.poppins(
                            color: booking.status == 'COMPLETED'
                                ? const Color(0xFF1C9A5B)
                                : booking.status == 'CANCELLED'
                                    ? Colors.redAccent
                                    : const Color(0xFFE31C2E),
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
                  Text('ROUTE DETAILS', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
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
                            Text('PICKUP', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(booking.pickupAddressName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
                            const SizedBox(height: 14),
                            Text('DROP', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(booking.dropAddressName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE7E7EB)),
                  const SizedBox(height: 16),
                  Text('SHIPMENT & PARCEL INFO', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailTile('Parcel Type', booking.parcelType, Icons.inventory_2_outlined),
                      ),
                      Expanded(
                        child: _buildDetailTile('Weight', '${booking.weightKg.toStringAsFixed(1)} KG', Icons.scale_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    'Goods Description',
                    booking.goodsDescription.isNotEmpty ? booking.goodsDescription : 'No description provided',
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE7E7EB)),
                  const SizedBox(height: 16),
                  Text('PAYMENT & FARE BREAKDOWN', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C6F79), letterSpacing: 0.5)),
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
                        Text('Total Charged Fare', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF121214))),
                        Text(
                          '₹${booking.totalFare.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE31C2E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      child: Text('Dismiss', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailTile(String label, String value, IconData icon) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF6C6F79)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6C6F79))),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF121214))),
          ],
        ),
      ),
    ],
  );
}
