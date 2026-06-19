class AvailableVehicleModel {
  final int id;
  final String make;
  final String model;
  final double perKmRate;
  final int vehicleTypeId;
  final String vehicleTypeName;

  AvailableVehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.perKmRate,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
  });

  factory AvailableVehicleModel.fromJson(Map<String, dynamic> json) {
    return AvailableVehicleModel(
      id: json['id'] as int? ?? 0,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      vehicleTypeId: json['vehicleTypeId'] as int? ?? 0,
      vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'perKmRate': perKmRate,
      'vehicleTypeId': vehicleTypeId,
      'vehicleTypeName': vehicleTypeName,
    };
  }
}
