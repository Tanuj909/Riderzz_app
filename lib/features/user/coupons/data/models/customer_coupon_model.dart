class CustomerCouponModel {
  final int id;
  final int? bookingId;
  final String recipientType;
  final double rewardAmount;
  final String rewardCode;
  final String status;
  final String? claimedAt;
  final String? expiresAt;
  final String? createdAt;

  CustomerCouponModel({
    required this.id,
    this.bookingId,
    required this.recipientType,
    required this.rewardAmount,
    required this.rewardCode,
    required this.status,
    this.claimedAt,
    this.expiresAt,
    this.createdAt,
  });

  bool get isAvailable =>
      status.toUpperCase() == 'AVAILABLE' && (claimedAt == null || claimedAt!.isEmpty);

  bool get isClaimed =>
      status.toUpperCase() == 'CLAIMED' || (claimedAt != null && claimedAt!.isNotEmpty);

  CustomerCouponModel copyWith({
    int? id,
    int? bookingId,
    String? recipientType,
    double? rewardAmount,
    String? rewardCode,
    String? status,
    String? claimedAt,
    String? expiresAt,
    String? createdAt,
  }) {
    return CustomerCouponModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      recipientType: recipientType ?? this.recipientType,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardCode: rewardCode ?? this.rewardCode,
      status: status ?? this.status,
      claimedAt: claimedAt ?? this.claimedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CustomerCouponModel.fromJson(Map<String, dynamic> json) {
    return CustomerCouponModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingId: (json['bookingId'] as num?)?.toInt(),
      recipientType: json['recipientType'] as String? ?? 'CUSTOMER',
      rewardAmount: (json['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      rewardCode: json['rewardCode'] as String? ?? '',
      status: json['status'] as String? ?? 'AVAILABLE',
      claimedAt: json['claimedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'recipientType': recipientType,
      'rewardAmount': rewardAmount,
      'rewardCode': rewardCode,
      'status': status,
      'claimedAt': claimedAt,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
    };
  }
}
