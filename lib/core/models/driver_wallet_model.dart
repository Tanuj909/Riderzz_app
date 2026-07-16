class DriverWalletModel {
  final double balance;
  final double minBalanceRequired;
  final String lastUpdated;
  final List<DriverWalletTransactionModel> transactions;

  DriverWalletModel({
    required this.balance,
    required this.minBalanceRequired,
    required this.lastUpdated,
    required this.transactions,
  });

  factory DriverWalletModel.fromJson(Map<String, dynamic> json) {
    var txList = json['transactions'] as List? ?? [];
    List<DriverWalletTransactionModel> parsedTx = txList
        .map(
          (t) => DriverWalletTransactionModel.fromJson(
            Map<String, dynamic>.from(t),
          ),
        )
        .toList();

    double balValue = 0.0;
    if (json['balance'] != null) {
      balValue = double.tryParse(json['balance'].toString()) ?? 0.0;
    }

    double minBalValue = 0.0;
    if (json['minBalanceRequired'] != null) {
      minBalValue =
          double.tryParse(json['minBalanceRequired'].toString()) ?? 0.0;
    }

    return DriverWalletModel(
      balance: balValue,
      minBalanceRequired: minBalValue,
      lastUpdated: json['lastUpdated'] as String? ?? '',
      transactions: parsedTx,
    );
  }
}

class DriverWalletTransactionModel {
  final int id;
  final String type;
  final double amount;
  final double openingBalance;
  final double closingBalance;
  final String referenceNumber;
  final String remarks;
  final String? bookingNumber;
  final String status;
  final String createdAt;

  String get description => remarks;

  DriverWalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.openingBalance,
    required this.closingBalance,
    required this.referenceNumber,
    required this.remarks,
    this.bookingNumber,
    required this.status,
    required this.createdAt,
  });

  factory DriverWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    double amtValue = 0.0;
    if (json['amount'] != null) {
      amtValue = double.tryParse(json['amount'].toString()) ?? 0.0;
    }

    double openBalValue = 0.0;
    if (json['openingBalance'] != null) {
      openBalValue = double.tryParse(json['openingBalance'].toString()) ?? 0.0;
    }

    double closingBalValue = 0.0;
    if (json['closingBalance'] != null) {
      closingBalValue =
          double.tryParse(json['closingBalance'].toString()) ?? 0.0;
    }

    return DriverWalletTransactionModel(
      id: json['id'] as int? ?? 0,
      type:
          json['transactionType'] as String? ??
          json['type'] as String? ??
          'RECHARGE',
      amount: amtValue,
      openingBalance: openBalValue,
      closingBalance: closingBalValue,
      referenceNumber: json['referenceNumber'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String?,
      status: json['status'] as String? ?? 'SUCCESS',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class RechargeInitiateResponse {
  final String razorpayOrderId;
  final String razorpayKeyId;
  final double amount;
  final int rechargeId;
  final String currency;

  RechargeInitiateResponse({
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.amount,
    required this.rechargeId,
    required this.currency,
  });

  factory RechargeInitiateResponse.fromJson(Map<String, dynamic> json) {
    return RechargeInitiateResponse(
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      razorpayKeyId: json['razorpayKeyId'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      rechargeId: json['rechargeId'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}
