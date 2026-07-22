import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/core/models/bank_account_model.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';

class DriverBankAccountsPage extends StatefulWidget {
  const DriverBankAccountsPage({super.key});

  @override
  State<DriverBankAccountsPage> createState() => _DriverBankAccountsPageState();
}

class _DriverBankAccountsPageState extends State<DriverBankAccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHomeProvider>().fetchBankAccounts();
    });
  }

  void _showAddEditAccountDialog(BuildContext context, {BankAccountModel? account}) {
    final isEdit = account != null;
    final formKey = GlobalKey<FormState>();
    final holderNameController = TextEditingController(text: account?.accountHolderName ?? '');
    final accountNumberController = TextEditingController(text: account?.accountNumber ?? '');
    final ifscController = TextEditingController(text: account?.ifscCode ?? '');
    bool isPrimary = account?.primaryAccount ?? false;
    bool isSubmitting = false;

    final defaultBanks = [
      'State Bank of India (SBI)',
      'Bank of Baroda',
      'Punjab National Bank',
      'Canara Bank',
      'Union Bank of India',
      'Indian Bank',
      'Bank of India',
      'Central Bank of India',
      'UCO Bank',
      'Indian Overseas Bank',
      'Bank of Maharashtra',
      'Punjab & Sind Bank',
    ];

    final moreBanks = [
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Mahindra Bank',
      'IndusInd Bank',
      'IDBI Bank',
      'IDFC FIRST Bank',
      'Federal Bank',
      'Yes Bank',
      'Bandhan Bank',
      'RBL Bank',
      'South Indian Bank',
      'Karnataka Bank',
      'City Union Bank',
    ];

    // Initial value for dropdown
    String? selectedBank = account?.bankName;
    if (selectedBank != null && selectedBank.isEmpty) {
      selectedBank = null;
    }

    // Determine if we should initially show more banks (if the loaded bank is in the 'moreBanks' list)
    bool showMore = selectedBank != null && moreBanks.contains(selectedBank);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top indicator bar
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Dialog Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDF2F4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEdit ? Icons.edit_note_rounded : Icons.account_balance_rounded,
                                  color: const Color(0xFF8B1A2B),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  isEdit ? 'Update Bank Account' : 'Add Bank Account',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: const Color(0xFF121214),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF6C6F79)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Account Holder Name Field
                          TextFormField(
                            controller: holderNameController,
                            enabled: !isSubmitting,
                            style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: _buildInputDecoration('Account Holder Name'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter account holder name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Bank Name Dropdown Field
                          PopupMenuButton<String>(
                            tooltip: 'Select Bank',
                            offset: const Offset(0, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            color: Colors.white,
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 40,
                              maxWidth: MediaQuery.of(context).size.width - 40,
                            ),
                            onSelected: isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedBank = value;
                                    });
                                  },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(text: selectedBank),
                                decoration: _buildInputDecoration('Bank Name').copyWith(
                                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF8B1A2B), size: 28),
                                ),
                                style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 15, fontWeight: FontWeight.w600),
                                validator: (value) {
                                  if (selectedBank == null || selectedBank!.trim().isEmpty) {
                                    return 'Please select bank name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            itemBuilder: (popupContext) {
                              return [
                                PopupMenuItem<String>(
                                  enabled: false,
                                  child: StatefulBuilder(
                                    builder: (context, setPopupState) {
                                      final items = showMore 
                                          ? [...defaultBanks, ...moreBanks] 
                                          : [...defaultBanks];

                                      return Container(
                                        width: MediaQuery.of(context).size.width - 72,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              constraints: const BoxConstraints(maxHeight: 250),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  children: items.map((bank) {
                                                    final isSelected = selectedBank == bank;
                                                    return InkWell(
                                                      onTap: () {
                                                        Navigator.of(popupContext).pop(bank);
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                        decoration: BoxDecoration(
                                                          color: isSelected ? const Color(0xFFFDF2F4) : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          bank,
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 14,
                                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                            color: isSelected ? const Color(0xFF8B1A2B) : const Color(0xFF121214),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                            const Divider(height: 16, color: Color(0xFFF0F0F4)),
                                            InkWell(
                                              onTap: () {
                                                setPopupState(() {
                                                  showMore = !showMore;
                                                });
                                                setState(() {
                                                  showMore = showMore;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  showMore ? 'Show Less' : 'More+',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF8B1A2B),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ];
                            },
                          ),
                          const SizedBox(height: 16),

                          // Account Number Field
                          TextFormField(
                            controller: accountNumberController,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: _buildInputDecoration('Account Number'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter account number';
                              }
                              if (value.length < 9) {
                                return 'Account number should be at least 9 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // IFSC Code Field
                          TextFormField(
                            controller: ifscController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.characters,
                            style: GoogleFonts.outfit(color: const Color(0xFF121214), fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: _buildInputDecoration('IFSC Code'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter IFSC code';
                              }
                              if (value.length != 11) {
                                return 'IFSC code must be exactly 11 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Set Primary Switch
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Set as Primary Account',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1F),
                              ),
                            ),
                            subtitle: Text(
                              'Wallet payouts will go to this account.',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C6F79)),
                            ),
                            activeColor: const Color(0xFFCC2D3B),
                            activeTrackColor: const Color(0xFFFDEBEC),
                            value: isPrimary,
                            onChanged: isSubmitting
                                ? null
                                : (bool val) {
                                    setState(() {
                                      isPrimary = val;
                                    });
                                  },
                          ),
                          const SizedBox(height: 24),

                          // Dialog Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF6C6F79),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFCC2D3B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate()) return;

                                          setState(() {
                                            isSubmitting = true;
                                          });

                                          final provider = context.read<DriverHomeProvider>();
                                          final bodyData = {
                                            'accountHolderName': holderNameController.text.trim(),
                                            'bankName': selectedBank?.trim() ?? '',
                                            'accountNumber': accountNumberController.text.trim(),
                                            'ifscCode': ifscController.text.trim().toUpperCase(),
                                            'primaryAccount': isPrimary,
                                          };

                                          bool success;
                                          if (isEdit) {
                                            success = await provider.updateBankAccount(account.id, bodyData);
                                          } else {
                                            success = await provider.addBankAccount(bodyData);
                                          }

                                          if (success) {
                                            if (context.mounted) {
                                              Navigator.pop(dialogContext);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isEdit
                                                        ? 'Bank account updated successfully! 🎉'
                                                        : 'Bank account added successfully! 🎉',
                                                    style: GoogleFonts.outfit(),
                                                  ),
                                                  backgroundColor: const Color(0xFF1C9A5B),
                                                ),
                                              );
                                            }
                                          } else {
                                            setState(() {
                                              isSubmitting = false;
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    provider.bankAccountsError ?? 'An error occurred. Please try again.',
                                                    style: GoogleFonts.outfit(),
                                                  ),
                                                  backgroundColor: const Color(0xFFCC2D3B),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          isEdit ? 'Update' : 'Add Account',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, BankAccountModel account) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDEBEC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFCC2D3B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Account',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF121214), fontSize: 18),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to delete this bank account (${account.bankName} - ${account.accountNumber.length > 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber})?',
                style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC2D3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() {
                            isSubmitting = true;
                          });

                          final provider = context.read<DriverHomeProvider>();
                          final success = await provider.deleteBankAccount(account.id);

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bank account deleted successfully.', style: GoogleFonts.outfit()),
                                  backgroundColor: const Color(0xFF1C9A5B),
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Color(0xFFCC2D3B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Failed to Delete',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF121214)),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    provider.bankAccountsError ?? 'Could not delete bank account.',
                                    style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14, height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('OK', style: GoogleFonts.outfit(color: const Color(0xFFCC2D3B), fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF0F0F4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8B1A2B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCC2D3B), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCC2D3B), width: 1.5),
      ),
    );
  }

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    final masked = '•••• ' * ((number.length - 4) ~/ 4 + 1);
    return '$masked${number.substring(number.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverHomeProvider>(context);
    final bankAccounts = driverProvider.bankAccounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bank Accounts',
          style: GoogleFonts.outfit(
            color: const Color(0xFF121214),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFD90429), size: 22),
            onPressed: () => _showAddEditAccountDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverHomeProvider>().fetchBankAccounts(),
        color: const Color(0xFFD90429),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // List / State Handling
            if (driverProvider.isBankAccountsLoading && bankAccounts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                  ),
                ),
              )
            else if (driverProvider.bankAccountsError != null && bankAccounts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          driverProvider.bankAccountsError!,
                          style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31C2E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            context.read<DriverHomeProvider>().fetchBankAccounts();
                          },
                          child: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Info banner description block instead of duplicated header and add new button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDEBEC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD90429), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Wallet payouts will be sent to your primary bank account automatically.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFD90429),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (bankAccounts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            size: 48,
                            color: Color(0xFF9AA5B4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bank accounts configured yet.',
                          style: GoogleFonts.outfit(color: const Color(0xFF121214), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add an account to start receiving your wallet payouts.',
                          style: GoogleFonts.outfit(color: const Color(0xFF6C6F79), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = bankAccounts[index];
                        final isPrimary = account.primaryAccount;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPrimary ? const Color(0xFFD90429) : const Color(0xFFE7E7EB),
                              width: isPrimary ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF121214).withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Background pattern decorative gradient
                                if (isPrimary)
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 100,
                                      color: const Color(0xFFFDEBEC).withValues(alpha: 0.5),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Top Row: Bank Name and Badges
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  account.bankName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF121214),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'IFSC: ${account.ifscCode}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    color: const Color(0xFF6C6F79),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isPrimary)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFDEBEC),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFFD90429), width: 0.8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFFD90429)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'PRIMARY',
                                                    style: GoogleFonts.outfit(
                                                      color: const Color(0xFFD90429),
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Account Number Visual
                                      Text(
                                        _maskAccountNumber(account.accountNumber),
                                        style: GoogleFonts.outfit(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF121214),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Divider
                                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                                      const SizedBox(height: 10),

                                      // Bottom row: Holder name and action items
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ACCOUNT HOLDER',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF9AA5B4),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                account.accountHolderName,
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF4B5563),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFFD90429)),
                                                onPressed: () => _showAddEditAccountDialog(context, account: account),
                                                tooltip: 'Edit details',
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(8),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                                onPressed: () => _showDeleteConfirmDialog(context, account),
                                                tooltip: 'Delete account',
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(8),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: bankAccounts.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
