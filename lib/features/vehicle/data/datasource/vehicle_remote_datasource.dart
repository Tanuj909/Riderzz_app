import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';

class VehicleRemoteDataSource {
  final ApiClient _apiClient;

  VehicleRemoteDataSource(this._apiClient);

  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.vehicleTypes,
        queryParameters: {
          'activeOnly': 'false',
          'page': '0',
          'size': '50',
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

  Future<List<VehicleTypeModel>> getVehicleTypesByCategory(String category) async {
    final response = await _apiClient.get(ApiConstants.vehicleTypesByCategory(category));
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

