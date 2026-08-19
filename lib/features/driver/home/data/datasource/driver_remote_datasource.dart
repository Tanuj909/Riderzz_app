import 'package:dio/dio.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/models/bank_account_model.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/core/models/driver_earnings_model.dart';
import 'package:riderzz_app/core/models/driver_message_model.dart';


class DriverRemoteDataSource {
  final ApiClient _apiClient;

  DriverRemoteDataSource(this._apiClient);

  Future<DriverProfileModel> getDriverProfile() async {
    final response = await _apiClient.get(ApiConstants.driverProfile);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final dynamic data = resBody['data'];
    if (data == null ||
        (data is Map && (data['userId'] == null || data['userId'] == 0))) {
      throw ApiException("Driver profile not found", statusCode: 404);
    }
    return DriverProfileModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<DriverWalletModel> getDriverWallet() async {
    final response = await _apiClient.get(ApiConstants.driverWallet);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      resBody['data'] ?? {},
    );

    try {
      final txResponse = await _apiClient.get(
        '${ApiConstants.driverWalletTransactions}?page=0&size=20',
      );
      final Map<String, dynamic> txResBody = Map<String, dynamic>.from(
        txResponse.data,
      );
      final Map<String, dynamic> txData = Map<String, dynamic>.from(
        txResBody['data'] ?? {},
      );
      data['transactions'] = txData['content'] as List? ?? [];
    } catch (e) {
      data['transactions'] = [];
    }

    return DriverWalletModel.fromJson(data);
  }

