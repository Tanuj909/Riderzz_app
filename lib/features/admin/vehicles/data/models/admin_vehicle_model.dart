class AdminVehicleModel {
  final int id;
  final int? vehicleTypeId;
  final String vehicleTypeName;
  final String status;
  final int? driverId;
  final String? driverName;

  AdminVehicleModel({
    required this.id,
    this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.status,
    this.driverId,
    this.driverName,
  });

  factory AdminVehicleModel.fromJson(Map<String, dynamic> json) {
    return AdminVehicleModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicleTypeId'] as int?,
      vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleTypeId': vehicleTypeId,
      'vehicleTypeName': vehicleTypeName,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
    };
  }
}
