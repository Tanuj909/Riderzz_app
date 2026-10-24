import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/user/wallet/data/datasource/customer_wallet_remote_datasource.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_withdrawal_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_bank_account_model.dart';

class CustomerWalletRepository {
  final CustomerWalletRemoteDataSource _remoteDataSource;

  CustomerWalletRepository(this._remoteDataSource);

  Future<ApiResponse<CustomerWalletModel>> fetchCustomerWallet() {
    return _remoteDataSource.fetchCustomerWallet();
  }

  Future<ApiResponse<CustomerWalletWithdrawalModel>> requestWithdrawal({
    required double amount,
  }) {
    return _remoteDataSource.requestWithdrawal(amount: amount);
  }

  Future<ApiResponse<CustomerBankAccountModel?>> fetchBankAccount() {
    return _remoteDataSource.fetchBankAccount();
  }

  Future<ApiResponse<CustomerBankAccountModel>> addBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) {
    return _remoteDataSource.addBankAccount(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      bankName: bankName,
      bankRegisteredPhone: bankRegisteredPhone,
    );
  }

  Future<ApiResponse<CustomerBankAccountModel>> updateBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) {
    return _remoteDataSource.updateBankAccount(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      bankName: bankName,
      bankRegisteredPhone: bankRegisteredPhone,
    );
  }

  Future<ApiResponse<dynamic>> deleteBankAccount() {
    return _remoteDataSource.deleteBankAccount();
  }
}
