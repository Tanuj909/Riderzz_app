import 'package:flutter/material.dart';

class UserBookingsPage extends StatelessWidget {
  const UserBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockBookings = [
      {
        'id': 'CS-98762',
        'date': '09 Jun 2026',
        'status': 'Completed',
        'vehicle': 'Mini Truck',
        'pickup': 'Connaught Place, New Delhi',
        'drop': 'Cyber Hub, Gurugram',
        'fare': '₹405',
        'color': const Color(0xFF0F9B6E),
      },
      {
        'id': 'CS-98610',
        'date': '06 Jun 2026',
        'status': 'Completed',
        'vehicle': 'Bike / Scooter',
        'pickup': 'DLF Phase 3, Gurugram',
        'drop': 'Golf Course Road, Gurugram',
        'fare': '₹85',
        'color': const Color(0xFF0F9B6E),
      },
      {
        'id': 'CS-98443',
        'date': '03 Jun 2026',
        'status': 'Cancelled',
        'vehicle': 'Large Truck',
        'pickup': 'Okhla Phase 3, New Delhi',
        'drop': 'Noida Sector 62, Noida',
        'fare': '₹1,250',
        'color': Colors.redAccent,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: mockBookings.length,
      itemBuilder: (context, index) {
        final booking = mockBookings[index];
        final isCompleted = booking['status'] == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9ECF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking['id'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3D6B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFE6F7F2) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      booking['status'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: booking['color'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(booking['date'], style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785))),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0F9B6E), shape: BoxShape.circle)),
                      Container(width: 1, height: 16, color: const Color(0xFFE9ECF0)),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking['pickup'], style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                        const SizedBox(height: 8),
                        Text(booking['drop'], style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking['fare'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2233)),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12, color: Color(0xFF1A3D6B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
