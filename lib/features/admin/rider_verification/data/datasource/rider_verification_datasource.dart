import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';

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

  /// Updates the driver approval status (APPROVED, REJECTED, SUSPENDED).
  Future<void> updateDriverStatus({
    required int driverId,
    required String status,
    String? rejectionReason,
  }) async {
    if (status == 'APPROVED') {
      await _apiClient.patch(
        '${ApiConstants.adminDrivers}/$driverId/approve',
      );
    } else if (status == 'REJECTED') {
      await _apiClient.patch(
        '${ApiConstants.adminDrivers}/$driverId/reject',
        data: {
          'reason': rejectionReason ?? 'Application rejected',
        },
      );
    } else if (status == 'SUSPENDED') {
      await _apiClient.patch(
        '${ApiConstants.adminDrivers}/$driverId/suspend',
      );
    } else if (status == 'ACTIVATED') {
      await _apiClient.patch(
        '${ApiConstants.adminDrivers}/$driverId/activate',
      );
    } else {
      throw Exception('Unsupported driver status action: $status');
    }
  }

  /// Verifies a specific driver document (APPROVED, REJECTED).
  Future<void> verifyDriverDocument({
    required int driverId,
    required int documentId,
    required String status,
    String? rejectionReason,
  }) async {
    await _apiClient.patch(
      '${ApiConstants.adminDrivers}/$driverId/documents/$documentId/verify',
      data: {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      },
    );
  }

  /// Forces a driver offline.
  Future<void> forceDriverOffline(int driverId) async {
    await _apiClient.patch(
      '${ApiConstants.adminDrivers}/$driverId/offline',
    );
  }

  /// Fetches a driver's wallet details.
  Future<DriverWalletModel> getDriverWallet(int driverId) async {
    final response = await _apiClient.get(
      '${ApiConstants.adminDrivers}/$driverId/wallet',
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverWalletModel.fromJson(data);
  }

  /// Adjusts a driver's wallet balance.
  Future<void> adjustDriverWallet({
    required int driverId,
    required String type,
    required double amount,
    required String description,
  }) async {
    await _apiClient.post(
      '${ApiConstants.adminDrivers}/$driverId/wallet/adjust',
      data: {
        'type': type,
        'amount': amount,
        'description': description,
      },
    );
  }
}
