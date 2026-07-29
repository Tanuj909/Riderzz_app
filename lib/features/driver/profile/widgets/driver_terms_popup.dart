import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverTermsPopup extends StatefulWidget {
  final VoidCallback onAccept;

  const DriverTermsPopup({super.key, required this.onAccept});

  @override
  State<DriverTermsPopup> createState() => _DriverTermsPopupState();
}

class _DriverTermsPopupState extends State<DriverTermsPopup> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEBEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFFE31C2E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partner Agreement',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Please read and agree to our Partner Terms and Conditions before proceeding to the registration form.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermItem('1. Licensing & Auth', 'You verify that you possess a valid commercial driving license, valid vehicle registration (RC), and active third-party insurance matching all details entered.'),
                      _buildTermItem('2. Safe Driving Policies', 'You agree to abide by all local transport and speed regulations. Operation of delivery services under the influence of illegal substances or alcohol will result in immediate partner ban.'),
                      _buildTermItem('3. Package Guidelines', 'You agree to inspect cargo for prohibited materials. Delivery of explosives, illegal drugs, weapons, or hazardous elements is strictly prohibited.'),
                      _buildTermItem('4. Customer Privacy', 'You agree to safeguard Riderzz customer data. You must never copy, store, share, or misuse customer phone numbers or pickup/drop addresses for private transactions.'),
                      _buildTermItem('5. Commission & Payouts', 'You accept the commission split model of Riderzz logistics and agree that funds will clear daily into verified bank accounts after administrative deductions.'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isAccepted,
                  activeColor: const Color(0xFFE31C2E),
                  onChanged: (val) {
                    setState(() {
                      _isAccepted = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I read and accept the Partner Terms & Conditions.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: const Color(0xFF475569),
                    ),
                    child: Text('Decline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAccepted
                        ? () {
                            Navigator.pop(context);
                            widget.onAccept();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFE31C2E),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text('Accept & Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }
}

void showDriverTermsAndConditionsPopup(BuildContext context, VoidCallback onAccept) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DriverTermsPopup(onAccept: onAccept),
  );
}
