import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/data/datasource/admin_vehicles_remote_datasource.dart';

class AdminVehiclesRepository {
  final AdminVehiclesRemoteDataSource _remoteDataSource;

  AdminVehiclesRepository(this._remoteDataSource);

  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    return await _remoteDataSource.getAllVehicleTypes();
  }

  Future<VehicleTypeModel> createVehicleType({
    required String name,
    required String iconUrl,
    required int maxWeightKg,
    required double baseFare,
    required double perKmRate,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    required bool active,
  }) async {
    return await _remoteDataSource.createVehicleType(
      name: name,
      iconUrl: iconUrl,
      maxWeightKg: maxWeightKg,
      baseFare: baseFare,
      perKmRate: perKmRate,
      minimumWalletBalance: minimumWalletBalance,
      tollEnabled: tollEnabled,
      dynamicPricingEnabled: dynamicPricingEnabled,
      active: active,
    );
  }

  Future<VehicleTypeModel> updateVehicleType({
    required int id,
    required String name,
    required String iconUrl,
    required int maxWeightKg,
    required double baseFare,
    required double perKmRate,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    required bool active,
  }) async {
    return await _remoteDataSource.updateVehicleType(
      id: id,
      name: name,
      iconUrl: iconUrl,
      maxWeightKg: maxWeightKg,
      baseFare: baseFare,
      perKmRate: perKmRate,
      minimumWalletBalance: minimumWalletBalance,
      tollEnabled: tollEnabled,
      dynamicPricingEnabled: dynamicPricingEnabled,
      active: active,
    );
  }

  Future<void> deleteVehicleType(int id) async {
    await _remoteDataSource.deleteVehicleType(id);
  }
}
