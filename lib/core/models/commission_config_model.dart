class CommissionConfigModel {
  final int id;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final double commissionPercent;

  CommissionConfigModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.commissionPercent,
  });

  factory CommissionConfigModel.fromJson(Map<String, dynamic> json) {
    return CommissionConfigModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicleTypeId'] as int,
      vehicleTypeName: json['vehicleTypeName'] as String? ?? 'N/A',
      commissionPercent: (json['commissionPercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleTypeId': vehicleTypeId,
      'vehicleTypeName': vehicleTypeName,
      'commissionPercent': commissionPercent,
    };
  }
}
