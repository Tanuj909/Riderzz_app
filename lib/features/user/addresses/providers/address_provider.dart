import 'package:flutter/material.dart';
import 'package:riderzz_app/app/constants/api_constants.dart';
import 'package:riderzz_app/core/api/dio_client.dart';

class AddressProvider extends ChangeNotifier {
  final DioClient _dioClient;

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  AddressProvider(this._dioClient);

  List<Map<String, dynamic>> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.get(ApiConstants.addresses);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(response.data);
        if (body['success'] == true) {
          final List<dynamic> list = body['data'] ?? [];
          _addresses = list.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _errorMessage = body['message'] ?? 'Failed to fetch addresses';
        }
      } else {
        _errorMessage = 'Failed to fetch addresses (Status: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.post(
        ApiConstants.addresses,
        data: {
          'label': label,
          'address': address,
          'lat': latitude,
          'lng': longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(response.data);
        if (body['success'] == true) {
          await fetchAddresses();
          return true;
        } else {
          _errorMessage = body['message'] ?? 'Failed to add address';
        }
      } else {
        _errorMessage = 'Failed to add address (Status: ${response.statusCode})';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress({
    required int id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.put(
        '${ApiConstants.addresses}/$id',
        data: {
          'label': label,
          'address': address,
          'lat': latitude,
          'lng': longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(response.data);
        if (body['success'] == true) {
          await fetchAddresses();
          return true;
        } else {
          _errorMessage = body['message'] ?? 'Failed to update address';
        }
      } else {
        _errorMessage = 'Failed to update address (Status: ${response.statusCode})';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.delete('${ApiConstants.addresses}/$id');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(response.data);
        if (body['success'] == true) {
          await fetchAddresses();
          return true;
        } else {
          _errorMessage = body['message'] ?? 'Failed to delete address';
        }
      } else {
        _errorMessage = 'Failed to delete address (Status: ${response.statusCode})';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
