import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';

class DriverRemoteDataSource {
  final ApiClient _apiClient;

  DriverRemoteDataSource(this._apiClient);

  Future<DriverProfileModel> getDriverProfile() async {
    final response = await _apiClient.get(ApiConstants.driverProfile);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverProfileModel.fromJson(data);
  }

  Future<DriverWalletModel> getDriverWallet() async {
    final response = await _apiClient.get(ApiConstants.driverWallet);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverWalletModel.fromJson(data);
  }

  Future<DriverWalletModel> rechargeDriverWallet(double amount) async {
    final response = await _apiClient.post(
      ApiConstants.driverWalletRecharge,
      data: {'amount': amount},
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverWalletModel.fromJson(data);
  }

  Future<bool> goOnline() async {
    final response = await _apiClient.patch(ApiConstants.driverOnline);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return data['isOnline'] as bool? ?? false;
  }

  Future<bool> goOffline() async {
    final response = await _apiClient.patch(ApiConstants.driverOffline);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return data['isOnline'] as bool? ?? false;
  }

  Future<List<AvailableVehicleModel>> getAvailableVehicles() async {
    final response = await _apiClient.get(ApiConstants.availableVehicles);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final List<dynamic> list = resBody['data'] as List? ?? [];
    return list.map((item) => AvailableVehicleModel.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> applyDriver(Map<String, dynamic> data) async {
    await _apiClient.post(
      ApiConstants.driverApply,
      data: data,
    );
  }

  Future<void> uploadDriverDocument(String docType, String fileUrl) async {
    await _apiClient.post(
      ApiConstants.driverDocuments,
      data: {
        'documentType': docType,
        'fileUrl': fileUrl,
      },
    );
  }

  Future<List<DriverDocumentModel>> getDriverDocuments() async {
    final response = await _apiClient.get(ApiConstants.driverDocuments);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final List<dynamic> list = resBody['data'] as List? ?? [];
    return list
        .map((item) => DriverDocumentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
