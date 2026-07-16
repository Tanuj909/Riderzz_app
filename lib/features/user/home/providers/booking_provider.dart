import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/data/repositories/booking_repository.dart';

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

  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _repository.fetchBookings();
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
}
