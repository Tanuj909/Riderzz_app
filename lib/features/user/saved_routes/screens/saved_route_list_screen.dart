import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/addresses/address_list_screen.dart';

class SavedRouteListScreen extends StatelessWidget {
  final bool showBackButton;
  const SavedRouteListScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return AddressListScreen(
      showBackButton: showBackButton,
      initialTabIndex: 1,
    );
  }
}
