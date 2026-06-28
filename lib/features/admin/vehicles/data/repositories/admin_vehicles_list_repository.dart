import 'package:riderzz_app/features/admin/vehicles/data/datasource/admin_vehicles_list_remote_datasource.dart';
import 'package:riderzz_app/features/admin/vehicles/data/models/admin_vehicle_model.dart';

class AdminVehiclesListRepository {
  final AdminVehiclesListRemoteDataSource _remoteDataSource;

  AdminVehiclesListRepository(this._remoteDataSource);

  Future<List<AdminVehicleModel>> getAllVehicles({int page = 0, int size = 20}) async {
    return await _remoteDataSource.getAllVehicles(page: page, size: size);
  }

  Future<AdminVehicleModel> getVehicleById(int id) async {
    return await _remoteDataSource.getVehicleById(id);
  }
}
