import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/support/providers/support_provider.dart';
import 'package:riderzz_app/features/support/data/models/support_ticket_model.dart';
import 'package:riderzz_app/features/support/screens/raise_ticket_screen.dart';
import 'package:riderzz_app/features/support/screens/ticket_details_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedStatus;

  // Status mapping to indices
  final List<String?> _statusFilters = [null, 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  final List<String> _tabLabels = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTickets();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedStatus = _statusFilters[_tabController.index];
    });
  }

  void _fetchTickets() {
    context.read<SupportProvider>().fetchTickets(
      status: null,
      force: true,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFE0F2FE); // Soft Blue
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7); // Soft Amber
      case 'RESOLVED':
        return const Color(0xFFDCFCE7); // Soft Green
      case 'CLOSED':
        return const Color(0xFFF3F4F6); // Soft Gray
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFF0369A1); // Deep Blue
      case 'IN_PROGRESS':
        return const Color(0xFFB45309); // Deep Amber
      case 'RESOLVED':
        return const Color(0xFF15803D); // Deep Green
      case 'CLOSED':
        return const Color(0xFF4B5563); // Deep Gray
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return const Color(0xFF6B7280); // Gray
      case 'MEDIUM':
        return const Color(0xFF3B82F6); // Blue
      case 'HIGH':
        return const Color(0xFFF59E0B); // Amber/Orange
      case 'CRITICAL':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = months[dateTime.month - 1];
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day $month, $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role ?? 'CUSTOMER';
    final isAdmin = userRole.toUpperCase() == 'ADMIN' || userRole.toUpperCase() == 'ROLE_ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tickets by number, subject...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Tabs for Ticket status
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFFD90429),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFFD90429),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: _tabLabels.map((lbl) => Tab(text: lbl)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tickets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
              ),
            );
          }

          var filteredTickets = provider.tickets;

          // Apply local status filter
          if (_selectedStatus != null) {
            filteredTickets = filteredTickets
                .where((t) => t.status.toUpperCase() == _selectedStatus!.toUpperCase())
                .toList();
          }

          // Apply local search query
          if (_searchQuery.isNotEmpty) {
            filteredTickets = filteredTickets.where((t) {
              final numMatch = t.ticketNumber.toLowerCase().contains(_searchQuery);
              final subMatch = t.subject.toLowerCase().contains(_searchQuery);
              final catMatch = t.category.toLowerCase().contains(_searchQuery);
              return numMatch || subMatch || catMatch;
            }).toList();
          }

          if (filteredTickets.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _fetchTickets(),
              color: const Color(0xFFD90429),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                  const Icon(Icons.support_agent_rounded, size: 72, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No Tickets Found',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Try adjusting your search query'
                          : 'You haven\'t raised any support queries yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchTickets(),
            color: const Color(0xFFD90429),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filteredTickets.length,
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailsScreen(ticketId: ticket.id),
                            ),
                          ).then((_) {
                            _fetchTickets(); // reload on pop back
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Ticket Number & Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ticket.ticketNumber,
                                    style: GoogleFonts.ibmPlexMono(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF475569),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusBgColor(ticket.status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      ticket.status.replaceAll('_', ' '),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                        color: _getStatusTextColor(ticket.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Subject
                              Text(
                                ticket.subject,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),
                              const SizedBox(height: 12),
                              // Bottom metadata row
                              Row(
                                children: [
                                  // Category label
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ticket.category,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Priority indicator dot
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(ticket.priority),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ticket.priority,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: _getPriorityColor(ticket.priority),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Date
                                  Icon(Icons.access_time_rounded, size: 12.5, color: const Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(ticket.createdAt),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'By: ${ticket.createdByName ?? ticket.createdBy?.fullName ?? 'User'}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RaiseTicketScreen()),
                ).then((_) {
                  _fetchTickets(); // Refresh tickets list when returned
                });
              },
              backgroundColor: const Color(0xFFD90429),
              elevation: 4,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
              label: Text(
                'Raise Ticket',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            )
          : null,
    );
  }
}
