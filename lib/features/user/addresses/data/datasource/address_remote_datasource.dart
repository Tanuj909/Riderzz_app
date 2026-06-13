import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_response.dart';

class AddressRemoteDataSource {
  final ApiClient _apiClient;

  AddressRemoteDataSource(this._apiClient);

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchAddresses() async {
    final response = await _apiClient.get(ApiConstants.addresses);
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<ApiResponse<dynamic>> addAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.addresses,
      data: {
        'label': label,
        'address': address,
        'lat': latitude,
        'lng': longitude,
      },
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> updateAddress({
    required int id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.addresses}/$id',
      data: {
        'label': label,
        'address': address,
        'lat': latitude,
        'lng': longitude,
      },
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> deleteAddress(int id) async {
    final response = await _apiClient.delete('${ApiConstants.addresses}/$id');
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }
}
