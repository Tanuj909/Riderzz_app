import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_withdrawal_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_bank_account_model.dart';

class CustomerWalletRemoteDataSource {
  final ApiClient _apiClient;

  CustomerWalletRemoteDataSource(this._apiClient);

  Future<ApiResponse<CustomerWalletModel>> fetchCustomerWallet() async {
    final response = await _apiClient.get(ApiConstants.customerWallet);
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => CustomerWalletModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<CustomerWalletModel>> createCustomerWallet() async {
    final response = await _apiClient.post(
      ApiConstants.customerWalletCreate,
      data: {},
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => CustomerWalletModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<CustomerWalletWithdrawalModel>> requestWithdrawal({
    required double amount,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.customerWalletWithdraw,
      data: {'amount': amount},
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => CustomerWalletWithdrawalModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<CustomerBankAccountModel?>> fetchBankAccount() async {
    try {
      final response = await _apiClient.get(ApiConstants.customerBankAccount);
      if (response.data == null) {
        return ApiResponse(success: true, message: 'No bank account found', data: null);
      }
      final resMap = Map<String, dynamic>.from(response.data as Map);
      final dataPayload = resMap['data'];
      if (dataPayload == null || dataPayload is! Map) {
        return ApiResponse(
          success: true,
          message: resMap['message']?.toString() ?? '',
          data: null,
        );
      }
      return ApiResponse.fromJson(
        resMap,
        (data) => CustomerBankAccountModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('404') || errStr.contains('not found')) {
        return ApiResponse(success: true, message: 'No bank account found', data: null);
      }
      rethrow;
    }
  }

  Future<ApiResponse<CustomerBankAccountModel>> addBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.customerBankAccount,
      data: {
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        if (bankRegisteredPhone != null && bankRegisteredPhone.isNotEmpty)
          'bankRegisteredPhone': bankRegisteredPhone.trim(),
      },
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => CustomerBankAccountModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<CustomerBankAccountModel>> updateBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.customerBankAccount,
      data: {
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        if (bankRegisteredPhone != null && bankRegisteredPhone.isNotEmpty)
          'bankRegisteredPhone': bankRegisteredPhone.trim(),
      },
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => CustomerBankAccountModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<dynamic>> deleteBankAccount() async {
    final response = await _apiClient.delete(ApiConstants.customerBankAccount);
    final resMap = Map<String, dynamic>.from(response.data as Map);
    return ApiResponse(
      success: true,
      message: resMap['message']?.toString() ?? 'Bank account deleted successfully',
      data: resMap['data'],
    );
  }
}
