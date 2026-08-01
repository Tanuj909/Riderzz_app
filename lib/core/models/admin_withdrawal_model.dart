enum PayoutStatus {
  pending,
  processing,
  success,
  failed
}

class AdminWithdrawalModel {
  final int withdrawalId;
  final int driverUserId;
  final String driverName;
  final String driverPhone;
  final double amount;
  final PayoutStatus status;
  final String bankName;
  final String accountNumber;
  final String requestedAt;
  final String remarks;

  AdminWithdrawalModel({
    required this.withdrawalId,
    required this.driverUserId,
    required this.driverName,
    required this.driverPhone,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountNumber,
    required this.requestedAt,
    required this.remarks,
  });

  factory AdminWithdrawalModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final PayoutStatus status = PayoutStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => PayoutStatus.pending,
    );

    return AdminWithdrawalModel(
      withdrawalId: json['withdrawalId'] as int? ?? json['id'] as int? ?? 0,
      driverUserId: json['driverUserId'] as int? ?? json['userId'] as int? ?? 0,
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: status,
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      requestedAt: json['requestedAt'] as String? ?? json['createdAt'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
    );
  }
}
