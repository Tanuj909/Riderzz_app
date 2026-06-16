import 'package:riderzz_app/features/admin/rider_verification/data/datasource/rider_verification_datasource.dart';

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
}
