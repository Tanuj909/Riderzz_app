import 'package:riderzz_app/features/user/home/data/datasource/booking_datasource.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/core/models/driver_location_model.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';

class BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepository(this._remoteDataSource);

  Future<BookingModel> createBooking(Map<String, dynamic> requestData) async {
    return await _remoteDataSource.createBooking(requestData);
  }

  Future<List<BookingModel>> fetchBookings() async {
    return await _remoteDataSource.fetchBookings();
  }

  Future<BookingModel> getBookingById(int id) async {
    return await _remoteDataSource.getBookingById(id);
  }

  Future<BookingModel> cancelBooking(int id, String reason) async {
    return await _remoteDataSource.cancelBooking(id, reason);
  }

  Future<List<BookingModel>> fetchCurrentBookings() async {
    return await _remoteDataSource.fetchCurrentBookings();
  }

  Future<Map<String, dynamic>> fetchBookingOtp(int id) async {
    return await _remoteDataSource.fetchBookingOtp(id);
  }

  Future<DriverLocationModel> fetchDriverLocation(int driverId) async {
    return await _remoteDataSource.fetchDriverLocation(driverId);
  }

  Future<PricingTierModel> getApplicablePricingTier(
    int vehicleTypeId,
    double distanceKm,
  ) async {
    return await _remoteDataSource.getApplicablePricingTier(
      vehicleTypeId,
      distanceKm,
    );
  }

  Future<bool> submitRating({
    required int bookingId,
    required String ratingType,
    required int stars,
    required String review,
  }) async {
    return await _remoteDataSource.submitRating(
      bookingId: bookingId,
      ratingType: ratingType,
      stars: stars,
      review: review,
    );
  }
}
