class CustomerBankAccountModel {
  final int? bankAccountId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String? bankRegisteredPhone;
  final String bankName;
  final bool verified;
  final bool active;

  CustomerBankAccountModel({
    this.bankAccountId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.bankRegisteredPhone,
    required this.bankName,
    this.verified = false,
    this.active = true,
  });

  factory CustomerBankAccountModel.fromJson(Map<String, dynamic> json) {
    return CustomerBankAccountModel(
      bankAccountId: (json['bankAccountId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt(),
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      bankRegisteredPhone: json['bankRegisteredPhone']?.toString(),
      bankName: json['bankName']?.toString() ?? '',
      verified: json['verified'] == true,
      active: json['active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bankAccountId != null) 'bankAccountId': bankAccountId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      if (bankRegisteredPhone != null) 'bankRegisteredPhone': bankRegisteredPhone,
      'bankName': bankName,
      'verified': verified,
      'active': active,
    };
  }
}
