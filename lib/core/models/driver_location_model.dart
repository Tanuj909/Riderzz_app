class DriverLocationModel {
  final double latitude;
  final double longitude;
  final String updatedAt;
  final String? driverName;
  final String? vehicleNumber;

  DriverLocationModel({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.driverName,
    this.vehicleNumber,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: json['updatedAt'] as String? ?? '',
      driverName: json['driverName'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
    );
  }
}
