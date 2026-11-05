import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/vehicle/data/datasource/vehicle_remote_datasource.dart';

class VehicleRepository {
  final VehicleRemoteDataSource _remoteDataSource;

  VehicleRepository(this._remoteDataSource);

  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    return await _remoteDataSource.getAllVehicleTypes();
  }

  Future<List<VehicleTypeModel>> getVehicleTypesByCategory(String category) async {
    return await _remoteDataSource.getVehicleTypesByCategory(category);
  }
}

