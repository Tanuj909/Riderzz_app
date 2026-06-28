import 'package:riderzz_app/features/admin/commission/data/datasource/commission_datasource.dart';
import 'package:riderzz_app/core/models/commission_config_model.dart';

class CommissionRepository {
  final CommissionRemoteDataSource _remoteDataSource;

  CommissionRepository(this._remoteDataSource);

  Future<List<CommissionConfigModel>> getCommissionConfigs() async {
    return await _remoteDataSource.getCommissionConfigs();
  }

  Future<CommissionConfigModel> createCommissionConfig({
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    return await _remoteDataSource.createCommissionConfig(
      vehicleTypeId: vehicleTypeId,
      commissionPercent: commissionPercent,
    );
  }

  Future<CommissionConfigModel> updateCommissionConfig({
    required int configId,
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    return await _remoteDataSource.updateCommissionConfig(
      configId: configId,
      vehicleTypeId: vehicleTypeId,
      commissionPercent: commissionPercent,
    );
  }

  Future<void> deleteCommissionConfig(int configId) async {
    await _remoteDataSource.deleteCommissionConfig(configId);
  }
}
