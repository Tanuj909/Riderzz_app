import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/support/providers/support_provider.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = "BOOKING";
  String _selectedPriority = "MEDIUM";

  final List<Map<String, dynamic>> _categories = [
    {'code': 'BOOKING', 'label': 'Booking', 'icon': Icons.local_shipping_rounded},
    {'code': 'PAYMENT', 'label': 'Payment', 'icon': Icons.payment_rounded},
    {'code': 'WALLET', 'label': 'Wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'code': 'DRIVER', 'label': 'Driver', 'icon': Icons.person_rounded},
    {'code': 'VEHICLE', 'label': 'Vehicle', 'icon': Icons.directions_car_rounded},
    {'code': 'ACCOUNT', 'label': 'Account', 'icon': Icons.manage_accounts_rounded},
    {'code': 'TECHNICAL', 'label': 'Technical', 'icon': Icons.phonelink_setup_rounded},
    {'code': 'OTHER', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'code': 'LOW', 'label': 'Low', 'color': Color(0xFF6B7280)},
    {'code': 'MEDIUM', 'label': 'Medium', 'color': Color(0xFF3B82F6)},
    {'code': 'HIGH', 'label': 'High', 'color': Color(0xFFF59E0B)},
    {'code': 'CRITICAL', 'label': 'Critical', 'color': Color(0xFFEF4444)},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SupportProvider>();
    final ticket = await provider.createTicket(
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
    );

    if (mounted) {
      if (ticket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket raised successfully! 🎟️'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to submit ticket. Please try again.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 18),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Raise Ticket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: supportProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How can we help you?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121214),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please fill out the details below to raise a support ticket.',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF6C6F79),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // CATEGORY
                            _buildSectionLabel('Select Category'),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.8,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected = _selectedCategory == cat['code'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = cat['code'];
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE31C2E).withOpacity(0.08) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFFE7E7EB),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cat['icon'],
                                          color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF6C6F79),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            cat['label'],
                                            style: GoogleFonts.outfit(
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 14,
                                              color: isSelected ? const Color(0xFFE31C2E) : const Color(0xFF121214),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // PRIORITY
                            _buildSectionLabel('Priority Level'),
                            const SizedBox(height: 12),
                            Row(
                              children: _priorities.map((p) {
                                final isSelected = _selectedPriority == p['code'];
                                final Color pColor = p['color'];
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedPriority = p['code'];
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? pColor : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? pColor : const Color(0xFFE7E7EB),
                                            width: 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: pColor.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            p['label'],
                                            style: GoogleFonts.outfit(
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 13,
                                              color: isSelected ? Colors.white : const Color(0xFF6C6F79),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),

                            // SUBJECT
                            _buildSectionLabel('Subject'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _subjectController,
                              hintText: 'e.g., Issue with recent booking payment',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Subject is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // DESCRIPTION
                            _buildSectionLabel('Description'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _descriptionController,
                              hintText: 'Please describe your issue in detail...',
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Description is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),

                            // SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _submitTicket,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31C2E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFFE31C2E).withOpacity(0.4),
                                ),
                                child: Text(
                                  'Submit Ticket',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF121214),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF121214), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFFB0B8C4), fontSize: 14, fontWeight: FontWeight.w400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE31C2E), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
          ),
        ),
      ),
    );
  }
}
