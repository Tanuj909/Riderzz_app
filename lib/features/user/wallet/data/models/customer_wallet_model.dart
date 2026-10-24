class CustomerWalletModel {
  final int walletId;
  final double balance;
  final double holdBalance;
  final bool active;

  CustomerWalletModel({
    required this.walletId,
    required this.balance,
    required this.holdBalance,
    required this.active,
  });

  factory CustomerWalletModel.fromJson(Map<String, dynamic> json) {
    return CustomerWalletModel(
      walletId: (json['walletId'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      holdBalance: (json['holdBalance'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletId': walletId,
      'balance': balance,
      'holdBalance': holdBalance,
      'active': active,
    };
  }
}
