import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';

class RiderVerificationRemoteDataSource {
  final ApiClient _apiClient;

  RiderVerificationRemoteDataSource(this._apiClient);

  /// Fetches a paginated list of drivers filtered by approval status.
  Future<Map<String, dynamic>> getDrivers({
    required int page,
    required int size,
    required String status,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.adminDrivers,
      queryParameters: {
        'page': page,
        'size': size,
        'status': status,
      },
    );

    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    final List<dynamic> content = data['content'] as List<dynamic>? ?? [];
    
    final List<AdminDriverModel> drivers = content
        .map((json) => AdminDriverModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    return {
      'drivers': drivers,
      'totalPages': data['totalPages'] as int? ?? 1,
      'totalElements': data['totalElements'] as int? ?? 0,
      'isLast': data['last'] as bool? ?? true,
      'pageNumber': data['number'] as int? ?? 0,
    };
  }

  /// Updates the driver approval status (APPROVED, REJECTED, SUSPENDED, UNDER_REVIEW).
  Future<void> updateDriverStatus({
    required int driverId,
    required String status,
    String? rejectionReason,
  }) async {
    await _apiClient.put(
      '${ApiConstants.adminDrivers}/$driverId/status',
      data: {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      },
    );
  }
}
