class AdminRegisteredVehicleModel {
  final int id;
  final String? vehicleTypeName;
  final String status;
  final int? driverId;
  final String? driverName;

  AdminRegisteredVehicleModel({
    required this.id,
    this.vehicleTypeName,
    required this.status,
    this.driverId,
    this.driverName,
  });

  factory AdminRegisteredVehicleModel.fromJson(Map<String, dynamic> json) {
    return AdminRegisteredVehicleModel(
      id: json['id'] ?? 0,
      vehicleTypeName: json['vehicleTypeName'],
      status: json['status'] ?? 'PENDING',
      driverId: json['driverId'],
      driverName: json['driverName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleTypeName': vehicleTypeName,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
    };
  }
}
