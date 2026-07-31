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

class CustomerInfo {
  final int userId;
  final String fullName;
  final String phone;
  final String? email;
  final double rating;

  CustomerInfo({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.rating,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      userId: json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? 'N/A',
      phone: json['phone'] as String? ?? 'N/A',
      email: json['email'] as String?,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
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
  final CustomerInfo? customer;
  final int? expiresInSeconds;
  final bool fastDelivery;
  final double? fastDeliveryCharge;
  final String? pickupContactName;
  final String? pickupContactPhone;
  final String? dropContactName;
  final String? dropContactPhone;
  final String? vehicleNumber;
  final double? commissionAmount;

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
    this.customer,
    this.expiresInSeconds,
    this.fastDelivery = false,
    this.fastDeliveryCharge,
    this.pickupContactName,
    this.pickupContactPhone,
    this.dropContactName,
    this.dropContactPhone,
    this.vehicleNumber,
    this.commissionAmount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String getFormattedAddress(dynamic addr) {
      if (addr == null) return 'N/A';
      if (addr is String) return addr;
      if (addr is Map) {
        final mapAddr = Map<String, dynamic>.from(addr);
        final parts = <String>[];
        if (mapAddr['addressLine1'] != null &&
            mapAddr['addressLine1'].toString().isNotEmpty) {
          parts.add(mapAddr['addressLine1'].toString());
        }
        if (mapAddr['addressLine2'] != null &&
            mapAddr['addressLine2'].toString().isNotEmpty) {
          parts.add(mapAddr['addressLine2'].toString());
        }
        if (mapAddr['city'] != null && mapAddr['city'].toString().isNotEmpty) {
          parts.add(mapAddr['city'].toString());
        }
        return parts.isNotEmpty
            ? parts.join(', ')
            : (mapAddr['label']?.toString() ?? 'Saved Address');
      }
      return addr.toString();
    }

    final pickupRaw = json['pickupAddress'];
    final dropRaw = json['dropAddress'];

    final Map<String, dynamic>? pickupObj =
        (pickupRaw != null && pickupRaw is Map)
        ? Map<String, dynamic>.from(pickupRaw)
        : null;
    final Map<String, dynamic>? dropObj = (dropRaw != null && dropRaw is Map)
        ? Map<String, dynamic>.from(dropRaw)
        : null;
    final Map<String, dynamic>? custObj =
        (json['customer'] != null && json['customer'] is Map)
        ? Map<String, dynamic>.from(json['customer'])
        : null;
    final Map<String, dynamic>? driverObj =
        (json['driver'] != null && json['driver'] is Map)
        ? Map<String, dynamic>.from(json['driver'])
        : null;

    final rawId = json['id'] ?? json['bookingId'];
    int parsedId = 0;
    if (rawId != null) {
      if (rawId is int) {
        parsedId = rawId;
      } else {
        parsedId = int.tryParse(rawId.toString()) ?? 0;
      }
    }

    final rawBookingNumber =
        json['bookingNumber'] ?? json['bookingId'] ?? json['id'];

    return BookingModel(
      id: parsedId,
      bookingId: rawBookingNumber?.toString() ?? '',
      customerId: custObj != null
          ? ((custObj['userId'] as num?)?.toInt() ?? 0)
          : ((json['customerId'] as num?)?.toInt() ?? 0),
      driverId: driverObj != null
          ? ((driverObj['userId'] as num?)?.toInt())
          : ((json['driverId'] as num?)?.toInt()),
      pickupAddressId: pickupObj != null
          ? ((pickupObj['id'] as num?)?.toInt() ?? 0)
          : ((json['pickupAddressId'] as num?)?.toInt() ?? 0),
      dropAddressId: dropObj != null
          ? ((dropObj['id'] as num?)?.toInt() ?? 0)
          : ((json['dropAddressId'] as num?)?.toInt() ?? 0),
      pickupAddressName: getFormattedAddress(pickupRaw),
      dropAddressName: getFormattedAddress(dropRaw),
      vehicleTypeId: (json['vehicleTypeId'] as num?)?.toInt() ?? 0,
      parcelType: json['parcelType'] as String? ?? 'OTHER',
      goodsDescription: json['goodsDescription'] as String? ?? '',
      weightKg: (json['weightKg'] as num? ?? 0.0).toDouble(),
      paymentMode: json['paymentMode'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'PENDING',
      baseFare: (json['baseFare'] as num? ?? 0.0).toDouble(),
      totalFare:
          (json['finalFare'] as num? ??
                  json['estimatedFare'] as num? ??
                  json['totalFare'] as num? ??
                  json['fare'] as num? ??
                  0.0)
              .toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
      pickupLatitude: pickupObj != null
          ? (pickupObj['latitude'] as num?)?.toDouble()
          : (json['pickupLatitude'] as num? ??
                    json['pickupLat'] as num? ??
                    json['pickup_lat'] as num?)
                ?.toDouble(),
      pickupLongitude: pickupObj != null
          ? (pickupObj['longitude'] as num?)?.toDouble()
          : (json['pickupLongitude'] as num? ??
                    json['pickupLng'] as num? ??
                    json['pickup_lng'] as num?)
                ?.toDouble(),
      dropLatitude: dropObj != null
          ? (dropObj['latitude'] as num?)?.toDouble()
          : (json['dropLatitude'] as num? ??
                    json['dropLat'] as num? ??
                    json['drop_lat'] as num?)
                ?.toDouble(),
      dropLongitude: dropObj != null
          ? (dropObj['longitude'] as num?)?.toDouble()
          : (json['dropLongitude'] as num? ??
                    json['dropLng'] as num? ??
                    json['drop_lng'] as num?)
                ?.toDouble(),
      estimatedDistanceKm:
          (json['estimatedDistanceKm'] as num? ?? json['distanceKm'] as num?)
              ?.toDouble(),
      routePolyline:
          json['routePolyline'] as String? ??
          json['route_polyline'] as String? ??
          json['route'] as String?,
      driver: driverObj != null ? DriverInfo.fromJson(driverObj) : null,
      customer: custObj != null ? CustomerInfo.fromJson(custObj) : null,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt(),
      fastDelivery: json['fastDelivery'] as bool? ?? false,
      fastDeliveryCharge: json['fastDeliveryCharge'] != null
          ? (json['fastDeliveryCharge'] as num).toDouble()
          : null,
      pickupContactName: pickupObj?['contactPersonName'] as String?,
      pickupContactPhone: pickupObj?['contactPersonPhone'] as String?,
      dropContactName: dropObj?['contactPersonName'] as String?,
      dropContactPhone: dropObj?['contactPersonPhone'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
    );
  }
}
