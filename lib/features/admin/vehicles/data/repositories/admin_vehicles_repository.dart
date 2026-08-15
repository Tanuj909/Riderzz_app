import 'dart:io';
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
    File? icon,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    bool active = true,
  }) async {
    return await _remoteDataSource.createVehicleType(
      name: name,
      icon: icon,
      maxWeightKg: maxWeightKg,
      minimumWalletBalance: minimumWalletBalance,
      tollEnabled: tollEnabled,
      dynamicPricingEnabled: dynamicPricingEnabled,
      active: active,
    );
  }

  Future<VehicleTypeModel> updateVehicleType({
    required int id,
    required String name,
    File? icon,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    bool active = true,
  }) async {
    return await _remoteDataSource.updateVehicleType(
      id: id,
      name: name,
      icon: icon,
      maxWeightKg: maxWeightKg,
      minimumWalletBalance: minimumWalletBalance,
      tollEnabled: tollEnabled,
      dynamicPricingEnabled: dynamicPricingEnabled,
      active: active,
    );
  }

  Future<void> deleteVehicleType(int id) async {
    await _remoteDataSource.deleteVehicleType(id);
  }

  // --- Registered Vehicles ---
  Future<Map<String, dynamic>> fetchRegisteredVehicles({
    String? status,
    int? vehicleTypeId,
    int page = 0,
    int size = 20,
  }) async {
    return await _remoteDataSource.fetchRegisteredVehicles(
      status: status,
      vehicleTypeId: vehicleTypeId,
      page: page,
      size: size,
    );
  }

  Future<void> updateRegisteredVehicleStatus(int id, String newStatus) async {
    await _remoteDataSource.updateRegisteredVehicleStatus(id, newStatus);
  }
}
