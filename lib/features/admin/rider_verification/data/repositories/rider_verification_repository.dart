import 'package:riderzz_app/features/admin/rider_verification/data/datasource/rider_verification_datasource.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';


class RiderVerificationRepository {
  final RiderVerificationRemoteDataSource _remoteDataSource;

  RiderVerificationRepository(this._remoteDataSource);

  Future<Map<String, dynamic>> getDrivers({
    required int page,
    required int size,
    required String status,
  }) async {
    return await _remoteDataSource.getDrivers(
      page: page,
      size: size,
      status: status,
    );
  }

  Future<AdminDriverModel> getDriverById(int userId) async {
    return await _remoteDataSource.getDriverById(userId);
  }

  Future<AdminDriverModel> updateDriverProfileAdmin({
    required int userId,
    required Map<String, dynamic> updateData,
  }) async {
    return await _remoteDataSource.updateDriverProfileAdmin(
      userId: userId,
      updateData: updateData,
    );
  }

  Future<void> updateDriverStatus({
    required int driverId,
    required String status,
    String? rejectionReason,
  }) async {
    await _remoteDataSource.updateDriverStatus(
      driverId: driverId,
      status: status,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> verifyDriverDocument({
    required int driverId,
    required int documentId,
    required String status,
    String? rejectionReason,
  }) async {
    await _remoteDataSource.verifyDriverDocument(
      driverId: driverId,
      documentId: documentId,
      status: status,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> forceDriverOffline(int driverId) async {
    await _remoteDataSource.forceDriverOffline(driverId);
  }

  Future<DriverWalletModel> getDriverWallet(int driverId) async {
    return await _remoteDataSource.getDriverWallet(driverId);
  }

  Future<void> adjustDriverWallet({
    required int driverId,
    required String type,
    required double amount,
    required String description,
  }) async {
    await _remoteDataSource.adjustDriverWallet(
      driverId: driverId,
      type: type,
      amount: amount,
      description: description,
    );
  }
}
