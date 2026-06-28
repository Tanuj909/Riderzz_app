import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/user/saved_routes/data/datasource/saved_route_remote_datasource.dart';

class SavedRouteRepository {
  final SavedRouteRemoteDataSource _remoteDataSource;

  SavedRouteRepository(this._remoteDataSource);

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchSavedRoutes() async {
    return await _remoteDataSource.fetchSavedRoutes();
  }

  Future<ApiResponse<dynamic>> createSavedRoute({
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    return await _remoteDataSource.createSavedRoute(
      routeName: routeName,
      pickupAddressId: pickupAddressId,
      dropAddressId: dropAddressId,
    );
  }

  Future<ApiResponse<dynamic>> updateSavedRoute({
    required int id,
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    return await _remoteDataSource.updateSavedRoute(
      id: id,
      routeName: routeName,
      pickupAddressId: pickupAddressId,
      dropAddressId: dropAddressId,
    );
  }

  Future<ApiResponse<dynamic>> deleteSavedRoute(int id) async {
    return await _remoteDataSource.deleteSavedRoute(id);
  }
}
