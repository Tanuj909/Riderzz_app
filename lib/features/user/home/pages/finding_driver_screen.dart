import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
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
    with TickerProviderStateMixin {
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

  double? _driverToPickupDistanceKm;
  int? _driverToPickupDurationMin;
  String? _driverToPickupPolyline;
  bool _isDriverRouteLoading = false;
  LatLng? _lastRouteFetchedDriverLocation;
  bool _hasInitialZoomedInOnDriver = false;

  // Variables for improved driver location tracking
  AnimationController? _markerAnimationController;
  LatLng? _previousLocation;
  LatLng? _targetLocation;
  double _driverBearing = 0.0;
  double _previousBearing = 0.0;
  double _targetBearing = 0.0;
  DateTime? _lastSuccessfulFetchTime;
  DateTime? _lastDriverLocationUpdatedAt;
  bool _isFetchingDriverLocation = false;
  bool _isCameraMoving = false;
  bool _isDriverLocationStaleState = false;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // 1.8 seconds (Task 6)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomMarkerIcon();
    });
    _startPolling();
    final statusUpper = _currentBooking.status.toUpperCase();
    final isPreTransit = statusUpper == 'DRIVER_ASSIGNED' ||
        statusUpper == 'ACCEPTED' ||
        statusUpper == 'EN_ROUTE' ||
        statusUpper == 'DRIVER_ARRIVED';

    if (!isPreTransit) {
      if (_currentBooking.routePolyline != null &&
          _currentBooking.routePolyline!.isNotEmpty) {
        _fetchRoute();
      }
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
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (!mounted) return;
      final bookingProvider = context.read<BookingProvider>();
      final freshBooking = await bookingProvider.fetchBookingById(
        _currentBooking.id,
      );
      if (freshBooking != null && mounted) {
        final oldStatus = _currentBooking.status.toUpperCase();
        final newStatus = freshBooking.status.toUpperCase();
        final isOldPreTransit = oldStatus == 'DRIVER_ASSIGNED' ||
            oldStatus == 'ACCEPTED' ||
            oldStatus == 'EN_ROUTE' ||
            oldStatus == 'DRIVER_ARRIVED';
        final isNewPreTransit = newStatus == 'DRIVER_ASSIGNED' ||
            newStatus == 'ACCEPTED' ||
            newStatus == 'EN_ROUTE' ||
            newStatus == 'DRIVER_ARRIVED';

        if (isOldPreTransit && !isNewPreTransit) {
          _hasInitialZoomedInOnDriver = false;
        }

        setState(() {
          _currentBooking = freshBooking;
        });
        if (!isNewPreTransit) {
          if (freshBooking.routePolyline != null &&
              (_polylineCoordinates.isEmpty ||
                  _polylines.any((p) => p.polylineId.value == 'driver_to_pickup_route'))) {
            _fetchRoute();
          }
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

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180.0;
    final double lon1 = start.longitude * math.pi / 180.0;
    final double lat2 = end.latitude * math.pi / 180.0;
    final double lon2 = end.longitude * math.pi / 180.0;

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    final double degrees = radians * 180.0 / math.pi;

    return (degrees + 360.0) % 360.0;
  }

  void _updateCameraIfNeeded(LatLng targetPos) async {
    if (!_hasInitialZoomedInOnDriver || _mapController == null || _isCameraMoving) {
      return;
    }

    _isCameraMoving = true;
    try {
      final bounds = await _mapController!.getVisibleRegion();
      
      final latRange = bounds.northeast.latitude - bounds.southwest.latitude;
      final lngRange = bounds.northeast.longitude - bounds.southwest.longitude;
      
      final paddingLat = latRange * 0.1;
      final paddingLng = lngRange * 0.1;
      
      final safeSouthwest = LatLng(
        bounds.southwest.latitude + paddingLat,
        bounds.southwest.longitude + paddingLng,
      );
      final safeNortheast = LatLng(
        bounds.northeast.latitude - paddingLat,
        bounds.northeast.longitude - paddingLng,
      );
      
      final safeBounds = LatLngBounds(southwest: safeSouthwest, northeast: safeNortheast);
      
      if (!safeBounds.contains(targetPos)) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(targetPos),
        );
      }
    } catch (e) {
      debugPrint('Error checking camera bounds: $e');
    } finally {
      _isCameraMoving = false;
    }
  }

  bool get _isDriverLocationStale {
    if (_lastSuccessfulFetchTime == null) return false;
    final now = DateTime.now();
    if (now.difference(_lastSuccessfulFetchTime!).inSeconds > 15) {
      return true;
    }
    if (_lastDriverLocationUpdatedAt != null) {
      final nowUtc = DateTime.now().toUtc();
      if (nowUtc.difference(_lastDriverLocationUpdatedAt!).inSeconds > 15) {
        return true;
      }
    }
    return false;
  }

  LatLng _getCurrentAnimatedLocation() {
    if (_previousLocation == null || _targetLocation == null) {
      return _driverLocation ?? const LatLng(0, 0);
    }
    if (_markerAnimationController == null || !_markerAnimationController!.isAnimating) {
      return _targetLocation!;
    }
    final t = _markerAnimationController!.value;
    final lat = _previousLocation!.latitude +
        (_targetLocation!.latitude - _previousLocation!.latitude) * t;
    final lng = _previousLocation!.longitude +
        (_targetLocation!.longitude - _previousLocation!.longitude) * t;
    return LatLng(lat, lng);
  }

  void _checkStaleness() {
    final currentlyStale = _isDriverLocationStale;
    if (_isDriverLocationStaleState != currentlyStale) {
      setState(() {
        _isDriverLocationStaleState = currentlyStale;
      });
    }
  }

  void _startDriverLocationTracking(int driverId) {
    _driverLocationTimer?.cancel();

    // Fetch immediately on start, then every 2 seconds
    _fetchAndUpdateDriverLocation(driverId);

    _driverLocationTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (!mounted) return;
      _fetchAndUpdateDriverLocation(driverId);
    });
  }

  Future<void> _fetchAndUpdateDriverLocation(int driverId) async {
    _checkStaleness();

    if (_isFetchingDriverLocation) return;
    _isFetchingDriverLocation = true;

    try {
      final bookingProvider = context.read<BookingProvider>();
      final loc = await bookingProvider.fetchDriverLocation(driverId);
      if (loc != null && mounted) {
        _lastSuccessfulFetchTime = DateTime.now();
        if (loc.updatedAt.isNotEmpty) {
          try {
            _lastDriverLocationUpdatedAt = DateTime.parse(loc.updatedAt).toUtc();
          } catch (_) {}
        }

        final newTarget = LatLng(loc.latitude, loc.longitude);

        // Skip duplicate coordinates completely (Task 3)
        if (_targetLocation != null &&
            _targetLocation!.latitude == newTarget.latitude &&
            _targetLocation!.longitude == newTarget.longitude) {
          _checkStaleness();
          return;
        }

        setState(() {
          if (loc.driverName != null) _driverName = loc.driverName;
          if (loc.vehicleNumber != null) _vehicleNumber = loc.vehicleNumber;
        });

        if (_driverLocation == null) {
          // First location update, snap directly
          setState(() {
            _driverLocation = newTarget;
            _previousLocation = newTarget;
            _targetLocation = newTarget;
            _driverBearing = 0.0;
            _previousBearing = 0.0;
            _targetBearing = 0.0;
          });
        } else {
          // Capture current animated position and animate toward target (Task 2)
          final currentPos = _getCurrentAnimatedLocation();
          _markerAnimationController?.stop(); // Stop current animation
          
          _previousLocation = currentPos; // Start animating from its current position
          _targetLocation = newTarget;
          
          // Calculate bearing only if moved at least 2 meters to avoid drift flickering (Task 4)
          final double distance = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            newTarget.latitude,
            newTarget.longitude,
          );
          
          if (distance >= 2.0) {
            final double bearing = _calculateBearing(currentPos, newTarget);
            _previousBearing = _driverBearing;
            _targetBearing = bearing;
          } else {
            _previousBearing = _driverBearing;
            _targetBearing = _driverBearing;
          }

          _markerAnimationController?.forward(from: 0.0);
        }

        // Camera follow update only on new location (Task 5)
        _updateCameraIfNeeded(newTarget);

        final statusUpper = _currentBooking.status.toUpperCase();
        final isPreTransit = statusUpper == 'DRIVER_ASSIGNED' ||
            statusUpper == 'ACCEPTED' ||
            statusUpper == 'EN_ROUTE' ||
            statusUpper == 'DRIVER_ARRIVED';

        if (isPreTransit) {
          bool shouldFetch = false;
          if (_lastRouteFetchedDriverLocation == null || _polylineCoordinates.isEmpty) {
            shouldFetch = true;
          } else {
            final double latDiff = (newTarget.latitude - _lastRouteFetchedDriverLocation!.latitude).abs();
            final double lngDiff = (newTarget.longitude - _lastRouteFetchedDriverLocation!.longitude).abs();
            if (latDiff > 0.0009 || lngDiff > 0.0009) {
              shouldFetch = true;
            }
          }

          if (shouldFetch) {
            _fetchDriverToPickupRoute();
          }
        }
        
        _checkStaleness();
      }
    } catch (e) {
      debugPrint('Error fetching driver location: $e');
      _checkStaleness();
    } finally {
      _isFetchingDriverLocation = false;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _driverLocationTimer?.cancel();
    _animationController.dispose();
    _markerAnimationController?.dispose();
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

  Future<void> _fetchDriverToPickupRoute() async {
    if (_driverLocation == null ||
        _currentBooking.pickupLatitude == null ||
        _currentBooking.pickupLongitude == null) {
      return;
    }

    final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (googleApiKey.isEmpty) return;

    setState(() {
      _isDriverRouteLoading = true;
    });

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        data: {
          "origin": {
            "location": {
              "latLng": {
                "latitude": _driverLocation!.latitude,
                "longitude": _driverLocation!.longitude,
              }
            }
          },
          "destination": {
            "location": {
              "latLng": {
                "latitude": _currentBooking.pickupLatitude!,
                "longitude": _currentBooking.pickupLongitude!,
              }
            }
          },
          "travelMode": "DRIVE",
          "routingPreference": "TRAFFIC_AWARE"
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': googleApiKey,
            'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final routes = response.data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first;
          final distanceMeters = route['distanceMeters'] as int?;
          final durationStr = route['duration'] as String?;
          final polylineStr = route['polyline']?['encodedPolyline'] as String?;

          double distanceKm = 0.0;
          if (distanceMeters != null) {
            distanceKm = (distanceMeters / 1000.0 * 100.0).round() / 100.0;
          }

          int durationMin = 0;
          if (durationStr != null) {
            final numericOnly = durationStr.replaceAll('s', '');
            final seconds = int.tryParse(numericOnly) ?? 0;
            durationMin = (seconds / 60.0).round();
          }

          if (mounted && polylineStr != null) {
            final decoded = decodePolyline(polylineStr);
            if (decoded.isNotEmpty) {
              setState(() {
                _lastRouteFetchedDriverLocation = _driverLocation;
                _driverToPickupDistanceKm = distanceKm;
                _driverToPickupDurationMin = durationMin;
                _driverToPickupPolyline = polylineStr;

                _polylineCoordinates = decoded
                    .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
                    .toList();

                _polylines.clear();
                _polylines.add(
                  Polyline(
                    polylineId: const PolylineId('driver_to_pickup_route'),
                    points: _polylineCoordinates,
                    color: Colors.blue,
                    width: 5,
                    jointType: JointType.round,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                  ),
                );

                _polylines.add(
                  Polyline(
                    polylineId: const PolylineId('pickup_conn'),
                    points: [
                      _polylineCoordinates.last,
                      LatLng(_currentBooking.pickupLatitude!, _currentBooking.pickupLongitude!),
                    ],
                    color: Colors.blueAccent,
                    width: 4,
                    patterns: <PatternItem>[
                      PatternItem.dash(10),
                      PatternItem.gap(10),
                    ],
                  ),
                );
              });

              if (_mapController != null) {
                _fitMapBounds();
                _triggerInitialZoomOnDriver();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver-to-pickup route: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDriverRouteLoading = false;
        });
      }
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
        setState(() {
          _polylines.clear();
          _polylineCoordinates = decoded
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

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
          _triggerInitialZoomOnDriver();
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
    if (_hasInitialZoomedInOnDriver) return;
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

  void _triggerInitialZoomOnDriver() {
    if (_hasInitialZoomedInOnDriver) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _mapController != null) {
        if (_driverLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _driverLocation!,
                zoom: 17.5,
              ),
            ),
          );
          setState(() {
            _hasInitialZoomedInOnDriver = true;
          });
        } else {
          // If driver location isn't fetched yet, try again in 1 second
          Future.delayed(const Duration(seconds: 1), () {
            _triggerInitialZoomOnDriver();
          });
        }
      }
    });
  }

  void _collapseSheetAndZoomOnDriver() {
    setState(() {
      _isSheetExpanded = false;
    });
    if (_driverLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _driverLocation!,
            zoom: 17.5,
          ),
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
                  child: AnimatedBuilder(
                    animation: _markerAnimationController ?? const AlwaysStoppedAnimation(0.0),
                    builder: (context, child) {
                      LatLng? displayLoc = _driverLocation;
                      double displayBearing = _driverBearing;

                      if (_previousLocation != null &&
                          _targetLocation != null &&
                          _markerAnimationController != null &&
                          _markerAnimationController!.isAnimating) {
                        final t = _markerAnimationController!.value;
                        final lat = _previousLocation!.latitude +
                            (_targetLocation!.latitude - _previousLocation!.latitude) * t;
                        final lng = _previousLocation!.longitude +
                            (_targetLocation!.longitude - _previousLocation!.longitude) * t;
                        displayLoc = LatLng(lat, lng);

                        // Interpolate bearing smoothly
                        double diff = _targetBearing - _previousBearing;
                        if (diff > 180) {
                          diff -= 360;
                        } else if (diff < -180) {
                          diff += 360;
                        }
                        displayBearing = (_previousBearing + diff * t + 360) % 360;

                        // Sync display back to driverLocation state so it can be accessed outside
                        _driverLocation = displayLoc;
                        _driverBearing = displayBearing;
                      }

                      return GoogleMap(
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
                          if (displayLoc != null)
                            Marker(
                              markerId: const MarkerId('driver_location'),
                              position: displayLoc,
                              rotation: displayBearing,
                              flat: true,
                              anchor: const Offset(0.5, 0.5),
                              infoWindow: InfoWindow(
                                title: _driverName ?? 'Driver',
                                snippet: _isDriverLocationStaleState
                                    ? '${_vehicleNumber ?? "Vehicle"} (Connection Lost)'
                                    : (_vehicleNumber ?? 'Vehicle'),
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
                      );
                    },
                  ),
                ),

                // Stale Location Banner Alert Overlay
                if (_isDriverLocationStaleState)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 72,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD90429).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Driver's GPS signal is weak. Reconnecting...",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSlide(
                    offset: _isSheetExpanded ? Offset.zero : const Offset(0, 1.2),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !_isSheetExpanded,
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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels <= 0 &&
                                  notification.scrollDelta != null &&
                                  notification.scrollDelta! < -5) {
                                _collapseSheetAndZoomOnDriver();
                              }
                            } else if (notification is OverscrollNotification) {
                              if (notification.overscroll < -5) {
                                _collapseSheetAndZoomOnDriver();
                              }
                            }
                            return false;
                          },
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
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragUpdate: (details) {
                                    if (details.delta.dy > 5) {
                                      _collapseSheetAndZoomOnDriver();
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE1E1E6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
                                      _collapseSheetAndZoomOnDriver();
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

                              // If driver is en route, show ETA banner
                              Builder(
                                builder: (context) {
                                  final statusUpper = _currentBooking.status.toUpperCase();
                                  final isPreTransit = statusUpper == 'DRIVER_ASSIGNED' ||
                                      statusUpper == 'ACCEPTED' ||
                                      statusUpper == 'EN_ROUTE' ||
                                      statusUpper == 'DRIVER_ARRIVED';
                                  if (isPreTransit && _driverToPickupDurationMin != null) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEBF5FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFC0E0FF)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.directions_bike_rounded, color: Colors.blue, size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Driver arriving in ${_driverToPickupDurationMin} min',
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: const Color(0xFF004085),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Distance to pickup: ${_driverToPickupDistanceKm?.toStringAsFixed(1)} km',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF004085),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),

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
                                              '${_vehicleNumber ?? _currentBooking.vehicleNumber ?? widget.vehicleName} · ★${_currentBooking.driver!.rating.toStringAsFixed(1)}',
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
                                      'Booking ID',
                                      _currentBooking.bookingId,
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
                                    Builder(
                                      builder: (context) {
                                        final statusUpper = _currentBooking.status.toUpperCase();
                                        final isPreTransit = statusUpper == 'DRIVER_ASSIGNED' ||
                                            statusUpper == 'ACCEPTED' ||
                                            statusUpper == 'EN_ROUTE' ||
                                            statusUpper == 'DRIVER_ARRIVED';
                                        if (isPreTransit && _driverToPickupDurationMin != null) {
                                          return Column(
                                            children: [
                                              const SizedBox(height: 12),
                                              _buildDetailRow(
                                                'Driver ETA',
                                                '${_driverToPickupDurationMin} mins',
                                              ),
                                              const SizedBox(height: 12),
                                              _buildDetailRow(
                                                'Distance to Pickup',
                                                '${_driverToPickupDistanceKm?.toStringAsFixed(1)} km',
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
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
                    ),
                  ),
                ),
              ),
                if (!_isSheetExpanded)
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

  // Ordered status list for continuous progress calculation
  static const List<String> _orderedStatuses = [
    'PENDING',
    'DRIVER_ASSIGNED',
    'EN_ROUTE',
    'DRIVER_ARRIVED',
    'IN_TRANSIT',
    'DELIVERED',
  ];

  Widget _buildProgressSection(String status) {
    final statusUpper = status.toUpperCase();
    String statusTitle;
    String statusDesc;

    // Map status to a continuous 0-100% scale
    int statusIndex = _orderedStatuses.indexOf(statusUpper);
    if (statusUpper == 'ACCEPTED') statusIndex = _orderedStatuses.indexOf('DRIVER_ASSIGNED');
    if (statusUpper == 'COMPLETED') statusIndex = _orderedStatuses.indexOf('DELIVERED');
    if (statusIndex < 0) statusIndex = 0;

    final double progressPercent = (statusIndex / (_orderedStatuses.length - 1)).clamp(0.0, 1.0);

    switch (statusUpper) {
      case 'DRIVER_ASSIGNED':
      case 'ACCEPTED':
      case 'EN_ROUTE':
        statusTitle = 'Driver Assigned';
        statusDesc = 'Driver is en route to pickup location';
        break;
      case 'DRIVER_ARRIVED':
        statusTitle = 'Driver Arrived';
        statusDesc = 'Driver has arrived at pickup location';
        break;
      case 'IN_TRANSIT':
        statusTitle = 'In Transit';
        statusDesc = 'Your parcel is on the way to drop location';
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        statusTitle = 'Delivered';
        statusDesc = 'Parcel has been successfully delivered';
        break;
      default:
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C9A5B),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                const Icon(Icons.location_on, size: 12, color: Color(0xFFD90429)),
                const SizedBox(height: 2),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    booking.pickupAddressName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Drop',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    booking.dropAddressName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
