class VehicleTypeModel {
  final int id;
  final String name;
  final double baseFare;
  final double perKmRate;
  final int maxWeightKg;
  final double commissionPct;
  final double minWalletBalance;
  final String description;
  final bool isActive;
  final String updatedAt;
  final String? deletedAt;

  VehicleTypeModel({
    required this.id,
    required this.name,
    required this.baseFare,
    required this.perKmRate,
    required this.maxWeightKg,
    required this.commissionPct,
    required this.minWalletBalance,
    required this.description,
    required this.isActive,
    required this.updatedAt,
    this.deletedAt,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      baseFare: (json['baseFare'] as num).toDouble(),
      perKmRate: (json['perKmRate'] as num).toDouble(),
      maxWeightKg: json['maxWeightKg'] as int,
      commissionPct: (json['commissionPct'] as num).toDouble(),
      minWalletBalance: (json['minWalletBalance'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: json['updatedAt'] as String? ?? '',
      deletedAt: json['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'maxWeightKg': maxWeightKg,
      'commissionPct': commissionPct,
      'minWalletBalance': minWalletBalance,
      'description': description,
      'isActive': isActive,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }
}
