import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'package:riderzz_app/core/services/maps_launcher_service.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverBookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const DriverBookingDetailsScreen({super.key, required this.booking});

  @override
  State<DriverBookingDetailsScreen> createState() =>
      _DriverBookingDetailsScreenState();
}

class _DriverBookingDetailsScreenState
    extends State<DriverBookingDetailsScreen> {
  GoogleMapController? _mapController;
  bool _isSheetExpanded = true;
  bool _isVerifyingOtp = false;
  String? _selectedPaymentMethod;
  bool _isDetailsExpanded = false;
  bool _hasStartedAutoPop = false;
  String? _localStatus;
  bool _wasAlreadyCompleted = false;
  bool _hasShownStatusDialog = false;

  final LatLng _defaultDelhi = const LatLng(28.6139, 77.2090);

  List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  bool _isRouteLoading = false;
  bool _isRouteDrawn = false;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  String? _routeDistanceText;
  String? _routeDurationText;

  late BookingModel _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    final initialStatus = _currentBooking.status.toUpperCase();
    _wasAlreadyCompleted =
        (initialStatus == 'DELIVERED' || initialStatus == 'COMPLETED');
    _loadMarkerIcons();
    _fetchRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchDriverProfile();
      _loadFreshBookingDetails();
      if (initialStatus == 'CANCELLED' || initialStatus == 'FAILED') {
        _showStatusModal(initialStatus);
      }
    });
  }

  Future<void> _loadFreshBookingDetails({bool force = false}) async {
    if (!force &&
        _currentBooking.routePolyline != null &&
        _currentBooking.routePolyline!.isNotEmpty &&
        _currentBooking.customer != null) {
      return;
    }
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/bookings/${widget.booking.id}');
      if (response.data != null && response.data['data'] != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data['data'],
        );
        final freshBooking = BookingModel.fromJson(data);
        if (mounted) {
          setState(() {
            _currentBooking = freshBooking;
          });
          _fetchRoute();
        }
      }
    } catch (e) {
      debugPrint('Error loading fresh booking details: $e');
    }
  }

  void _checkAndShowStatusDialog(String status) {
    if (_hasShownStatusDialog) return;
    if (status == 'CANCELLED' || status == 'FAILED') {
      _hasShownStatusDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStatusModal(status);
      });
    }
  }

  void _showStatusModal(String status) {
    final isCancelled = status == 'CANCELLED';
    final reason = widget.booking.goodsDescription.isNotEmpty
        ? widget.booking.goodsDescription
        : 'Customer changed mind';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : Icons.error_outline_rounded,
                    color: isCancelled
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFD97706),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isCancelled ? 'Booking Cancelled' : 'Booking Failed',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF121214),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isCancelled
                      ? 'This booking was cancelled.\nReason: $reason'
                      : 'Booking was failed!',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    color: const Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // close dialog
                      Navigator.pop(context); // pop details screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCancelled
                          ? const Color(0xFFCC2D3B)
                          : const Color(0xFF121214),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _loadMarkerIcons() async {
    try {
      final Uint8List markerBytes = await _getBytesFromAsset(
        'assets/icons/location.png',
        80,
      ); // 80 pixels width
      final icon = BitmapDescriptor.fromBytes(markerBytes);
      setState(() {
        _pickupIcon = icon;
        _dropIcon = icon;
      });
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
    }
  }

  Future<void> _fetchRoute() async {
    final encodedPolyline =
        _currentBooking.routePolyline ?? widget.booking.routePolyline;
    final distanceKm =
        _currentBooking.estimatedDistanceKm ??
        widget.booking.estimatedDistanceKm;

    if (distanceKm != null) {
      _routeDistanceText = '${distanceKm.toStringAsFixed(1)} km';
    }

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

          final pickupLat = widget.booking.pickupLatitude;
          final pickupLng = widget.booking.pickupLongitude;
          final dropLat = widget.booking.dropLatitude;
          final dropLng = widget.booking.dropLongitude;

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

          _isRouteDrawn = true;
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

  void _onViewRoutePressed() {
    if (_polylineCoordinates.isNotEmpty) {
      setState(() {
        _isRouteDrawn = !_isRouteDrawn;
        if (_isRouteDrawn) {
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

          final pickupLat =
              _currentBooking.pickupLatitude ?? widget.booking.pickupLatitude;
          final pickupLng =
              _currentBooking.pickupLongitude ?? widget.booking.pickupLongitude;
          final dropLat =
              _currentBooking.dropLatitude ?? widget.booking.dropLatitude;
          final dropLng =
              _currentBooking.dropLongitude ?? widget.booking.dropLongitude;

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

          _fitMapBounds();
        } else {
          _polylines.removeWhere(
            (p) =>
                p.polylineId.value == 'route' ||
                p.polylineId.value == 'pickup_conn' ||
                p.polylineId.value == 'drop_conn',
          );
        }
      });
    } else {
      _fetchRoute();
    }
  }

  Set<Marker> _buildMarkers(BookingModel booking) {
    final pickupLat = booking.pickupLatitude;
    final pickupLng = booking.pickupLongitude;
    final dropLat = booking.dropLatitude;
    final dropLng = booking.dropLongitude;

    final markers = <Marker>{};

    if (pickupLat != null && pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon:
              _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    if (dropLat != null && dropLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(dropLat, dropLng),
          infoWindow: const InfoWindow(title: 'Drop Location'),
          icon:
              _dropIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    return markers;
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

  void _showCallModal() {
    final driverProvider = Provider.of<DriverHomeProvider>(
      context,
      listen: false,
    );
    final booking =
        (driverProvider.activeBooking != null &&
            driverProvider.activeBooking!.id == widget.booking.id)
        ? driverProvider.activeBooking!
        : _currentBooking;
    final customer = booking.customer;
    final phone = customer?.phone;

    if (phone != null && phone.isNotEmpty) {
      _makeCall(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available')),
      );
    }
  }

  void _showLowBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 36.0, bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDEBEC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFFE31C2E),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Wallet Balance is Low',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF121214),
                      ),
                      textAlign: TextAlign.center,
                ),
                    const SizedBox(height: 12),
                    Text(
                      'Your current wallet balance is below the minimum required amount to accept bookings. Please recharge to continue.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6C6F79),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRejectDialog(
    BuildContext context,
    DriverHomeProvider driverProvider,
    int bookingId,
  ) {
    final controller = TextEditingController(
      text: 'Too far from current location',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5E7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE53E4F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reject Booking',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF121214),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Please provide a reason for rejecting this booking.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6C6F79),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF121214),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter reason here...',
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
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFCC2D3B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        foregroundColor: const Color(0xFF6C6F79),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await driverProvider
                            .rejectBookingForDriver(bookingId, controller.text);
                        if (success && mounted) {
                          Navigator.pop(
                            context,
                          ); // Pop details screen since it's rejected
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking rejected successfully'),
                            ),
                          );
                        } else if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                driverProvider.bookingsError ??
                                    'Failed to reject booking',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC2D3B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSliderText(String status) {
    switch (status.toUpperCase()) {
      case 'DRIVER_ASSIGNED':
        return 'Swipe: Arrived at Pickup';
      case 'OTP_VERIFIED':
        return 'Swipe: Pick Up Goods';
      case 'GOODS_PICKED_UP':
        return 'Swipe: Start Transit';
      case 'IN_TRANSIT':
        return 'Swipe: Arrived at Drop';
      case 'DRIVER_ARRIVED_DROP':
        return 'Swipe: Complete Delivery';
      default:
        return 'Swipe to Proceed';
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'DRIVER_ASSIGNED':
        return 'DRIVER_ARRIVED';
      case 'OTP_VERIFIED':
        return 'GOODS_PICKED_UP';
      case 'GOODS_PICKED_UP':
        return 'IN_TRANSIT';
      case 'IN_TRANSIT':
        return 'DRIVER_ARRIVED_DROP';
      case 'DRIVER_ARRIVED_DROP':
        return 'DELIVERED';
      default:
        return 'DELIVERED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final booking =
        (driverProvider.activeBooking != null &&
            driverProvider.activeBooking!.id == widget.booking.id)
        ? driverProvider.activeBooking!
        : _currentBooking;

    final pickupLat = booking.pickupLatitude;
    final pickupLng = booking.pickupLongitude;
    final LatLng centerLatLng = (pickupLat != null && pickupLng != null)
        ? LatLng(pickupLat, pickupLng)
        : _defaultDelhi;

    final String statusUpper = (_localStatus ?? booking.status).toUpperCase();
    final bool needsOtpVerification = statusUpper == 'DRIVER_ARRIVED';
    final bool isDelivered =
        statusUpper == 'DELIVERED' || statusUpper == 'COMPLETED';

    if (statusUpper == 'CANCELLED' || statusUpper == 'FAILED') {
      _checkAndShowStatusDialog(statusUpper);
    }

    if (isDelivered && !_wasAlreadyCompleted && !_hasStartedAutoPop) {
      _hasStartedAutoPop = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          driverProvider.fetchHomeBookings();
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map Background
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: centerLatLng,
                zoom: 13.5,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_polylineCoordinates.isNotEmpty && _isRouteDrawn) {
                  _fitMapBounds();
                }
              },
              markers: _buildMarkers(booking),
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Custom Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                    if (_isRouteDrawn &&
                        (_routeDistanceText != null ||
                            _routeDurationText != null)) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFE1E1E6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.navigation_outlined,
                              size: 14,
                              color: Color(0xFFD90429),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_routeDistanceText ?? ""} · ${_routeDurationText ?? ""}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSheetExpanded = !_isSheetExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFE1E1E6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSheetExpanded
                                  ? Icons.map_outlined
                                  : Icons.info_outline,
                              size: 14,
                              color: const Color(0xFF121214),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSheetExpanded ? 'Map' : 'Details',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _onViewRoutePressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isRouteDrawn
                              ? const Color(0xFFE31C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFE1E1E6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions,
                              size: 14,
                              color: _isRouteDrawn
                                  ? Colors.white
                                  : const Color(0xFF121214),
                            ),
                            const SizedBox(width: 4),
                            if (_isRouteLoading)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE31C2E),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'View Route',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _isRouteDrawn
                                      ? Colors.white
                                      : const Color(0xFF121214),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Sheet Content
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              offset: _isSheetExpanded ? Offset.zero : const Offset(0, 0.9),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 30,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle Bar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSheetExpanded = !_isSheetExpanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent,
                          child: Center(
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
                      ),

                      // Sheet Body
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Earnings & Distance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ESTIMATED EARNING',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF6C6F79),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${booking.totalFare.toStringAsFixed(2)}',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 28,
                                        color: const Color(0xFF121214),
                                      ),
                                    ),
                                  ],
                                ),
                                if (booking.estimatedDistanceKm != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'TOTAL DISTANCE',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF6C6F79),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${booking.estimatedDistanceKm!.toStringAsFixed(1)} km',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Addresses & Shipment Details
                            if (statusUpper == 'DRIVER_ARRIVED_DROP' &&
                                _selectedPaymentMethod != null) ...[
                              _buildCollapsibleDetailsSection(booking),
                              const SizedBox(height: 20),
                            ] else ...[
                              _buildAddressCard(booking),
                              const SizedBox(height: 20),
                              _buildShipmentDetailsCard(booking),
                              const SizedBox(height: 24),
                            ],

                            // Dynamic Action Section (Accept/Reject, OTP or Status updates)
                            if (statusUpper == 'PENDING') ...[
                              Column(
                                children: [
                                  SwipeSlider(
                                    key: ValueKey(
                                      'accept_${booking.status}_${booking.id}',
                                    ),
                                    text: 'Swipe to Accept',
                                    isLoading: driverProvider.isBookingsLoading,
                                    onSwipeComplete: () async {
                                      final success = await driverProvider
                                          .acceptBookingForDriver(booking.id);
                                      if (success && mounted) {
                                        setState(() {
                                          _localStatus = 'DRIVER_ASSIGNED';
                                        });
                                        await _loadFreshBookingDetails(
                                          force: true,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Booking accepted!'),
                                          ),
                                        );
                                      } else if (!success && mounted) {
                                        final errorMsg = driverProvider.bookingsError ?? '';
                                        final isLowBalance = errorMsg.toLowerCase().contains('wallet') ||
                                                             errorMsg.toLowerCase().contains('balance') ||
                                                             errorMsg.toLowerCase().contains('insufficient');
                                        if (isLowBalance) {
                                          _showLowBalanceDialog(context);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                driverProvider.bookingsError ??
                                                    'Failed to accept booking',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ] else ...[
                              if (statusUpper == 'DRIVER_ARRIVED_DROP') ...[
                                // Arrived at drop payment selection or QR
                                if (_selectedPaymentMethod == null) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'COLLECT PAYMENT',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF6C6F79),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPaymentMethod =
                                                      'CASH';
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE1E1E6,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                      Icons.payments_rounded,
                                                      color: Color(0xFF1C9A5B),
                                                      size: 36,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Cash Payment',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: const Color(
                                                              0xFF121214,
                                                            ),
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Collect physical cash',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        color: const Color(
                                                          0xFF6C6F79,
                                                        ),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPaymentMethod = 'QR';
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE1E1E6,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                      Icons.qr_code_2_rounded,
                                                      color: Color(0xFFD90429),
                                                      size: 36,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'UPI / QR Code',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: const Color(
                                                              0xFF121214,
                                                            ),
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Scan to pay driver',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        color: const Color(
                                                          0xFF6C6F79,
                                                        ),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ] else if (_selectedPaymentMethod ==
                                    'CASH') ...[
                                  Column(
                                    children: [
                                      SwipeSlider(
                                        key: ValueKey(
                                          'complete_cash_${booking.status}_${booking.id}',
                                        ),
                                        text: _getSliderText(booking.status),
                                        isLoading:
                                            driverProvider.isBookingsLoading,
                                        onSwipeComplete: () async {
                                          final nextStatus = _getNextStatus(
                                            booking.status,
                                          );
                                          final success = await driverProvider
                                              .updateStatusForBooking(
                                                booking.id,
                                                nextStatus,
                                              );
                                          if (success && mounted) {
                                            setState(() {
                                              _localStatus = nextStatus;
                                            });
                                            await _loadFreshBookingDetails(
                                              force: true,
                                            );
                                          } else if (!success && mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  driverProvider
                                                          .bookingsError ??
                                                      'Status update failed',
                                                ),
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedPaymentMethod = null;
                                          });
                                        },
                                        child: Text(
                                          'Change Payment Method',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFFD90429),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_selectedPaymentMethod == 'QR') ...[
                                  Builder(
                                    builder: (context) {
                                      final upiId =
                                          driverProvider.profile?.upiId;
                                      if (upiId == null || upiId.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF5F5),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFFD1D1),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Color(0xFFD90429),
                                                size: 36,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'UPI ID is not configured in your profile. Please configure it in your profile settings to collect payments using QR Code.',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      color: const Color(
                                                        0xFFD90429,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16),
                                              OutlinedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedPaymentMethod =
                                                        'CASH';
                                                  });
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFFD90429,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFFD90429),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Choose Cash Payment Instead',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final String payeeName =
                                          driverProvider.profile?.name ??
                                          'Partner';
                                      final String upiUrl =
                                          'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=${booking.totalFare.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Booking ${booking.bookingId}")}';
                                      final String qrImageUrl =
                                          'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

                                      return Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFE1E1E6),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'SCAN QR CODE TO PAY',
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFF6C6F79,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    qrImageUrl,
                                                    width: 160,
                                                    height: 160,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          width: 160,
                                                          height: 160,
                                                          color: const Color(
                                                            0xFFFFF5F5,
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .qr_code_rounded,
                                                            size: 48,
                                                            color: Color(
                                                              0xFFD90429,
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '₹${booking.totalFare.toStringAsFixed(2)}',
                                                  style:
                                                      GoogleFonts.ibmPlexMono(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 24,
                                                        color: const Color(
                                                          0xFF121214,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'UPI: $upiId',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF6C6F79,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SwipeSlider(
                                            key: ValueKey(
                                              'complete_qr_${booking.status}_${booking.id}',
                                            ),
                                            text: _getSliderText(
                                              booking.status,
                                            ),
                                            isLoading: driverProvider
                                                .isBookingsLoading,
                                            onSwipeComplete: () async {
                                              final nextStatus = _getNextStatus(
                                                booking.status,
                                              );
                                              final success =
                                                  await driverProvider
                                                      .updateStatusForBooking(
                                                        booking.id,
                                                        nextStatus,
                                                      );
                                              if (success && mounted) {
                                                setState(() {
                                                  _localStatus = nextStatus;
                                                });
                                                await _loadFreshBookingDetails(
                                                  force: true,
                                                );
                                              } else if (!success && mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      driverProvider
                                                              .bookingsError ??
                                                          'Status update failed',
                                                    ),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedPaymentMethod = null;
                                              });
                                            },
                                            child: Text(
                                              'Change Payment Method',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: const Color(
                                                      0xFFD90429,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ] else ...[
                                // OTP verification or updates
                                if (needsOtpVerification) ...[
                                  OtpVerificationView(
                                    isLoading: _isVerifyingOtp,
                                    isSuccess: statusUpper == 'OTP_VERIFIED',
                                    onOtpSubmit: (otp) async {
                                      setState(() {
                                        _isVerifyingOtp = true;
                                      });
                                      final success = await driverProvider
                                          .verifyOtpForBooking(booking.id, otp);
                                      setState(() {
                                        _isVerifyingOtp = false;
                                      });
                                      if (success && mounted) {
                                        setState(() {
                                          _localStatus = 'OTP_VERIFIED';
                                        });
                                      } else if (!success && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              driverProvider.bookingsError ??
                                                  'OTP verification failed',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ] else ...[
                                  // Message and Call Buttons
                                  _buildMessageCallButtons(),
                                  const SizedBox(height: 16),
                                  // Swipe Slider (below buttons)
                                  SwipeSlider(
                                    key: ValueKey(
                                      'status_${booking.status}_${booking.id}',
                                    ),
                                    text: _getSliderText(booking.status),
                                    isLoading: driverProvider.isBookingsLoading,
                                    onSwipeComplete: () async {
                                      final nextStatus = _getNextStatus(
                                        booking.status,
                                      );
                                      final success = await driverProvider
                                          .updateStatusForBooking(
                                            booking.id,
                                            nextStatus,
                                          );
                                      if (success && mounted) {
                                        setState(() {
                                          _localStatus = nextStatus;
                                        });
                                        await _loadFreshBookingDetails(
                                          force: true,
                                        );
                                      } else if (!success && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              driverProvider.bookingsError ??
                                                  'Status update failed',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ],
                              const SizedBox(height: 12),
                              if (statusUpper == 'DRIVER_ASSIGNED') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (booking.pickupLatitude != null &&
                                          booking.pickupLongitude != null) {
                                        MapsLauncherService.launchMaps(
                                          latitude: booking.pickupLatitude!,
                                          longitude: booking.pickupLongitude!,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pickup location coordinates are missing',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.navigation_rounded),
                                    label: const Text('Navigate to Pickup'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF121214),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      textStyle: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ] else if (statusUpper == 'IN_TRANSIT') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (booking.dropLatitude != null &&
                                          booking.dropLongitude != null) {
                                        MapsLauncherService.launchMaps(
                                          latitude: booking.dropLatitude!,
                                          longitude: booking.dropLongitude!,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Drop location coordinates are missing',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.navigation_rounded),
                                    label: const Text('Navigate to Drop'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF121214),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      textStyle: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                              if (statusUpper != 'IN_TRANSIT' &&
                                  statusUpper != 'DRIVER_ARRIVED_DROP') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _showRejectDialog(
                                      context,
                                      driverProvider,
                                      booking.id,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD90429),
                                      side: const BorderSide(
                                        color: Color(0xFFD90429),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text(
                                      'Reject Booking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Completion Modal Overlay
          if (isDelivered)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF6F6F8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F7EF),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF1C9A5B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1C9A5B),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1C9A5B),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Trip Earnings',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C6F79),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${booking.totalFare.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF121214),
                        letterSpacing: -1,
                      ),
                    ),
                    if (_wasAlreadyCompleted) ...[
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05121214),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB000),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Customer Rating',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF121214),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB000),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '"Very fast delivery, polite behavior and well-maintained vehicle. Excellent service!"',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: const Color(0xFF4A5568),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(
                        'Going to home page in 3 seconds...',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6C6F79),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Clear active booking ONLY if this is a newly/live completed trip
                          if (!_wasAlreadyCompleted) {
                            driverProvider.fetchHomeBookings();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC2D3B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: Text(
                          _wasAlreadyCompleted ? 'Close' : 'Go to Home Now',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BookingModel booking) {
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
    final statusUpper = (_localStatus ?? booking.status).toUpperCase();
    final isPending = statusUpper == 'PENDING';

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
                    isPending
                        ? booking.parcelType
                        : '${booking.parcelType} (${booking.weightKg} kg)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                ],
              ),
              if (!isPending && booking.goodsDescription.isNotEmpty) ...[
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

  Widget _buildMessageCallButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showCallModal,
        icon: const Icon(Icons.phone_android_rounded, size: 18),
        label: const Text('Call Customer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121214),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCollapsibleDetailsSection(BookingModel booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E1E6)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isDetailsExpanded,
          onExpansionChanged: (val) {
            setState(() {
              _isDetailsExpanded = val;
            });
          },
          leading: const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD90429),
          ),
          title: Text(
            'Ride & Shipment Details',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF121214),
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFE1E1E6)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAddressCard(booking),
                  const SizedBox(height: 16),
                  _buildShipmentDetailsCard(booking),
                  const SizedBox(height: 16),
                  _buildMessageCallButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwipeSlider extends StatefulWidget {
  final String text;
  final VoidCallback onSwipeComplete;
  final bool isLoading;

  const SwipeSlider({
    super.key,
    required this.text,
    required this.onSwipeComplete,
    this.isLoading = false,
  });

  @override
  State<SwipeSlider> createState() => _SwipeSliderState();
}

class _SwipeSliderState extends State<SwipeSlider> {
  double _thumbPosition = 0;
  bool _isCompleted = false;

  @override
  void didUpdateWidget(covariant SwipeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() {
        _thumbPosition = 0;
        _isCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDistance = constraints.maxWidth - 56;
        final double currentPosition = widget.isLoading
            ? maxDistance
            : _thumbPosition;

        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: currentPosition > 0 ? currentPosition + 24 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C9A5B),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.text,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Positioned(
                left: currentPosition + 4,
                top: 4,
                bottom: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted || widget.isLoading) return;
                    setState(() {
                      _thumbPosition += details.delta.dx;
                      if (_thumbPosition < 0) _thumbPosition = 0;
                      if (_thumbPosition > maxDistance)
                        _thumbPosition = maxDistance;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted || widget.isLoading) return;
                    if (_thumbPosition >= maxDistance * 0.85) {
                      setState(() {
                        _thumbPosition = maxDistance;
                        _isCompleted = true;
                      });
                      widget.onSwipeComplete();
                    } else {
                      setState(() {
                        _thumbPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    width: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF121214),
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: Color(0xFF121214),
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OtpVerificationView extends StatefulWidget {
  final Function(String otp) onOtpSubmit;
  final bool isLoading;
  final bool isSuccess;

  const OtpVerificationView({
    super.key,
    required this.onOtpSubmit,
    required this.isLoading,
    required this.isSuccess,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onKeyChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == 4) {
          widget.onOtpSubmit(otp);
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSuccess) {
      return Container(
        height: 56,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF1C9A5B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Verified!',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1C9A5B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isLoading) {
      return Container(
        height: 56,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Verifying...',
              style: GoogleFonts.outfit(
                color: const Color(0xFF6C6F79),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Ask customer for 4-digit PIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121214),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              width: 48,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                maxLength: 1,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF121214),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: const Color(0xFFF1F1F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE1E1E6),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD90429),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) => _onKeyChanged(val, index),
              ),
            );
          }),
        ),
      ],
    );
  }
}
