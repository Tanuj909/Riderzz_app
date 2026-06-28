import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/features/admin/vehicles/data/models/admin_vehicle_model.dart';

class AdminVehiclesListRemoteDataSource {
  final ApiClient _apiClient;

  AdminVehiclesListRemoteDataSource(this._apiClient);

  Future<List<AdminVehicleModel>> getAllVehicles({int page = 0, int size = 20}) async {
    final response = await _apiClient.get(
      ApiConstants.adminVehicles,
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'createdAt,desc',
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
    return list.map((json) => AdminVehicleModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<AdminVehicleModel> getVehicleById(int id) async {
    final response = await _apiClient.get('${ApiConstants.adminVehicles}/$id');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return AdminVehicleModel.fromJson(data);
  }
}
