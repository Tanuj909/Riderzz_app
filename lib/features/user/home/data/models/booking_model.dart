class DriverInfo {
  final int userId;
  final String fullName;
  final String phone;
  final String? email;
  final double rating;
  final String? licenseNumber;

  DriverInfo({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.rating,
    this.licenseNumber,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      userId: json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? 'N/A',
      phone: json['phone'] as String? ?? 'N/A',
      email: json['email'] as String?,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      licenseNumber: json['licenseNumber'] as String?,
    );
  }
}

class BookingModel {
  final int id;
  final String bookingId;
  final int customerId;
  final int? driverId;
  final int pickupAddressId;
  final int dropAddressId;
  final String pickupAddressName;
  final String dropAddressName;
  final int vehicleTypeId;
  final String parcelType;
  final String goodsDescription;
  final double weightKg;
  final String paymentMode;
  final String status;
  final double baseFare;
  final double totalFare;
  final String createdAt;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final double? estimatedDistanceKm;
  final String? routePolyline;
  final DriverInfo? driver;

  BookingModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    this.driverId,
    required this.pickupAddressId,
    required this.dropAddressId,
    required this.pickupAddressName,
    required this.dropAddressName,
    required this.vehicleTypeId,
    required this.parcelType,
    required this.goodsDescription,
    required this.weightKg,
    required this.paymentMode,
    required this.status,
    required this.baseFare,
    required this.totalFare,
    required this.createdAt,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.estimatedDistanceKm,
    this.routePolyline,
    this.driver,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String getFormattedAddress(Map<String, dynamic>? addr) {
      if (addr == null) return 'N/A';
      final parts = <String>[];
      if (addr['addressLine1'] != null && addr['addressLine1'].toString().isNotEmpty) {
        parts.add(addr['addressLine1']);
      }
      if (addr['addressLine2'] != null && addr['addressLine2'].toString().isNotEmpty) {
        parts.add(addr['addressLine2']);
      }
      if (addr['city'] != null && addr['city'].toString().isNotEmpty) {
        parts.add(addr['city']);
      }
      return parts.isNotEmpty ? parts.join(', ') : (addr['label'] ?? 'Saved Address');
    }

    final pickupObj = json['pickupAddress'] != null ? Map<String, dynamic>.from(json['pickupAddress']) : null;
    final dropObj = json['dropAddress'] != null ? Map<String, dynamic>.from(json['dropAddress']) : null;
    final custObj = json['customer'] != null ? Map<String, dynamic>.from(json['customer']) : null;
    final driverObj = json['driver'] != null ? Map<String, dynamic>.from(json['driver']) : null;

    return BookingModel(
      id: json['id'] as int? ?? 0,
      bookingId: json['bookingNumber'] as String? ?? json['bookingId'] as String? ?? json['id']?.toString() ?? '',
      customerId: custObj != null ? (custObj['userId'] as int? ?? 0) : (json['customerId'] as int? ?? 0),
      driverId: driverObj != null ? (driverObj['userId'] as int?) : (json['driverId'] as int?),
      pickupAddressId: pickupObj != null ? (pickupObj['id'] as int? ?? 0) : (json['pickupAddressId'] as int? ?? 0),
      dropAddressId: dropObj != null ? (dropObj['id'] as int? ?? 0) : (json['dropAddressId'] as int? ?? 0),
      pickupAddressName: getFormattedAddress(pickupObj),
      dropAddressName: getFormattedAddress(dropObj),
      vehicleTypeId: json['vehicleTypeId'] as int? ?? 0,
      parcelType: json['parcelType'] as String? ?? 'OTHER',
      goodsDescription: json['goodsDescription'] as String? ?? '',
      weightKg: (json['weightKg'] as num? ?? 0.0).toDouble(),
      paymentMode: json['paymentMode'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'PENDING',
      baseFare: (json['baseFare'] as num? ?? 0.0).toDouble(),
      totalFare: (json['finalFare'] as num? ?? json['estimatedFare'] as num? ?? json['totalFare'] as num? ?? json['fare'] as num? ?? 0.0).toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
      pickupLatitude: pickupObj != null ? (pickupObj['latitude'] as num?)?.toDouble() : null,
      pickupLongitude: pickupObj != null ? (pickupObj['longitude'] as num?)?.toDouble() : null,
      dropLatitude: dropObj != null ? (dropObj['latitude'] as num?)?.toDouble() : null,
      dropLongitude: dropObj != null ? (dropObj['longitude'] as num?)?.toDouble() : null,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      routePolyline: json['routePolyline'] as String? ?? json['route_polyline'] as String?,
      driver: driverObj != null ? DriverInfo.fromJson(driverObj) : null,
    );
  }
}
