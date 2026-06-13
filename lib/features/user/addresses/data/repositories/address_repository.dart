import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/user/addresses/data/datasource/address_remote_datasource.dart';

class AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepository(this._remoteDataSource);

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchAddresses() async {
    return await _remoteDataSource.fetchAddresses();
  }

  Future<ApiResponse<dynamic>> addAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return await _remoteDataSource.addAddress(
      label: label,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<ApiResponse<dynamic>> updateAddress({
    required int id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return await _remoteDataSource.updateAddress(
      id: id,
      label: label,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<ApiResponse<dynamic>> deleteAddress(int id) async {
    return await _remoteDataSource.deleteAddress(id);
  }
}
