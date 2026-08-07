class TimeBasedPricingModel {
  final int id;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final double extraCharge;
  final bool enabled;

  TimeBasedPricingModel({
    required this.id,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.extraCharge,
    required this.enabled,
  });

  factory TimeBasedPricingModel.fromJson(Map<String, dynamic> json) {
    return TimeBasedPricingModel(
      id: json['id'] as int,
      timeSlot: json['timeSlot'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      extraCharge: (json['extraCharge'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeSlot': timeSlot,
      'startTime': startTime,
      'endTime': endTime,
      'extraCharge': extraCharge,
      'enabled': enabled,
    };
  }
}
