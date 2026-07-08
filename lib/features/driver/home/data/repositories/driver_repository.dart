import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/models/bank_account_model.dart';
import 'package:riderzz_app/features/driver/home/data/datasource/driver_remote_datasource.dart';

class DriverRepository {
  final DriverRemoteDataSource _remoteDataSource;

  DriverRepository(this._remoteDataSource);

  Future<DriverProfileModel> getDriverProfile() async {
    return await _remoteDataSource.getDriverProfile();
  }

  Future<DriverWalletModel> getDriverWallet() async {
    return await _remoteDataSource.getDriverWallet();
  }

  Future<DriverWalletModel> createDriverWallet() async {
    return await _remoteDataSource.createDriverWallet();
  }

  Future<RechargeInitiateResponse> initiateWalletRecharge(double amount) async {
    return await _remoteDataSource.initiateWalletRecharge(amount);
  }

  Future<void> verifyWalletRecharge(int rechargeId, String orderId, String paymentId, String signature) async {
    await _remoteDataSource.verifyWalletRecharge(rechargeId, orderId, paymentId, signature);
  }

  Future<bool> goOnline() async {
    return await _remoteDataSource.goOnline();
  }

  Future<bool> goOffline() async {
    return await _remoteDataSource.goOffline();
  }

  Future<List<AvailableVehicleModel>> getAvailableVehicles() async {
    return await _remoteDataSource.getAvailableVehicles();
  }

  Future<DriverProfileModel> updateDriverProfile({
    required String licenseNumber,
    required String bio,
    required String gender,
    required String dob,
  }) async {
    return await _remoteDataSource.updateDriverProfile(
      licenseNumber: licenseNumber,
      bio: bio,
      gender: gender,
      dob: dob,
    );
  }

  Future<void> applyDriver(Map<String, dynamic> data) async {
    await _remoteDataSource.applyDriver(data);
  }

  Future<void> uploadDriverDocument(String docType, String filePath) async {
    await _remoteDataSource.uploadDriverDocument(docType, filePath);
  }

  Future<List<BankAccountModel>> getBankAccounts() async {
    return await _remoteDataSource.getBankAccounts();
  }

  Future<BankAccountModel> addBankAccount(Map<String, dynamic> data) async {
    return await _remoteDataSource.addBankAccount(data);
  }

  Future<BankAccountModel> updateBankAccount(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _remoteDataSource.updateBankAccount(id, data);
  }

  Future<void> deleteBankAccount(int id) async {
    await _remoteDataSource.deleteBankAccount(id);
  }

  Future<BankAccountModel?> getPrimaryBankAccount() async {
    return await _remoteDataSource.getPrimaryBankAccount();
  }
}
