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
      (data) {
        final list = data as List;
        return list.map((e) {
          final map = Map<String, dynamic>.from(e);
          
          final parts = <String>[];
          if (map['addressLine1'] != null && map['addressLine1'].toString().isNotEmpty) {
            parts.add(map['addressLine1']);
          }
          if (map['addressLine2'] != null && map['addressLine2'].toString().isNotEmpty) {
            parts.add(map['addressLine2']);
          }
          if (map['landmark'] != null && map['landmark'].toString().isNotEmpty) {
            parts.add(map['landmark']);
          }
          if (map['city'] != null && map['city'].toString().isNotEmpty) {
            parts.add(map['city']);
          }
          if (map['state'] != null && map['state'].toString().isNotEmpty) {
            parts.add(map['state']);
          }
          if (map['postalCode'] != null && map['postalCode'].toString().isNotEmpty) {
            parts.add(map['postalCode']);
          }
          if (map['country'] != null && map['country'].toString().isNotEmpty) {
            parts.add(map['country']);
          }
          final fullAddress = parts.join(', ');

          return {
            'id': map['id'],
            'label': map['label'] ?? map['addressType'] ?? 'Address',
            'address': fullAddress,
            'lat': map['latitude'] is num ? (map['latitude'] as num).toDouble() : 0.0,
            'lng': map['longitude'] is num ? (map['longitude'] as num).toDouble() : 0.0,
            'latitude': map['latitude'] is num ? (map['latitude'] as num).toDouble() : 0.0,
            'longitude': map['longitude'] is num ? (map['longitude'] as num).toDouble() : 0.0,
            'addressType': map['addressType'],
            'addressLine1': map['addressLine1'],
            'addressLine2': map['addressLine2'],
            'landmark': map['landmark'],
            'city': map['city'],
            'state': map['state'],
            'country': map['country'],
            'postalCode': map['postalCode'],
            'defaultAddress': map['defaultAddress'] ?? false,
            'contactPersonName': map['contactPersonName'],
            'contactPersonPhone': map['contactPersonPhone'],
          };
        }).toList();
      },
    );
  }

  Future<ApiResponse<dynamic>> addAddress(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.addresses,
      data: data,
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> updateAddress({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.addresses}/$id',
      data: data,
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> updateAddressContact({
    required int id,
    required int userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.addresses}/$id/contact?userId=$userId',
      data: data,
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> setDefaultAddress(int id) async {
    final response = await _apiClient.patch('${ApiConstants.addresses}/$id/default');
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> deleteAddress(int id) async {
    final response = await _apiClient.delete('${ApiConstants.addresses}/$id');
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }
}
