import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_response.dart';

class SavedRouteRemoteDataSource {
  final ApiClient _apiClient;

  SavedRouteRemoteDataSource(this._apiClient);

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchSavedRoutes() async {
    final response = await _apiClient.get(ApiConstants.savedRoutes);
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) {
        final list = data as List;
        return list.map((e) {
          final map = Map<String, dynamic>.from(e);
          final pickup = Map<String, dynamic>.from(map['pickupAddress'] ?? {});
          final drop = Map<String, dynamic>.from(map['dropAddress'] ?? {});
          
          final pickupParts = <String>[];
          if (pickup['addressLine1'] != null && pickup['addressLine1'].toString().isNotEmpty) {
            pickupParts.add(pickup['addressLine1']);
          }
          if (pickup['addressLine2'] != null && pickup['addressLine2'].toString().isNotEmpty) {
            pickupParts.add(pickup['addressLine2']);
          }
          if (pickup['landmark'] != null && pickup['landmark'].toString().isNotEmpty) {
            pickupParts.add(pickup['landmark']);
          }
          if (pickup['city'] != null && pickup['city'].toString().isNotEmpty) {
            pickupParts.add(pickup['city']);
          }
          if (pickup['state'] != null && pickup['state'].toString().isNotEmpty) {
            pickupParts.add(pickup['state']);
          }
          if (pickup['postalCode'] != null && pickup['postalCode'].toString().isNotEmpty) {
            pickupParts.add(pickup['postalCode']);
          }
          if (pickup['country'] != null && pickup['country'].toString().isNotEmpty) {
            pickupParts.add(pickup['country']);
          }
          final pickupFullAddress = pickupParts.join(', ');

          final dropParts = <String>[];
          if (drop['addressLine1'] != null && drop['addressLine1'].toString().isNotEmpty) {
            dropParts.add(drop['addressLine1']);
          }
          if (drop['addressLine2'] != null && drop['addressLine2'].toString().isNotEmpty) {
            dropParts.add(drop['addressLine2']);
          }
          if (drop['landmark'] != null && drop['landmark'].toString().isNotEmpty) {
            dropParts.add(drop['landmark']);
          }
          if (drop['city'] != null && drop['city'].toString().isNotEmpty) {
            dropParts.add(drop['city']);
          }
          if (drop['state'] != null && drop['state'].toString().isNotEmpty) {
            dropParts.add(drop['state']);
          }
          if (drop['postalCode'] != null && drop['postalCode'].toString().isNotEmpty) {
            dropParts.add(drop['postalCode']);
          }
          if (drop['country'] != null && drop['country'].toString().isNotEmpty) {
            dropParts.add(drop['country']);
          }
          final dropFullAddress = dropParts.join(', ');

          final mappedPickup = {
            ...pickup,
            'address': pickupFullAddress,
            'lat': pickup['latitude'] is num ? (pickup['latitude'] as num).toDouble() : 0.0,
            'lng': pickup['longitude'] is num ? (pickup['longitude'] as num).toDouble() : 0.0,
          };

          final mappedDrop = {
            ...drop,
            'address': dropFullAddress,
            'lat': drop['latitude'] is num ? (drop['latitude'] as num).toDouble() : 0.0,
            'lng': drop['longitude'] is num ? (drop['longitude'] as num).toDouble() : 0.0,
          };

          return {
            'id': map['id'],
            'routeName': map['routeName'] ?? '',
            'pickupAddress': mappedPickup,
            'dropAddress': mappedDrop,
          };
        }).toList();
      },
    );
  }

  Future<ApiResponse<dynamic>> createSavedRoute({
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.savedRoutes,
      data: {
        'routeName': routeName,
        'pickupAddressId': pickupAddressId,
        'dropAddressId': dropAddressId,
      },
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> updateSavedRoute({
    required int id,
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.savedRoutes}/$id',
      data: {
        'routeName': routeName,
        'pickupAddressId': pickupAddressId,
        'dropAddressId': dropAddressId,
      },
    );
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }

  Future<ApiResponse<dynamic>> deleteSavedRoute(int id) async {
    final response = await _apiClient.delete('${ApiConstants.savedRoutes}/$id');
    return ApiResponse.fromJson(Map<String, dynamic>.from(response.data), (data) => data);
  }
}
