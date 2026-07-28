class PricingTierModel {
  final int id;
  final int vehicleTypeId;
  final String? vehicleTypeName;
  final double fromDistance;
  final double? toDistance;
  final double baseFare;
  final double perKmRate;
  final double commission;
  final bool fastDeliveryEnabled;
  final double? fastDeliveryCharge;

  PricingTierModel({
    required this.id,
    required this.vehicleTypeId,
    this.vehicleTypeName,
    required this.fromDistance,
    this.toDistance,
    required this.baseFare,
    required this.perKmRate,
    required this.commission,
    this.fastDeliveryEnabled = false,
    this.fastDeliveryCharge,
  });

  factory PricingTierModel.fromJson(Map<String, dynamic> json) {
    return PricingTierModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicleTypeId'] as int,
      vehicleTypeName: json['vehicleTypeName'] as String?,
      fromDistance: (json['fromDistance'] as num).toDouble(),
      toDistance: json['toDistance'] != null ? (json['toDistance'] as num).toDouble() : null,
      baseFare: (json['baseFare'] as num).toDouble(),
      perKmRate: (json['perKmRate'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      fastDeliveryEnabled: json['fastDeliveryEnabled'] as bool? ?? false,
      fastDeliveryCharge: json['fastDeliveryCharge'] != null ? (json['fastDeliveryCharge'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleTypeId': vehicleTypeId,
      'vehicleTypeName': vehicleTypeName,
      'fromDistance': fromDistance,
      'toDistance': toDistance,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'commission': commission,
      'fastDeliveryEnabled': fastDeliveryEnabled,
      'fastDeliveryCharge': fastDeliveryCharge,
    };
  }
}
