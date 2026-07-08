import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final bankNameController = TextEditingController(text: account?.bankName ?? '');
    final accountNumberController = TextEditingController(text: account?.accountNumber ?? '');
    final ifscController = TextEditingController(text: account?.ifscCode ?? '');
    bool isPrimary = account?.primaryAccount ?? false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dialog Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEBEC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isEdit ? Icons.edit_note_rounded : Icons.account_balance_rounded,
                                color: const Color(0xFF1E3A8A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit ? 'Update Bank Account' : 'Add Bank Account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF121214),
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
                        const SizedBox(height: 20),

                        // Account Holder Name Field
                        TextFormField(
                          controller: holderNameController,
                          enabled: !isSubmitting,
                          style: const TextStyle(color: Color(0xFF121214), fontSize: 14),
                          decoration: _buildInputDecoration('Account Holder Name', Icons.person_outline_rounded),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter account holder name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Bank Name Field
                        TextFormField(
                          controller: bankNameController,
                          enabled: !isSubmitting,
                          style: const TextStyle(color: Color(0xFF121214), fontSize: 14),
                          decoration: _buildInputDecoration('Bank Name', Icons.account_balance_outlined),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter bank name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Account Number Field
                        TextFormField(
                          controller: accountNumberController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF121214), fontSize: 14),
                          decoration: _buildInputDecoration('Account Number', Icons.numbers_rounded),
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
                        const SizedBox(height: 14),

                        // IFSC Code Field
                        TextFormField(
                          controller: ifscController,
                          enabled: !isSubmitting,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Color(0xFF121214), fontSize: 14),
                          decoration: _buildInputDecoration('IFSC Code', Icons.qr_code_2_rounded),
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
                          title: const Text(
                            'Set as Primary Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          subtitle: const Text(
                            'Wallet payouts will go to this account.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                          activeThumbColor: const Color(0xFF1E3A8A),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          'bankName': bankNameController.text.trim(),
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
                                                ),
                                                backgroundColor: const Color(0xFF10B981),
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
                                                ),
                                                backgroundColor: Colors.redAccent,
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
                                        isEdit ? 'Update' : 'Add',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
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
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Delete Account',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to delete this bank account (${account.bankName} - ${account.accountNumber.length > 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber})?',
                style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C6F79))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
                                const SnackBar(
                                  content: Text('Bank account deleted successfully.'),
                                  backgroundColor: Color(0xFF10B981),
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
                                  surfaceTintColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: const [
                                      Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'Failed to Delete',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    provider.bankAccountsError ?? 'Could not delete bank account.',
                                    style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF6C6F79), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFE31C2E), size: 18),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
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
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverHomeProvider>().fetchBankAccounts(),
        color: const Color(0xFF1E3A8A),
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
                          style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
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
                          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Header description block
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Bank Accounts',
                            style: TextStyle(
                              color: Color(0xFF121214),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage payout endpoints (${bankAccounts.length} added)',
                            style: const TextStyle(
                              color: Color(0xFF6C6F79),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _showAddEditAccountDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                        const Text(
                          'No bank accounts configured yet.',
                          style: TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add an account to start receiving your wallet payouts.',
                          style: TextStyle(color: Color(0xFF6C6F79), fontSize: 12),
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
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF121214),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'IFSC: ${account.ifscCode}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6C6F79),
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
                                                children: const [
                                                  Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFFD90429)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'PRIMARY',
                                                    style: TextStyle(
                                                      color: Color(0xFFD90429),
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
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF121214),
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
                                              const Text(
                                                'ACCOUNT HOLDER',
                                                style: TextStyle(
                                                  color: Color(0xFF9AA5B4),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                account.accountHolderName,
                                                style: const TextStyle(
                                                  color: Color(0xFF4B5563),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E3A8A)),
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
