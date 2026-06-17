import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    
    final user = authProvider.currentUser;
    final profile = driverProvider.profile;

    final driverName = profile?.name ?? user?.name ?? 'Partner';
    final vehicleDetails = profile?.vehicle != null 
        ? '${profile!.vehicle!.make} ${profile.vehicle!.model}'
        : 'No vehicle details';
    final vehiclePlate = profile?.vehicleNumber ?? 'N/A';
    final isOnline = profile?.isOnline ?? false;
    final rating = profile?.rating ?? 5.0;
    final totalTrips = profile?.totalTrips ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Vehicle Details
          Text(
            'Welcome back, $driverName 👋',
            style: const TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (profile?.vehicle != null) ...[
            const SizedBox(height: 4),
            Text(
              '$vehicleDetails • $vehiclePlate',
              style: const TextStyle(
                color: Color(0xFF6B7785),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          // Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE9ECF0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Earnings',
                      style: TextStyle(
                        color: Color(0xFF6B7785),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '₹1,240.50',
                      style: TextStyle(
                        color: Color(0xFF1A2233),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE9ECF0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn('Today\'s Trips', '0'),
                    _buildStatColumn('Rating', '${rating.toStringAsFixed(1)} ★'),
                    _buildStatColumn('Total Trips', totalTrips.toString()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          // Section: Incoming Requests
          const Text(
            'Incoming Bookings',
            style: TextStyle(
              color: Color(0xFF1A2233),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9ECF0)),
            ),
            child: Text(
              isOnline 
                  ? 'No new ride requests in your area.'
                  : 'Go ONLINE to start receiving ride requests.',
              style: const TextStyle(
                color: Color(0xFF6B7785),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7785),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A2233),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
