import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCancelling = false;
  Timer? _statusTimer;
  late BookingModel _currentBooking;
  String? _generatedOtp;
  bool _otpLoading = false;
  bool _hasShownRatingDialog = false;

  GoogleMapController? _mapController;
  List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  bool _isRouteLoading = false;
  bool _isSheetExpanded = true;

  Timer? _driverLocationTimer;
  LatLng? _driverLocation;
  String? _driverName;
  String? _vehicleNumber;
  BitmapDescriptor? _driverIconDescriptor;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomMarkerIcon();
    });
    _startPolling();
    if (_currentBooking.routePolyline != null &&
        _currentBooking.routePolyline!.isNotEmpty) {
      _fetchRoute();
    }
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/icons/driver_icon.png',
      );
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 60,
        targetHeight: 60,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData = await fi.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null && mounted) {
        setState(() {
          _driverIconDescriptor = BitmapDescriptor.bytes(
            byteData.buffer.asUint8List(),
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to load custom driver icon: $e');
    }
  }

  void _showRatingDialog() {
    int selectedStars = 5;
    final reviewController = TextEditingController();
    bool isSubmitting = false;
    final bookingProvider = context.read<BookingProvider>();
    final navState = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB000),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Rate Your Ride',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF121214),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'How was your delivery partner ${_currentBooking.driver?.fullName ?? "Driver"}?',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6C6F79),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Star Rating selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          final isSelected = starValue <= selectedStars;
                          return GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      selectedStars = starValue;
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: isSelected
                                    ? const Color(0xFFFFB000)
                                    : const Color(0xFFE2E8F0),
                                size: 38,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Review Comment box
                      TextField(
                        controller: reviewController,
                        maxLines: 3,
                        enabled: !isSubmitting,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF121214),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your feedback (optional)...',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFA2A5AE),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE31C2E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action buttons
                      Row(
                        children: [
                          // Close option
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                      navState.pop();
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6C6F79),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Submit option
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isSubmitting = true;
                                      });

                                      final success = await bookingProvider
                                          .submitRating(
                                            bookingId: _currentBooking.id,
                                            ratingType: 'CUSTOMER_TO_DRIVER',
                                            stars: selectedStars,
                                            review:
                                                reviewController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? reviewController.text.trim()
                                                : 'Ride was smooth.',
                                          );

                                      if (success) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Rating submitted successfully',
                                            ),
                                          ),
                                        );
                                        Navigator.pop(dialogContext);
                                        navState.pop();
                                      } else {
                                        setDialogState(() {
                                          isSubmitting = false;
                                        });
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              bookingProvider.errorMessage ??
                                                  'Failed to submit rating',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31C2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Submit',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      final bookingProvider = context.read<BookingProvider>();
      final freshBooking = await bookingProvider.fetchBookingById(
        _currentBooking.id,
      );
      if (freshBooking != null && mounted) {
        setState(() {
          _currentBooking = freshBooking;
        });

        if (freshBooking.routePolyline != null &&
            _polylineCoordinates.isEmpty) {
          _fetchRoute();
        }

        // Start location tracking if driver is assigned and timer is not running
        final driverId = freshBooking.driverId ?? freshBooking.driver?.userId;
        if (driverId != null && _driverLocationTimer == null) {
          _startDriverLocationTracking(driverId);
        }

        // Stop polling if booking is finalized
        final statusLower = freshBooking.status.toLowerCase();
        if (statusLower == 'cancelled' ||
            statusLower == 'delivered' ||
            statusLower == 'completed') {
          timer.cancel();
          _driverLocationTimer?.cancel();
        }
      }
    });

    // Check on startup if driver is already assigned
    final initialDriverId =
        _currentBooking.driverId ?? _currentBooking.driver?.userId;
    if (initialDriverId != null) {
      _startDriverLocationTracking(initialDriverId);
    }
  }

  void _startDriverLocationTracking(int driverId) {
    _driverLocationTimer?.cancel();

    // Fetch immediately on start, then every 5 seconds
    _fetchAndUpdateDriverLocation(driverId);

    _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (!mounted) return;
      _fetchAndUpdateDriverLocation(driverId);
    });
  }

  Future<void> _fetchAndUpdateDriverLocation(int driverId) async {
    final bookingProvider = context.read<BookingProvider>();
    final loc = await bookingProvider.fetchDriverLocation(driverId);
    if (loc != null && mounted) {
      setState(() {
        _driverLocation = LatLng(loc.latitude, loc.longitude);
        if (loc.driverName != null) _driverName = loc.driverName;
        if (loc.vehicleNumber != null) _vehicleNumber = loc.vehicleNumber;
      });

      // Animate camera to follow driver when map is visible
      if (!_isSheetExpanded &&
          _mapController != null &&
          _driverLocation != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_driverLocation!));
      }
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _driverLocationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelBooking() async {
    setState(() {
      _isCancelling = true;
    });

    final bookingProvider = context.read<BookingProvider>();
    final success = await bookingProvider.cancelBooking(
      _currentBooking.id,
      "Changed my mind",
    );

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
            content: Text(
              bookingProvider.errorMessage ?? 'Failed to cancel booking',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  Future<void> _handleGenerateOtp() async {
    setState(() {
      _otpLoading = true;
    });

    final bookingProvider = context.read<BookingProvider>();
    final otpData = await bookingProvider.fetchBookingOtp(_currentBooking.id);

    if (mounted) {
      setState(() {
        _otpLoading = false;
        if (otpData != null) {
          _generatedOtp = otpData['otp']?.toString();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookingProvider.errorMessage ?? 'Failed to generate OTP',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchRoute() async {
    final encodedPolyline = _currentBooking.routePolyline;
    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      return;
    }

    setState(() {
      _isRouteLoading = true;
    });

    try {
      final decoded = decodePolyline(encodedPolyline);
      if (decoded.isNotEmpty) {
        _polylineCoordinates = decoded
            .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _polylineCoordinates,
              color: const Color(0xFF8A0000),
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );

          final pickupLat = _currentBooking.pickupLatitude;
          final pickupLng = _currentBooking.pickupLongitude;
          final dropLat = _currentBooking.dropLatitude;
          final dropLng = _currentBooking.dropLongitude;

          if (pickupLat != null && pickupLng != null) {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('pickup_conn'),
                points: [
                  LatLng(pickupLat, pickupLng),
                  _polylineCoordinates.first,
                ],
                color: const Color(0xFF8A0000),
                width: 4,
                patterns: <PatternItem>[
                  PatternItem.dash(10),
                  PatternItem.gap(10),
                ],
              ),
            );
          }

          if (dropLat != null && dropLng != null) {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('drop_conn'),
                points: [_polylineCoordinates.last, LatLng(dropLat, dropLng)],
                color: const Color(0xFF8A0000),
                width: 4,
                patterns: <PatternItem>[
                  PatternItem.dash(10),
                  PatternItem.gap(10),
                ],
              ),
            );
          }
        });

        if (_mapController != null) {
          _fitMapBounds();
        }
      }
    } catch (e) {
      debugPrint('Error decoding route polyline: $e');
    } finally {
      setState(() {
        _isRouteLoading = false;
      });
    }
  }

  void _fitMapBounds() {
    if (_mapController == null || _polylineCoordinates.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final point in _polylineCoordinates) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusUpper = _currentBooking.status.toUpperCase();
    if ((statusUpper == 'DELIVERED' || statusUpper == 'COMPLETED') &&
        !_hasShownRatingDialog) {
      _hasShownRatingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRatingDialog();
      });
    }

    final isDriverAssigned =
        _currentBooking.driver != null ||
        _currentBooking.status.toUpperCase() == 'DRIVER_ASSIGNED' ||
        _currentBooking.status.toUpperCase() == 'ACCEPTED' ||
        _currentBooking.status.toUpperCase() == 'EN_ROUTE' ||
        _currentBooking.status.toUpperCase() == 'DRIVER_ARRIVED' ||
        _currentBooking.status.toUpperCase() == 'IN_TRANSIT';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isDriverAssigned
          ? null
          : AppBar(
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF121214),
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ),
      body: isDriverAssigned
          ? Stack(
              children: [
                // Full Background Google Map
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: (_polylineCoordinates.isNotEmpty)
                          ? _polylineCoordinates.first
                          : (_currentBooking.pickupLatitude != null &&
                                _currentBooking.pickupLongitude != null)
                          ? LatLng(
                              _currentBooking.pickupLatitude!,
                              _currentBooking.pickupLongitude!,
                            )
                          : const LatLng(28.6139, 77.2090),
                      zoom: 15.5,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_polylineCoordinates.isNotEmpty) {
                        _fitMapBounds();
                      }
                    },
                    markers: {
                      if (_currentBooking.pickupLatitude != null &&
                          _currentBooking.pickupLongitude != null)
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: LatLng(
                            _currentBooking.pickupLatitude!,
                            _currentBooking.pickupLongitude!,
                          ),
                          infoWindow: const InfoWindow(
                            title: 'Pickup Location',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      if (_currentBooking.dropLatitude != null &&
                          _currentBooking.dropLongitude != null)
                        Marker(
                          markerId: const MarkerId('drop'),
                          position: LatLng(
                            _currentBooking.dropLatitude!,
                            _currentBooking.dropLongitude!,
                          ),
                          infoWindow: const InfoWindow(title: 'Drop Location'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      if (_driverLocation != null)
                        Marker(
                          markerId: const MarkerId('driver_location'),
                          position: _driverLocation!,
                          infoWindow: InfoWindow(
                            title: _driverName ?? 'Driver',
                            snippet: _vehicleNumber ?? 'Vehicle',
                          ),
                          icon:
                              _driverIconDescriptor ??
                              BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                        ),
                    },
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // Floating Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE1E1E6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF121214),
                      ),
                    ),
                  ),
                ),

                // Bottom Details Sheet Content
                if (_isSheetExpanded)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 30,
                            offset: Offset(0, -10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Center Drag Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1E1E6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              // Track Delivery Heading & View Map option
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Track Driver',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF121214),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isSheetExpanded = false;
                                      });
                                      // Animate camera to driver location when viewing map
                                      if (_driverLocation != null &&
                                          _mapController != null) {
                                        _mapController!.animateCamera(
                                          CameraUpdate.newLatLng(
                                            _driverLocation!,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.map_rounded,
                                      size: 16,
                                      color: Color(0xFFD90429),
                                    ),
                                    label: Text(
                                      'View Map',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFD90429),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Shipment Shutter Driver Card
                              if (_currentBooking.driver != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE1E1E6),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x05121214),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF121214),
                                              Color(0xFF3A3B41),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _currentBooking
                                                  .driver!
                                                  .fullName
                                                  .isNotEmpty
                                              ? _currentBooking
                                                    .driver!
                                                    .fullName[0]
                                                    .toUpperCase()
                                              : 'D',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentBooking.driver!.fullName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF121214),
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Phone: ${_currentBooking.driver!.phone}',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121214),
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_currentBooking.driver!.licenseNumber ?? 'N/A'} · ${widget.vehicleName} ★${_currentBooking.driver!.rating.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6C6F79),
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _makeCall(
                                          _currentBooking.driver!.phone,
                                        ),
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF1F1F4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.phone_in_talk_rounded,
                                            color: Color(0xFF121214),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Trip Progress Track (Status-based Progress timeline)
                              _buildProgressSection(_currentBooking.status),

                              // Generate OTP / Display OTP section
                              if (_currentBooking.status.toUpperCase() ==
                                  'DRIVER_ARRIVED') ...[
                                const SizedBox(height: 16),
                                if (_generatedOtp != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF99F6E4),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.vpn_key_rounded,
                                              color: Color(0xFF0D9488),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'PICKUP OTP: $_generatedOtp',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F766E),
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Share this OTP with your driver to start the ride.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0D9488),
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
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: _otpLoading
                                          ? null
                                          : _handleGenerateOtp,
                                      icon: _otpLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.pin_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                      label: const Text(
                                        'Get OTP',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE31C2E,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 16),

                              // 1. Summary details card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE1E1E6),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      'Booking ref',
                                      _currentBooking.bookingId,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                      'Vehicle',
                                      widget.vehicleName,
                                    ),
                                    if (_currentBooking.estimatedDistanceKm !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        'Est. Distance',
                                        '${_currentBooking.estimatedDistanceKm!.toStringAsFixed(1)} km',
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                      'Est. Fare',
                                      '₹${_currentBooking.totalFare.toStringAsFixed(2)}',
                                      isMono: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Pickup & Drop address dot-timeline card
                              _buildRouteAddressesCard(_currentBooking),
                              const SizedBox(height: 16),

                              // 3. Shipment Details Card
                              _buildShipmentDetailsCard(_currentBooking),
                              const SizedBox(height: 24),

                              // Cancel/Dismiss button
                              if (_currentBooking.status.toUpperCase() !=
                                      'CANCELLED' &&
                                  _currentBooking.status.toUpperCase() !=
                                      'DELIVERED' &&
                                  _currentBooking.status.toUpperCase() !=
                                      'COMPLETED') ...[
                                if (_isCancelling)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(14.0),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFFE31C2E),
                                              ),
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: _handleCancelBooking,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFE31C2E,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE31C2E),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
                                  const SizedBox(height: 12),
                                ],
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.popUntil(
                                      context,
                                      (route) => route.isFirst,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF121214),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Go to Dashboard',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSheetExpanded = true;
                          });
                          Future.delayed(const Duration(milliseconds: 50), () {
                            if (mounted) {
                              _fitMapBounds();
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'View Details',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121214),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
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
                                        color: const Color(
                                          0xFFE31C2E,
                                        ).withOpacity(0.04 * (1.0 - val)),
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
                                        color: const Color(
                                          0xFFE31C2E,
                                        ).withOpacity(0.08 * (1.0 - val)),
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
                                        color: const Color(
                                          0xFFE31C2E,
                                        ).withOpacity(0.15 * (1.0 - val)),
                                        width: 1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF121214),
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
                      const SizedBox(height: 40),
                      if (_isCancelling)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE31C2E),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _handleCancelBooking,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE31C2E),
                              side: const BorderSide(color: Color(0xFFE31C2E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
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
                      const SizedBox(height: 20),
                    ],
                  ),
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

  Widget _buildProgressSection(String status) {
    final statusUpper = status.toUpperCase();
    double progressPercent;
    String statusTitle;
    String statusDesc;

    switch (statusUpper) {
      case 'DRIVER_ASSIGNED':
      case 'ACCEPTED':
      case 'EN_ROUTE':
        progressPercent = 0.25;
        statusTitle = 'Driver Assigned';
        statusDesc = 'Driver is en route to pickup location';
        break;
      case 'DRIVER_ARRIVED':
        progressPercent = 0.50;
        statusTitle = 'Driver Arrived';
        statusDesc = 'Driver has arrived at pickup location';
        break;
      case 'IN_TRANSIT':
        progressPercent = 0.75;
        statusTitle = 'In Transit';
        statusDesc = 'Your parcel is on the way to drop location';
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        progressPercent = 1.0;
        statusTitle = 'Delivered';
        statusDesc = 'Parcel has been successfully delivered';
        break;
      default:
        progressPercent = 0.10;
        statusTitle = status;
        statusDesc = 'Processing your order';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E1E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusTitle,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF121214),
                ),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD90429),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusDesc,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF6C6F79),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F4),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progressPercent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D021F), Color(0xFFD90429)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAddressesCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              const Icon(Icons.circle, size: 10, color: Color(0xFF121214)),
              Container(width: 1.5, height: 40, color: const Color(0xFFE1E1E6)),
              const Icon(Icons.location_on, size: 12, color: Color(0xFFD90429)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.pickupAddressName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.dropAddressName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121214),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentDetailsCard(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SHIPMENT DETAILS',
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1E1E6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goods Type',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF6C6F79),
                    ),
                  ),
                  Text(
                    '${booking.parcelType} (${booking.weightKg} kg)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                ],
              ),
              if (booking.goodsDescription.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, color: Color(0xFFE1E1E6)),
                ),
                Text(
                  'Instructions',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6C6F79),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.goodsDescription,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: const Color(0xFF121214),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
