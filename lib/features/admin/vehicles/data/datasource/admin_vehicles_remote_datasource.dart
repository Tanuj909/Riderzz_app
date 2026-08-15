import 'dart:io';
import 'package:dio/dio.dart';
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

  Future<VehicleTypeModel> createVehicleType({
    required String name,
    File? icon,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    bool active = true,
  }) async {
    final Map<String, dynamic> formDataMap = {
      'name': name,
      'maxWeightKg': maxWeightKg.toString(),
      'minimumWalletBalance': minimumWalletBalance.toString(),
      'tollEnabled': tollEnabled.toString(),
      'dynamicPricingEnabled': dynamicPricingEnabled.toString(),
      'active': active.toString(),
    };

    if (icon != null) {
      formDataMap['icon'] = await MultipartFile.fromFile(icon.path);
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _apiClient.post(
      ApiConstants.vehicleTypes,
      data: formData,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return VehicleTypeModel.fromJson(data);
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
    final Map<String, dynamic> formDataMap = {
      'name': name,
      'maxWeightKg': maxWeightKg.toString(),
      'minimumWalletBalance': minimumWalletBalance.toString(),
      'tollEnabled': tollEnabled.toString(),
      'dynamicPricingEnabled': dynamicPricingEnabled.toString(),
      'active': active.toString(),
    };

    if (icon != null) {
      formDataMap['icon'] = await MultipartFile.fromFile(icon.path);
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _apiClient.put(
      '${ApiConstants.vehicleTypes}/$id',
      data: formData,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data']);
    return VehicleTypeModel.fromJson(data);
  }

  Future<void> deleteVehicleType(int id) async {
    await _apiClient.delete('${ApiConstants.vehicleTypes}/$id');
  }

  // --- Registered Vehicles (Driver Vehicles) ---
  Future<Map<String, dynamic>> fetchRegisteredVehicles({
    String? status,
    int? vehicleTypeId,
    int page = 0,
    int size = 20,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': 'createdAt,desc',
    };
    if (status != null && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (vehicleTypeId != null) {
      queryParams['vehicleTypeId'] = vehicleTypeId.toString();
    }

    final response = await _apiClient.get(
      '/admin/vehicles', // Using direct path as requested
      queryParameters: queryParams,
    );
    
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    return Map<String, dynamic>.from(resBody['data']);
  }

  Future<void> updateRegisteredVehicleStatus(int id, String newStatus) async {
    // Assuming PUT /api/admin/vehicles/{id} or similar with a status param or body
    // Using query param for now, common pattern: /api/admin/vehicles/1?status=APPROVED
    try {
      await _apiClient.put(
        '/admin/vehicles/$id',
        queryParameters: {'status': newStatus},
      );
    } catch (e) {
      // Fallback if it needs json body
      await _apiClient.put(
        '/admin/vehicles/$id',
        data: {'status': newStatus},
      );
    }
  }
}
