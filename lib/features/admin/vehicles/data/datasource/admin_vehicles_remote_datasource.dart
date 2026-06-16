import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';

class AdminVehiclesRemoteDataSource {
  final ApiClient _apiClient;

  AdminVehiclesRemoteDataSource(this._apiClient);

  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    final response = await _apiClient.get(ApiConstants.vehicleTypes);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final List<dynamic> data = resBody['data'] as List<dynamic>? ?? [];
    return data.map((json) => VehicleTypeModel.fromJson(Map<String, dynamic>.from(json))).toList();
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
    final response = await _apiClient.post(
      ApiConstants.vehicleTypes,
      data: {
        'name': name,
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'maxWeightKg': maxWeightKg,
        'commissionPct': commissionPct,
        'minWalletBalance': minWalletBalance,
        'description': description,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return VehicleTypeModel.fromJson(data);
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
    final response = await _apiClient.put(
      '${ApiConstants.vehicleTypes}/$id',
      data: {
        'name': name,
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'maxWeightKg': maxWeightKg,
        'commissionPct': commissionPct,
        'minWalletBalance': minWalletBalance,
        'description': description,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return VehicleTypeModel.fromJson(data);
  }

  Future<void> deleteVehicleType(int id) async {
    await _apiClient.delete('${ApiConstants.vehicleTypes}/$id');
  }
}
