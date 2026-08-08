import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/features/admin/users/providers/admin_users_provider.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUsersProvider>().fetchUsers(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = context.read<AdminUsersProvider>();
        if (!provider.isLoading && !provider.isLastPage) {
          provider.fetchUsers();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header matching Driver Directory
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE1E1E6)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USER MANAGEMENT',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFD90429),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All Users',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF121214),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildFilters(context),
            Expanded(
              child: Consumer<AdminUsersProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.errorMessage!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA2A5AE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => provider.fetchUsers(refresh: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD90429),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE1E1E6)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.group_off_outlined, color: Color(0xFFA2A5AE), size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Users Found',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF121214),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your filters.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA2A5AE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(refresh: true),
                  color: const Color(0xFFD90429),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: provider.users.length + (provider.isLastPage ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == provider.users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
                            ),
                          ),
                        );
                      }

                      final user = provider.users[index];
                      return _buildUserCard(user);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final provider = context.watch<AdminUsersProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: 'Role',
              value: provider.currentRoleFilter ?? 'ALL',
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
                DropdownMenuItem(value: 'DRIVER', child: Text('Driver')),
              ],
              onChanged: (value) {
                context.read<AdminUsersProvider>().setRoleFilter(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              label: 'Status',
              value: provider.currentStatusFilter ?? 'ALL',
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
              ],
              onChanged: (value) {
                context.read<AdminUsersProvider>().setStatusFilter(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Theme(
        data: ThemeData.light(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA2A5AE), size: 20),
            isExpanded: true,
            style: GoogleFonts.outfit(
              color: const Color(0xFF121214),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item.value,
                child: Text(
                  (item.child as Text).data!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF121214),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color statusColor = const Color(0xFF6C6F79);
    if (user.status == 'ACTIVE') statusColor = const Color(0xFF1C9A5B);
    if (user.status == 'SUSPENDED') statusColor = const Color(0xFFD90429);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE1E1E6)),
                image: user.profileImage != null
                    ? DecorationImage(
                        image: NetworkImage(user.profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: user.profileImage == null
                  ? Text(
                      user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF121214),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'Unknown User',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF121214),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone ?? 'No phone number',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA2A5AE),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE1E1E6)),
                        ),
                        child: Text(
                          user.role,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6C6F79),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: statusColor, size: 6),
                            const SizedBox(width: 4),
                            Text(
                              user.status ?? 'UNKNOWN',
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
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
  }
}

