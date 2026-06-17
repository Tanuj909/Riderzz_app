import 'package:flutter/material.dart';

class DriverHistoryPage extends StatelessWidget {
  const DriverHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for recent trips
    final trips = [
      {
        'date': 'Today, 2:15 PM',
        'id': '#TXN-847291',
        'earnings': '₹280.00',
        'pickup': 'Hauz Khas, New Delhi',
        'dropoff': 'Connaught Place, New Delhi',
        'status': 'COMPLETED',
        'statusColor': const Color(0xFF0F9B6E),
        'statusBg': const Color(0xFFE6F7F2),
        'distance': '12.4 km • 34 mins',
        'category': 'Sedan',
      },
      {
        'date': 'Yesterday, 6:30 PM',
        'id': '#TXN-845102',
        'earnings': '₹190.50',
        'pickup': 'Indira Gandhi Airport (T3)',
        'dropoff': 'Dwarka Sector 10, New Delhi',
        'status': 'COMPLETED',
        'statusColor': const Color(0xFF0F9B6E),
        'statusBg': const Color(0xFFE6F7F2),
        'distance': '8.2 km • 22 mins',
        'category': 'Mini',
      },
      {
        'date': '15 Jun, 11:20 AM',
        'id': '#TXN-843019',
        'earnings': '₹540.00',
        'pickup': 'Noida Sector 62',
        'dropoff': 'Gurugram Phase 3, Haryana',
        'status': 'COMPLETED',
        'statusColor': const Color(0xFF0F9B6E),
        'statusBg': const Color(0xFFE6F7F2),
        'distance': '28.1 km • 65 mins',
        'category': 'SUV',
      },
      {
        'date': '14 Jun, 3:15 PM',
        'id': '#TXN-841920',
        'earnings': '₹0.00',
        'pickup': 'Saket District Centre',
        'dropoff': 'Malviya Nagar, New Delhi',
        'status': 'CANCELLED',
        'statusColor': Colors.redAccent,
        'statusBg': const Color(0xFFFEF2F2),
        'distance': '3.1 km • Cancelled by user',
        'category': 'Mini',
      },
      {
        'date': '12 Jun, 9:45 AM',
        'id': '#TXN-839088',
        'earnings': '₹230.00',
        'pickup': 'Rajouri Garden, New Delhi',
        'dropoff': 'Karol Bagh Market, New Delhi',
        'status': 'COMPLETED',
        'statusColor': const Color(0xFF0F9B6E),
        'statusBg': const Color(0xFFE6F7F2),
        'distance': '9.8 km • 28 mins',
        'category': 'Mini',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9ECF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['id'] as String,
                        style: const TextStyle(
                          color: Color(0xFF1A2233),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip['date'] as String,
                        style: const TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: trip['statusBg'] as Color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trip['status'] as String,
                      style: TextStyle(
                        color: trip['statusColor'] as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE9ECF0), height: 1),
              const SizedBox(height: 14),
              
              // Pickup & Dropoff indicators (Timeline style)
              Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF1A3D6B), size: 16),
                      Container(width: 2, height: 20, color: const Color(0xFFE9ECF0)),
                      const Icon(Icons.location_on_rounded, color: Color(0xFF0F9B6E), size: 16),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip['pickup'] as String,
                          style: const TextStyle(
                            color: Color(0xFF1A2233),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          trip['dropoff'] as String,
                          style: const TextStyle(
                            color: Color(0xFF1A2233),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE9ECF0), height: 1),
              const SizedBox(height: 12),
              
              // Bottom row: Distance details & Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE9ECF0)),
                        ),
                        child: Text(
                          trip['category'] as String,
                          style: const TextStyle(color: Color(0xFF6B7785), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip['distance'] as String,
                        style: const TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    trip['earnings'] as String,
                    style: const TextStyle(
                      color: Color(0xFF1A2233),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
