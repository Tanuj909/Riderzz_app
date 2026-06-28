import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/commission_config_model.dart';

class CommissionRemoteDataSource {
  final ApiClient _apiClient;

  CommissionRemoteDataSource(this._apiClient);

  Future<List<CommissionConfigModel>> getCommissionConfigs() async {
    final response = await _apiClient.get(ApiConstants.adminCommissionConfigs);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final List<dynamic> dataList = List<dynamic>.from(resBody['data'] ?? []);
    return dataList.map((json) => CommissionConfigModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<CommissionConfigModel> createCommissionConfig({
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.adminCommissionConfigs,
      data: {
        'vehicleTypeId': vehicleTypeId,
        'commissionPercent': commissionPercent,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return CommissionConfigModel.fromJson(data);
  }

  Future<CommissionConfigModel> updateCommissionConfig({
    required int configId,
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.adminCommissionConfigs}/$configId',
      data: {
        'vehicleTypeId': vehicleTypeId,
        'commissionPercent': commissionPercent,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return CommissionConfigModel.fromJson(data);
  }

  Future<void> deleteCommissionConfig(int configId) async {
    await _apiClient.delete(
      '${ApiConstants.adminCommissionConfigs}/$configId',
    );
  }
}
