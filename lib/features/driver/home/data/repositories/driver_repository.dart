import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/models/bank_account_model.dart';
import 'package:riderzz_app/features/driver/home/data/datasource/driver_remote_datasource.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/core/models/driver_earnings_model.dart';
import 'package:riderzz_app/core/models/driver_message_model.dart';


class DriverRepository {
  final DriverRemoteDataSource _remoteDataSource;

  DriverRepository(this._remoteDataSource);

  Future<DriverProfileModel> getDriverProfile() async {
    return await _remoteDataSource.getDriverProfile();
  }

  Future<DriverWalletModel> getDriverWallet() async {
    return await _remoteDataSource.getDriverWallet();
  }

  Future<DriverWalletModel> createDriverWallet() async {
    return await _remoteDataSource.createDriverWallet();
  }

  Future<RechargeInitiateResponse> initiateWalletRecharge(double amount) async {
    return await _remoteDataSource.initiateWalletRecharge(amount);
  }

  Future<void> verifyWalletRecharge(int rechargeId, String orderId, String paymentId, String signature) async {
    await _remoteDataSource.verifyWalletRecharge(rechargeId, orderId, paymentId, signature);
  }

  Future<bool> goOnline() async {
    return await _remoteDataSource.goOnline();
  }

  Future<bool> goOffline() async {
    return await _remoteDataSource.goOffline();
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    await _remoteDataSource.updateLocation(latitude, longitude);
  }

  Future<List<AvailableVehicleModel>> getAvailableVehicles() async {
    return await _remoteDataSource.getAvailableVehicles();
  }

  Future<DriverProfileModel> updateDriverProfile({
    required String licenseNumber,
    required String bio,
    required String gender,
    required String dob,
    String? upiId,
  }) async {
    return await _remoteDataSource.updateDriverProfile(
      licenseNumber: licenseNumber,
      bio: bio,
      gender: gender,
      dob: dob,
      upiId: upiId,
    );
  }

  Future<void> applyDriver(Map<String, dynamic> data) async {
    await _remoteDataSource.applyDriver(data);
  }

  Future<void> uploadDriverDocument(String docType, String filePath) async {
    await _remoteDataSource.uploadDriverDocument(docType, filePath);
  }

  Future<List<BankAccountModel>> getBankAccounts() async {
    return await _remoteDataSource.getBankAccounts();
  }

  Future<BankAccountModel> addBankAccount(Map<String, dynamic> data) async {
    return await _remoteDataSource.addBankAccount(data);
  }

  Future<BankAccountModel> updateBankAccount(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _remoteDataSource.updateBankAccount(id, data);
  }

  Future<void> deleteBankAccount(int id) async {
    await _remoteDataSource.deleteBankAccount(id);
  }

  Future<BankAccountModel?> getPrimaryBankAccount() async {
    return await _remoteDataSource.getPrimaryBankAccount();
  }

  Future<List<BookingModel>> getDriverBookings({int page = 0, int size = 20}) async {
    return await _remoteDataSource.fetchDriverBookings(page: page, size: size);
  }

  Future<List<BookingModel>> getAllBookings({int page = 0, int size = 20, String sort = 'createdAt,desc'}) async {
    return await _remoteDataSource.fetchAllBookings(page: page, size: size, sort: sort);
  }

  Future<void> verifyOtp(int bookingId, String otp) async {
    await _remoteDataSource.verifyOtp(bookingId, otp);
  }

  Future<BookingModel> updateBookingStatus(int bookingId, String status) async {
    return await _remoteDataSource.updateBookingStatus(bookingId, status);
  }

  Future<BookingModel> acceptBooking(int bookingId) async {
    return await _remoteDataSource.acceptBooking(bookingId);
  }

  Future<void> rejectBooking(int bookingId, String reason) async {
    await _remoteDataSource.rejectBooking(bookingId, reason);
  }

  Future<List<BookingModel>> getPendingBroadcasts() async {
    return await _remoteDataSource.fetchPendingBroadcasts();
  }

  Future<DriverEarningsModel> getDriverEarnings() async {
    return await _remoteDataSource.getDriverEarnings();
  }

  Future<List<DriverMessageModel>> getDriverMessages() async {
    return await _remoteDataSource.getDriverMessages();
  }

  Future<void> markMessagesAsRead() async {
    await _remoteDataSource.markMessagesAsRead();
  }
}
