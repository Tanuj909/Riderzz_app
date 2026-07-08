import 'package:flutter/material.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Upcoming'];

  // Mock data for recent trips
  final trips = [
    {
      'date': 'Today, 2:40 PM',
      'id': 'HLR-88213',
      'earnings': '₹832',
      'route': 'Sector 18 → Bhiwadi Depot',
      'status': 'Completed',
      'statusColor': const Color(0xFF1C9A5B),
      'statusBg': const Color(0xFFE7F7EF),
    },
    {
      'date': 'Jul 3, 10:15 AM',
      'id': 'HLR-87990',
      'earnings': '₹1,240',
      'route': 'Sector 62 → Noida Warehouse',
      'status': 'Completed',
      'statusColor': const Color(0xFF1C9A5B),
      'statusBg': const Color(0xFFE7F7EF),
    },
    {
      'date': 'Jul 2, 8:30 PM',
      'id': 'HLR-87654',
      'earnings': '₹0',
      'route': 'Delhi Airport → Vasant Kunj',
      'status': 'Cancelled',
      'statusColor': const Color(0xFFD90429),
      'statusBg': const Color(0xFFFCF0DC), // Or red faint
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 20),
            child: Text(
              'Rides History',
              style: TextStyle(
                color: Color(0xFF121214),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          
          // Chips Row
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _filters.map((filter) {
                  final isActive = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF121214) : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isActive ? const Color(0xFF121214) : const Color(0xFFE1E1E6),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF6C6F79),
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Trip Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E1E6)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05121214), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: ID and Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trip['id'] as String,
                          style: const TextStyle(
                            color: Color(0xFF6C6F79),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: trip['status'] == 'Completed'
                                ? const Color(0xFFE7F7EF)
                                : const Color(0xFFFDEBEC),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: trip['status'] == 'Completed'
                                      ? const Color(0xFF1C9A5B)
                                      : const Color(0xFFD90429),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trip['status'] as String,
                                style: TextStyle(
                                  color: trip['status'] == 'Completed'
                                      ? const Color(0xFF1C9A5B)
                                      : const Color(0xFFD90429),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Route
                    Text(
                      trip['route'] as String,
                      style: const TextStyle(
                        color: Color(0xFF121214),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Date & Earnings
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF6C6F79),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: '${trip['date']} · '),
                          TextSpan(
                            text: trip['earnings'] as String,
                            style: const TextStyle(
                              color: Color(0xFF121214),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF121214),
                              side: const BorderSide(color: Color(0xFFE1E1E6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD90429),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
