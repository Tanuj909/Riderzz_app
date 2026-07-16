class DriverEarningsModel {
  final double totalEarnings;
  final double todayEarnings;
  final int totalCompletedTrips;

  DriverEarningsModel({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.totalCompletedTrips,
  });

  factory DriverEarningsModel.fromJson(Map<String, dynamic> json) {
    return DriverEarningsModel(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      totalCompletedTrips: (json['totalCompletedTrips'] as int?) ?? 0,
    );
  }
}
