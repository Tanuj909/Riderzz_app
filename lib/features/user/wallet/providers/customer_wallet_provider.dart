import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_wallet_withdrawal_model.dart';
import 'package:riderzz_app/features/user/wallet/data/models/customer_bank_account_model.dart';
import 'package:riderzz_app/features/user/wallet/data/repositories/customer_wallet_repository.dart';

class CustomerWalletProvider extends ChangeNotifier {
  final CustomerWalletRepository _repository;

  CustomerWalletProvider(this._repository);

  CustomerWalletModel? _wallet;
  bool _isLoading = false;
  bool _isWithdrawing = false;
  String? _errorMessage;

  CustomerBankAccountModel? _bankAccount;
  bool _isBankAccountLoading = false;
  bool _isSavingBankAccount = false;
  String? _bankAccountError;

  CustomerWalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  bool get isWithdrawing => _isWithdrawing;
  String? get errorMessage => _errorMessage;

  CustomerBankAccountModel? get bankAccount => _bankAccount;
  bool get isBankAccountLoading => _isBankAccountLoading;
  bool get isSavingBankAccount => _isSavingBankAccount;
  String? get bankAccountError => _bankAccountError;

  Future<void> fetchCustomerWallet({bool force = false}) async {
    if (_wallet != null && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.fetchCustomerWallet();
      if (response.success && response.data != null) {
        _wallet = response.data;
        _errorMessage = null;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to fetch wallet';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBankAccount({bool force = false}) async {
    if (_bankAccount != null && !force) return;

    _isBankAccountLoading = true;
    _bankAccountError = null;
    notifyListeners();

    try {
      final response = await _repository.fetchBankAccount();
      _bankAccount = response.data;
      _bankAccountError = null;
    } catch (e) {
      _bankAccountError = e.toString();
    } finally {
      _isBankAccountLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) async {
    _isSavingBankAccount = true;
    _bankAccountError = null;
    notifyListeners();

    try {
      final response = await _repository.addBankAccount(
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        bankName: bankName,
        bankRegisteredPhone: bankRegisteredPhone,
      );
      if (response.data != null) {
        _bankAccount = response.data;
        _bankAccountError = null;
        return true;
      } else {
        _bankAccountError = response.message.isNotEmpty ? response.message : 'Failed to add bank account';
        return false;
      }
    } catch (e) {
      _bankAccountError = e.toString();
      return false;
    } finally {
      _isSavingBankAccount = false;
      notifyListeners();
    }
  }

  Future<bool> updateBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? bankRegisteredPhone,
  }) async {
    _isSavingBankAccount = true;
    _bankAccountError = null;
    notifyListeners();

    try {
      final response = await _repository.updateBankAccount(
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        bankName: bankName,
        bankRegisteredPhone: bankRegisteredPhone,
      );
      if (response.data != null) {
        _bankAccount = response.data;
        _bankAccountError = null;
        return true;
      } else {
        _bankAccountError = response.message.isNotEmpty ? response.message : 'Failed to update bank account';
        return false;
      }
    } catch (e) {
      _bankAccountError = e.toString();
      return false;
    } finally {
      _isSavingBankAccount = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBankAccount() async {
    _isSavingBankAccount = true;
    _bankAccountError = null;
    notifyListeners();

    try {
      await _repository.deleteBankAccount();
      _bankAccount = null;
      _bankAccountError = null;
      return true;
    } catch (e) {
      _bankAccountError = e.toString();
      return false;
    } finally {
      _isSavingBankAccount = false;
      notifyListeners();
    }
  }

  Future<CustomerWalletWithdrawalModel?> requestWithdrawal(double amount) async {
    _isWithdrawing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.requestWithdrawal(amount: amount);
      if (response.success && response.data != null) {
        // Refresh balance after initiating withdrawal
        await fetchCustomerWallet(force: true);
        return response.data;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Withdrawal request failed';
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isWithdrawing = false;
      notifyListeners();
    }
  }

  void clearData() {
    _wallet = null;
    _bankAccount = null;
    _isLoading = false;
    _isWithdrawing = false;
    _isBankAccountLoading = false;
    _isSavingBankAccount = false;
    _errorMessage = null;
    _bankAccountError = null;
    notifyListeners();
  }
}
