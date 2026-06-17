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
        .map((t) => DriverWalletTransactionModel.fromJson(Map<String, dynamic>.from(t)))
        .toList();

    double balValue = 0.0;
    if (json['balance'] != null) {
      balValue = double.tryParse(json['balance'].toString()) ?? 0.0;
    }

    double minBalValue = 0.0;
    if (json['minBalanceRequired'] != null) {
      minBalValue = double.tryParse(json['minBalanceRequired'].toString()) ?? 0.0;
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
  final double closingBalance;
  final String description;
  final String createdAt;

  DriverWalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.closingBalance,
    required this.description,
    required this.createdAt,
  });

  factory DriverWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    double amtValue = 0.0;
    if (json['amount'] != null) {
      amtValue = double.tryParse(json['amount'].toString()) ?? 0.0;
    }

    double closingBalValue = 0.0;
    if (json['closingBalance'] != null) {
      closingBalValue = double.tryParse(json['closingBalance'].toString()) ?? 0.0;
    }

    return DriverWalletTransactionModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'RECHARGE',
      amount: amtValue,
      closingBalance: closingBalValue,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
