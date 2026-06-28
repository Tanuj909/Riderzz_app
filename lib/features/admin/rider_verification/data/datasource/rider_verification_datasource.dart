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
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
      'sort': 'createdAt,desc',
    };
    // Only add status filter if it's not 'ALL'
    if (status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.adminDriverList,
      queryParameters: queryParams,
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

  /// Fetches full driver profile by user ID.
  Future<AdminDriverModel> getDriverById(int userId) async {
    final response = await _apiClient.get(
      '${ApiConstants.adminDriverList.replaceAll('/list', '')}/$userId',
    );

    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return AdminDriverModel.fromJson(data);
  }

  /// Updates the driver approval status (APPROVED, REJECTED, SUSPENDED).
  Future<void> updateDriverStatus({
    required int driverId,
    required String status,
    String? rejectionReason,
  }) async {
    if (status == 'APPROVED') {
      await _apiClient.put(
        '${ApiConstants.adminDriverList.replaceAll('/list', '')}/$driverId/approve',
      );
    } else if (status == 'REJECTED') {
      await _apiClient.put(
        '${ApiConstants.adminDriverList.replaceAll('/list', '')}/$driverId/reject',
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

  /// Updates driver details as an admin.
  Future<AdminDriverModel> updateDriverProfileAdmin({
    required int userId,
    required Map<String, dynamic> updateData,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.adminDriverList.replaceAll('/list', '')}/$userId',
      data: updateData,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return AdminDriverModel.fromJson(data);
  }

  /// Verifies a specific driver document (APPROVED, REJECTED).
  Future<void> verifyDriverDocument({
    required int driverId,
    required int documentId,
    required String status,
    String? rejectionReason,
  }) async {
    final bool isApproved = status == 'APPROVED';
    final Map<String, dynamic> queryParams = {
      'approved': isApproved,
    };
    if (!isApproved && rejectionReason != null && rejectionReason.isNotEmpty) {
      queryParams['rejectionReason'] = rejectionReason;
    }

    await _apiClient.put(
      '${ApiConstants.adminDriverList.replaceAll('/list', '')}/documents/$documentId/verify',
      queryParameters: queryParams,
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
