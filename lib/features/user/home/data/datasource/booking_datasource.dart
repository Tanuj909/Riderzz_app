import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/core/models/driver_location_model.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';

class BookingRemoteDataSource {
  final ApiClient _apiClient;

  BookingRemoteDataSource(this._apiClient);

  Future<BookingModel> createBooking(Map<String, dynamic> requestData) async {
    final response = await _apiClient.post(
      ApiConstants.bookings,
      data: requestData,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return BookingModel.fromJson(data);
  }

  Future<List<BookingModel>> fetchBookings() async {
    final response = await _apiClient.get(ApiConstants.bookings);
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    
    // Check if data is list or paginated object
    final dynamic rawData = resBody['data'];
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['content'] is List) {
      list = rawData['content'] as List;
    }
    
    return list.map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<BookingModel> getBookingById(int id) async {
    final response = await _apiClient.get('${ApiConstants.bookings}/$id');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> cancelBooking(int id, String reason) async {
    final response = await _apiClient.post(
      '${ApiConstants.bookings}/$id/cancel',
      data: {'reason': reason},
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return BookingModel.fromJson(data);
  }

  Future<List<BookingModel>> fetchCurrentBookings() async {
    final response = await _apiClient.get(ApiConstants.bookingsCurrent);
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

  Future<Map<String, dynamic>> fetchBookingOtp(int id) async {
    final response = await _apiClient.get('${ApiConstants.bookings}/$id/otp');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    return Map<String, dynamic>.from(resBody['data'] ?? {});
  }

  Future<DriverLocationModel> fetchDriverLocation(int driverId) async {
    final response = await _apiClient.get('/driver/location/$driverId');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return DriverLocationModel.fromJson(data);
  }

  Future<PricingTierModel> getApplicablePricingTier(int vehicleTypeId, double distanceKm) async {
    final response = await _apiClient.get(
      '/admin/pricing-tiers/applicable',
      queryParameters: {
        'vehicleTypeId': vehicleTypeId.toString(),
        'distanceKm': distanceKm.toString(),
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return PricingTierModel.fromJson(data);
  }
}
