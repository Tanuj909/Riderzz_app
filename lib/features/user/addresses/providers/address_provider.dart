import 'package:flutter/material.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/features/user/addresses/data/repositories/address_repository.dart';

class AddressProvider extends ChangeNotifier {
  final AddressRepository _addressRepository;

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  AddressProvider(this._addressRepository);

  List<Map<String, dynamic>> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _addressRepository.fetchAddresses();
      if (response.success) {
        _addresses = response.data ?? [];
      } else {
        _errorMessage = response.message;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _addressRepository.addAddress(data);

      if (response.success) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
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
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _addressRepository.updateAddress(
        id: id,
        data: data,
      );

      if (response.success) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
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

  Future<bool> updateAddressContact({
    required int id,
    required int userId,
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _addressRepository.updateAddressContact(
        id: id,
        userId: userId,
        data: data,
      );

      if (response.success) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
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
      final response = await _addressRepository.deleteAddress(id);

      if (response.success) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
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

  Future<bool> setDefaultAddress(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _addressRepository.setDefaultAddress(id);

      if (response.success) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
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
