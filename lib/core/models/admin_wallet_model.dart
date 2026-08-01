class AdminWalletModel {
  final int walletId;
  final double balance;
  final double holdBalance;
  final double availableBalance;
  final bool active;
  final String createdAt;
  final String updatedAt;

  AdminWalletModel({
    required this.walletId,
    required this.balance,
    required this.holdBalance,
    required this.availableBalance,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminWalletModel.fromJson(Map<String, dynamic> json) {
    return AdminWalletModel(
      walletId: json['walletId'] as int? ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      holdBalance: double.tryParse(json['holdBalance']?.toString() ?? '0') ?? 0.0,
      availableBalance: double.tryParse(json['availableBalance']?.toString() ?? '0') ?? 0.0,
      active: json['active'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
