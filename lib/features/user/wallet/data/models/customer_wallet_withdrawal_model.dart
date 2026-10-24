import 'package:riderzz_app/core/models/admin_withdrawal_model.dart' show PayoutStatus;

class CustomerWalletWithdrawalModel {
  final int? withdrawalId;
  final int? bankAccountId;
  final double amount;
  final PayoutStatus status;
  final String rawStatus;

  CustomerWalletWithdrawalModel({
    this.withdrawalId,
    this.bankAccountId,
    required this.amount,
    required this.status,
    required this.rawStatus,
  });

  factory CustomerWalletWithdrawalModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'PENDING';
    final PayoutStatus status = PayoutStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => PayoutStatus.pending,
    );

    return CustomerWalletWithdrawalModel(
      withdrawalId: (json['withdrawalId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt(),
      bankAccountId: (json['bankAccountId'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble() ?? double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: status,
      rawStatus: statusStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'withdrawalId': withdrawalId,
      'bankAccountId': bankAccountId,
      'amount': amount,
      'status': rawStatus,
    };
  }
}
