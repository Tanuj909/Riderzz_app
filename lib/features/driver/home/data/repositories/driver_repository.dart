import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
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

  Future<DriverWalletModel> rechargeDriverWallet(double amount) async {
    return await _remoteDataSource.rechargeDriverWallet(amount);
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

  Future<void> applyDriver(Map<String, dynamic> data) async {
    await _remoteDataSource.applyDriver(data);
  }
}
