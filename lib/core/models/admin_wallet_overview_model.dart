class AdminWalletOverviewModel {
  final int totalDriversWithWallet;
  final double totalBalance;
  final double totalHoldBalance;
  final double totalPendingWithdrawals;
  final int pendingWithdrawalCount;

  AdminWalletOverviewModel({
    required this.totalDriversWithWallet,
    required this.totalBalance,
    required this.totalHoldBalance,
    required this.totalPendingWithdrawals,
    required this.pendingWithdrawalCount,
  });

  factory AdminWalletOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminWalletOverviewModel(
      totalDriversWithWallet: json['totalDriversWithWallet'] as int? ?? 0,
      totalBalance: double.tryParse(json['totalBalance']?.toString() ?? '0') ?? 0.0,
      totalHoldBalance: double.tryParse(json['totalHoldBalance']?.toString() ?? '0') ?? 0.0,
      totalPendingWithdrawals: double.tryParse(json['totalPendingWithdrawals']?.toString() ?? '0') ?? 0.0,
      pendingWithdrawalCount: json['pendingWithdrawalCount'] as int? ?? 0,
    );
  }
}
