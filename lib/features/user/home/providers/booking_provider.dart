import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/data/repositories/booking_repository.dart';
import 'package:riderzz_app/core/models/driver_location_model.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider(this._repository);

  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  List<BookingModel> _currentBookings = [];
  List<BookingModel> get currentBookings => _currentBookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  bool _hasMore = true;

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<void> fetchBookings({int page = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedBookings = await _repository.fetchBookings(
        page: page,
        size: 10,
      );
      _bookings = fetchedBookings;
      _currentPage = page;
      // If we got less than 10 items, there are no more pages.
      _hasMore = fetchedBookings.length == 10; 
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBookings = await _repository.fetchCurrentBookings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BookingModel?> createBooking(Map<String, dynamic> requestData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final booking = await _repository.createBooking(requestData);
      _bookings.insert(0, booking);
      notifyListeners();
      return booking;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<BookingModel?> fetchBookingById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final booking = await _repository.getBookingById(id);
      return booking;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(int id, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedBooking = await _repository.cancelBooking(id, reason);
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
      }

      // Refresh current bookings so active shipments list updates immediately
      try {
        _currentBookings = await _repository.fetchCurrentBookings();
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DriverLocationModel?> fetchDriverLocation(int driverId) async {
    try {
      final loc = await _repository.fetchDriverLocation(driverId);
      return loc;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchBookingOtp(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final otpData = await _repository.fetchBookingOtp(id);
      return otpData;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PricingTierModel?> getApplicablePricingTier(
    int vehicleTypeId,
    double distanceKm,
  ) async {
    try {
      return await _repository.getApplicablePricingTier(
        vehicleTypeId,
        distanceKm,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<bool> submitRating({
    required int bookingId,
    required String ratingType,
    required int stars,
    required String review,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.submitRating(
        bookingId: bookingId,
        ratingType: ratingType,
        stars: stars,
        review: review,
      );
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
