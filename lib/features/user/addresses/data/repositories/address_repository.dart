import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/user/addresses/data/datasource/address_remote_datasource.dart';

class AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepository(this._remoteDataSource);

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchAddresses() async {
    return await _remoteDataSource.fetchAddresses();
  }

  Future<ApiResponse<dynamic>> addAddress(Map<String, dynamic> data) async {
    return await _remoteDataSource.addAddress(data);
  }

  Future<ApiResponse<dynamic>> updateAddress({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    return await _remoteDataSource.updateAddress(
      id: id,
      data: data,
    );
  }

  Future<ApiResponse<dynamic>> deleteAddress(int id) async {
    return await _remoteDataSource.deleteAddress(id);
  }

  Future<ApiResponse<dynamic>> setDefaultAddress(int id) async {
    return await _remoteDataSource.setDefaultAddress(id);
  }
}
