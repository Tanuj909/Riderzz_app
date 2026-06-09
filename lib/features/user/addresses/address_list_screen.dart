import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  void _deleteAddress(int index) {
    Provider.of<AddressProvider>(context, listen: false).deleteAddress(index);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address deleted successfully')),
    );
  }

  void _addAddress(String title, String address, String type) {
    Provider.of<AddressProvider>(context, listen: false).addAddress(title, address, type);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address added successfully')),
    );
  }

  void _showAddAddressBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'home'; // default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2233),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7785)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title Field
                    const Text(
                      'Address Title',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        border: Border.all(color: const Color(0xFFE9ECF0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextFormField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233)),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Friend\'s House, Gym',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    const Text(
                      'Full Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        border: Border.all(color: const Color(0xFFE9ECF0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextFormField(
                        controller: addressController,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2233)),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter full location details',
                          hintStyle: TextStyle(color: Color(0xFFB0B8C4)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Picker
                    const Text(
                      'Address Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7785),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTypeChip(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          isSelected: selectedType == 'home',
                          onTap: () => setModalState(() => selectedType = 'home'),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          label: 'Office',
                          icon: Icons.business_rounded,
                          isSelected: selectedType == 'office',
                          onTap: () => setModalState(() => selectedType = 'office'),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          label: 'Other',
                          icon: Icons.location_on_rounded,
                          isSelected: selectedType == 'other',
                          onTap: () => setModalState(() => selectedType = 'other'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D6B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final address = addressController.text.trim();
                          if (title.isEmpty || address.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out all fields')),
                            );
                            return;
                          }
                          _addAddress(title, address, selectedType);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Save Address',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F0FB) : const Color(0xFFF7F8FA),
            border: Border.all(
              color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFFE9ECF0),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF6B7785),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFF1A3D6B) : const Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final addresses = addressProvider.addresses;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D6B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Color(0xFFB0B8C4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Addresses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2233),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Save your locations for instant booking.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7785),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3D6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showAddAddressBottomSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Address'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final item = addresses[index];
                final type = item['type'];

                IconData leadIcon = Icons.location_on_rounded;
                Color leadBg = const Color(0xFFFFF3E8);
                Color leadIconColor = const Color(0xFFF97316);

                if (type == 'home') {
                  leadIcon = Icons.home_rounded;
                  leadBg = const Color(0xFFE6F7F2);
                  leadIconColor = const Color(0xFF0F9B6E);
                } else if (type == 'office') {
                  leadIcon = Icons.business_rounded;
                  leadBg = const Color(0xFFE8F0FB);
                  leadIconColor = const Color(0xFF1A3D6B);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE9ECF0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: leadBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(leadIcon, color: leadIconColor, size: 20),
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2233),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        item['address'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7785),
                          height: 1.4,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () => _deleteAddress(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddAddressBottomSheet(context),
              backgroundColor: const Color(0xFF1A3D6B),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}
