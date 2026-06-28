import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';

class AdminVehiclesRemoteDataSource {
  final ApiClient _apiClient;

  AdminVehiclesRemoteDataSource(this._apiClient);

  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.vehicleTypes,
        queryParameters: {
          'activeOnly': 'true',
          'page': '0',
          'size': '20',
        },
      );
      final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
      final dynamic rawData = resBody['data'];
      List<dynamic> list = [];
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData['content'] is List) {
        list = rawData['content'] as List;
      }
      return list.map((json) => VehicleTypeModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      final response = await _apiClient.get(ApiConstants.vehicleTypes);
      final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
      final dynamic rawData = resBody['data'];
      List<dynamic> list = [];
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData['content'] is List) {
        list = rawData['content'] as List;
      }
      return list.map((json) => VehicleTypeModel.fromJson(Map<String, dynamic>.from(json))).toList();
    }
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
    final response = await _apiClient.post(
      ApiConstants.vehicleTypes,
      data: {
        'name': name,
        'iconUrl': iconUrl,
        'maxWeightKg': maxWeightKg,
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'minimumWalletBalance': minimumWalletBalance,
        'tollEnabled': tollEnabled,
        'dynamicPricingEnabled': dynamicPricingEnabled,
        'active': active,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return VehicleTypeModel.fromJson(data);
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
    final response = await _apiClient.put(
      '${ApiConstants.vehicleTypes}/$id',
      data: {
        'name': name,
        'iconUrl': iconUrl,
        'maxWeightKg': maxWeightKg,
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'minimumWalletBalance': minimumWalletBalance,
        'tollEnabled': tollEnabled,
        'dynamicPricingEnabled': dynamicPricingEnabled,
        'active': active,
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