  Future<DriverWalletModel> createDriverWallet() async {
    final response = await _apiClient.post(ApiConstants.driverWalletCreate);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      resBody['data'] ?? {},
    );
    data['transactions'] = [];
    return DriverWalletModel.fromJson(data);
  }

  Future<RechargeInitiateResponse> initiateWalletRecharge(double amount) async {
    final response = await _apiClient.post(
      ApiConstants.walletRechargeInitiate,
      data: {'amount': amount},
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return RechargeInitiateResponse.fromJson(data);
  }

  Future<void> verifyWalletRecharge(int rechargeId, String orderId, String paymentId, String signature) async {
    await _apiClient.post(
      ApiConstants.walletRechargeVerify,
      data: {
        'rechargeId': rechargeId,
        'razorpayOrderId': orderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
      },
    );
  }

  Future<bool> goOnline() async {
    await _apiClient.patch('${ApiConstants.driverOnline}?online=true');
    return true;
  }

  Future<bool> goOffline() async {
    await _apiClient.patch('${ApiConstants.driverOnline}?online=false');
    return false;
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    await _apiClient.post(
      ApiConstants.driverLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<List<AvailableVehicleModel>> getAvailableVehicles() async {
    final response = await _apiClient.get(ApiConstants.availableVehicles);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final List<dynamic> list = resBody['data'] as List? ?? [];
    return list
        .map(
          (item) =>
              AvailableVehicleModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<DriverProfileModel> updateDriverProfile({
    required String licenseNumber,
    required String bio,
    required String gender,
    required String dob,
    String? upiId,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.driverProfile,
      data: {
        'licenseNumber': licenseNumber,
        'bio': bio,
        'gender': gender,
        'dob': dob,
        if (upiId != null) 'upiId': upiId,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      resBody['data'] ?? {},
    );
    return DriverProfileModel.fromJson(data);
  }

  Future<void> applyDriver(Map<String, dynamic> data) async {
    await _apiClient.post(ApiConstants.driverApply, data: data);
  }

  Future<void> uploadDriverDocument(String docType, String filePath) async {
    final formData = FormData.fromMap({
      'documentType': docType,
      'file': await MultipartFile.fromFile(filePath),
    });

    await _apiClient.post(ApiConstants.driverDocuments, data: formData);
  }

  Future<List<BankAccountModel>> getBankAccounts() async {
    final response = await _apiClient.get(ApiConstants.bankAccounts);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final List<dynamic> list = resBody['data'] as List? ?? [];
    return list
        .map(
          (item) => BankAccountModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<BankAccountModel> addBankAccount(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.bankAccounts,
      data: data,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
      resBody['data'] ?? {},
    );
    return BankAccountModel.fromJson(dataMap);
  }

  Future<BankAccountModel> updateBankAccount(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      '${ApiConstants.bankAccounts}/$id',
      data: data,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(
      response.data,
    );
    final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
      resBody['data'] ?? {},
    );
    return BankAccountModel.fromJson(dataMap);
  }

  Future<void> deleteBankAccount(int id) async {
    await _apiClient.delete('${ApiConstants.bankAccounts}/$id');
  }

  Future<BankAccountModel?> getPrimaryBankAccount() async {
    try {
      final response = await _apiClient.get(ApiConstants.primaryBankAccount);
      final Map<String, dynamic> resBody = Map<String, dynamic>.from(
        response.data,
      );
      if (resBody['data'] == null) return null;
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        resBody['data'],
      );
      return BankAccountModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel?> fetchActiveBooking() async {
    try {
      final response = await _apiClient.get(ApiConstants.driverActiveBooking);
      if (response.data != null && response.data['data'] != null) {
        return BookingModel.fromJson(Map<String, dynamic>.from(response.data['data']));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.message.toLowerCase().contains('not found')) {
        return null;
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<List<BookingModel>> fetchDriverBookings({int page = 0, int size = 20}) async {
    final response = await _apiClient.get('${ApiConstants.driverBookings}?page=$page&size=$size');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final dynamic rawData = resBody['data'];
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['content'] is List) {
      list = rawData['content'] as List;
    }
    return list.map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<List<BookingModel>> fetchAllBookings({int page = 0, int size = 20, String sort = 'createdAt,desc'}) async {
    final response = await _apiClient.get('${ApiConstants.bookingsAll}?page=$page&size=$size&sort=$sort');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final dynamic rawData = resBody['data'];
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['content'] is List) {
      list = rawData['content'] as List;
    }
    return list.map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<void> verifyOtp(int bookingId, String otp) async {
    await _apiClient.post(
      '${ApiConstants.driverBookings}/$bookingId/verify-otp',
      data: {'otp': otp},
    );
  }

  Future<BookingModel> updateBookingStatus(int bookingId, String status) async {
    final response = await _apiClient.patch(
      '${ApiConstants.driverBookings}/$bookingId/status',
      data: {'status': status},
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> acceptBooking(int bookingId) async {
    final response = await _apiClient.post(
      '${ApiConstants.driverBookings}/$bookingId/accept',
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return BookingModel.fromJson(data);
  }

  Future<void> rejectBooking(int bookingId, String reason) async {
    await _apiClient.post(
      '${ApiConstants.driverBookings}/$bookingId/reject',
      data: {'reason': reason},
    );
  }

  Future<void> cancelBooking(int bookingId, String reason) async {
    await _apiClient.post(
      '${ApiConstants.driverBookings}/$bookingId/cancel',
      data: {'reason': reason},
    );
  }

  Future<List<BookingModel>> fetchPendingBroadcasts() async {
    final response = await _apiClient.get(ApiConstants.driverPendingBroadcasts);
    dynamic rawData;
    if (response.data is List) {
      rawData = response.data;
    } else if (response.data is Map) {
      final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
      rawData = resBody['data'] ?? resBody['content'] ?? resBody;
    }
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['content'] is List) {
      list = rawData['content'] as List;
    }
    return list.map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<DriverEarningsModel> getDriverEarnings() async {
    final response = await _apiClient.get(ApiConstants.driverEarnings);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverEarningsModel.fromJson(data);
  }

  Future<List<DriverMessageModel>> getDriverMessages() async {
    final response = await _apiClient.get(ApiConstants.driverMessages);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final List<dynamic> list = resBody['data'] as List? ?? [];
    return list
        .map((json) => DriverMessageModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> markMessagesAsRead() async {
    await _apiClient.put(ApiConstants.driverMessagesRead);
  }
}
