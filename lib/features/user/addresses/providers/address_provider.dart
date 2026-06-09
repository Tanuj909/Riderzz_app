import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  final List<Map<String, String>> _addresses = [
    {
      'title': 'Home',
      'address': 'Rohini Sector 15, Delhi - 110085',
      'type': 'home',
    },
    {
      'title': 'Office',
      'address': 'Cyber Hub, DLF Phase 2, Gurugram - 122002',
      'type': 'office',
    },
    {
      'title': 'Gym',
      'address': 'Gold\'s Gym, Connaught Place, New Delhi - 110001',
      'type': 'other',
    },
  ];

  List<Map<String, String>> get addresses => List.unmodifiable(_addresses);

  void addAddress(String title, String address, String type) {
    _addresses.add({
      'title': title,
      'address': address,
      'type': type,
    });
    notifyListeners();
  }

  void deleteAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      _addresses.removeAt(index);
      notifyListeners();
    }
  }
}
