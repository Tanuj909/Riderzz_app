import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/home/pages/user_home_page.dart';
import 'package:riderzz_app/features/user/home/pages/choose_vehicle_screen.dart';
import 'package:riderzz_app/features/user/home/pages/fare_estimate_screen.dart';
import 'package:riderzz_app/features/user/home/pages/confirm_booking_screen.dart';
import 'package:riderzz_app/features/user/home/pages/finding_driver_screen.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/pages/pickup_details_view.dart';

class BookingFlowBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialRoute;
  final VoidCallback onBookingConfirmed;

  const BookingFlowBottomSheet({
    super.key,
    this.initialRoute,
    required this.onBookingConfirmed,
  });

  @override
  State<BookingFlowBottomSheet> createState() => _BookingFlowBottomSheetState();
}

class _BookingFlowBottomSheetState extends State<BookingFlowBottomSheet> {
  int _currentStep = 0;
  Map<String, dynamic> _bookingData = {};

  final List<String> _tabs = [
    'Choose a vehicle',
    'Fare estimate',
    'Confirm booking',
  ];

  void _nextStep(Map<String, dynamic> updatedData) {
    setState(() {
      _bookingData = updatedData;
      if (_currentStep < 3) {
        _currentStep++;
      }
    });
  }

  void _onConfirm(BookingModel result) {
    widget.onBookingConfirmed();
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindingDriverScreen(
          booking: result,
          vehicleName: _bookingData['vehicleType']?.name ?? '',
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    if (_currentStep == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: 26, bottom: 14),
        child: Center(
          child: Text(
            'Pickup details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121214),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 14, left: 16, right: 16),
          child: Center(
            child: Text(
              _tabs[_currentStep - 1],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF121214),
              ),
            ),
          ),
        ),
        // Stepper
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isDone = index < (_currentStep - 1);
              final isActive = index == (_currentStep - 1);
              
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFFE31C2E) 
                        : (isDone ? const Color(0xFFE31C2E).withValues(alpha: 0.5) : const Color(0xFFFDEBEC)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle and header
          Stack(
            children: [
              _buildStepHeader(),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F6F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6C6F79)),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return PickupDetailsView(
          key: const ValueKey(0),
          initialRoute: widget.initialRoute,
          initialData: _bookingData,
          onContinue: _nextStep,
        );
      case 1:
        return ChooseVehicleView(
          key: const ValueKey(1),
          bookingData: _bookingData,
          onNext: _nextStep,
          onBack: () => setState(() => _currentStep--),
        );
      case 2:
        return FareEstimateView(
          key: const ValueKey(2),
          bookingData: _bookingData,
          onNext: _nextStep,
          onBack: () => setState(() => _currentStep--),
        );
      case 3:
        return ConfirmBookingView(
          key: const ValueKey(3),
          bookingData: _bookingData,
          onConfirm: _onConfirm,
          onBack: () => setState(() => _currentStep--),
        );
      default:
        return const SizedBox();
    }
  }
}
