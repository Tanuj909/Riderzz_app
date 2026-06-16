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
    required double baseFare,
    required double perKmRate,
    required int maxWeightKg,
    required double commissionPct,
    required double minWalletBalance,
    required String description,
  }) async {
    return await _remoteDataSource.createVehicleType(
      name: name,
      baseFare: baseFare,
      perKmRate: perKmRate,
      maxWeightKg: maxWeightKg,
      commissionPct: commissionPct,
      minWalletBalance: minWalletBalance,
      description: description,
    );
  }

  Future<VehicleTypeModel> updateVehicleType({
    required int id,
    required String name,
    required double baseFare,
    required double perKmRate,
    required int maxWeightKg,
    required double commissionPct,
    required double minWalletBalance,
    required String description,
  }) async {
    return await _remoteDataSource.updateVehicleType(
      id: id,
      name: name,
      baseFare: baseFare,
      perKmRate: perKmRate,
      maxWeightKg: maxWeightKg,
      commissionPct: commissionPct,
      minWalletBalance: minWalletBalance,
      description: description,
    );
  }

  Future<void> deleteVehicleType(int id) async {
    await _remoteDataSource.deleteVehicleType(id);
  }
}
