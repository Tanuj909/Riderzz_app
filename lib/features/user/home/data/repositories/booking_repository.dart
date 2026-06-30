import 'package:riderzz_app/features/user/home/data/datasource/booking_datasource.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';

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
}
