class PricingRuleModel {
  final int id;
  final double rainMultiplier;
  final double nightMultiplier;
  final double heavyTrafficMultiplier;
  final double fuelMultiplier;
  final double waitingChargePerMinute;
  final bool dynamicPricingEnabled;

  PricingRuleModel({
    required this.id,
    required this.rainMultiplier,
    required this.nightMultiplier,
    required this.heavyTrafficMultiplier,
    required this.fuelMultiplier,
    required this.waitingChargePerMinute,
    required this.dynamicPricingEnabled,
  });

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) {
    return PricingRuleModel(
      id: json['id'] as int,
      rainMultiplier: (json['rainMultiplier'] as num).toDouble(),
      nightMultiplier: (json['nightMultiplier'] as num).toDouble(),
      heavyTrafficMultiplier: (json['heavyTrafficMultiplier'] as num).toDouble(),
      fuelMultiplier: (json['fuelMultiplier'] as num).toDouble(),
      waitingChargePerMinute: (json['waitingChargePerMinute'] as num).toDouble(),
      dynamicPricingEnabled: json['dynamicPricingEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rainMultiplier': rainMultiplier,
      'nightMultiplier': nightMultiplier,
      'heavyTrafficMultiplier': heavyTrafficMultiplier,
      'fuelMultiplier': fuelMultiplier,
      'waitingChargePerMinute': waitingChargePerMinute,
      'dynamicPricingEnabled': dynamicPricingEnabled,
    };
  }
}
