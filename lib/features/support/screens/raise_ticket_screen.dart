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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Raise Support Ticket',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: supportProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading label for Categories
                    Text(
                      'SELECT CATEGORY',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Categories Grid UI
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
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
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFDF2F4) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFD90429) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'],
                                  color: isSelected ? const Color(0xFFD90429) : const Color(0xFF64748B),
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['label'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 10.5,
                                    color: isSelected ? const Color(0xFFD90429) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Priority Row
                    Text(
                      'PRIORITY',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _priorities.map((p) {
                        final isSelected = _selectedPriority == p['code'];
                        final Color pColor = p['color'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = p['code'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? pColor.withOpacity(0.12) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? pColor : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    p['label'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isSelected ? pColor : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Subject field
                    Text(
                      'SUBJECT',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                      style: GoogleFonts.outfit(fontSize: 14.5, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'E.g., Payment deducted but booking failed',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD90429), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Description
                    Text(
                      'DESCRIPTION',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write details of your query';
                        }
                        return null;
                      },
                      style: GoogleFonts.outfit(fontSize: 14.5, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Please detail what happened...',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD90429), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD90429),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Ticket',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
