import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/models/driver_message_model.dart';

class DriverMessagesPage extends StatefulWidget {
  const DriverMessagesPage({super.key});

  @override
  State<DriverMessagesPage> createState() => _DriverMessagesPageState();
}

class _DriverMessagesPageState extends State<DriverMessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DriverHomeProvider>();
      await provider.fetchDriverMessages(force: true);
      await provider.markAllMessagesAsRead();
    });
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      final hourVal = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hourVal:$minute $period';
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: Consumer<DriverHomeProvider>(
          builder: (context, provider, child) {
            final messages = provider.messages;
            final isLoading = provider.isMessagesLoading;
            final error = provider.messagesError;

            return RefreshIndicator(
              onRefresh: () async {
                await provider.fetchDriverMessages(force: true);
                await provider.markAllMessagesAsRead();
              },
              color: const Color(0xFFD90429),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INBOX',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFD90429),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admin Messages',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF121214),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading && messages.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                            ),
                          )
                        : error != null && messages.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        error,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(color: const Color(0xFF4A5568), fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD90429)),
                                        onPressed: () => provider.fetchDriverMessages(force: true),
                                        child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : messages.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFEDF0),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.mail_outline_rounded, size: 44, color: Color(0xFFD90429)),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Your Inbox is Empty',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF121214),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Messages from support/admin will appear here.',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: const Color(0xFF6C6F79),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final DriverMessageModel msg = messages[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: msg.read ? const Color(0xFFE1E1E6) : const Color(0xFFD90429).withValues(alpha: 0.15),
                                            width: msg.read ? 1.0 : 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF121214).withValues(alpha: 0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.admin_panel_settings_rounded,
                                                      size: 16,
                                                      color: msg.read ? const Color(0xFF6C6F79) : const Color(0xFFD90429),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Admin: ${msg.adminName}',
                                                      style: GoogleFonts.outfit(
                                                        color: const Color(0xFF121214),
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (!msg.read)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFD90429),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              msg.message,
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF4A5568),
                                                fontSize: 13,
                                                height: 1.4,
                                                fontWeight: msg.read ? FontWeight.normal : FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                _formatDateTime(msg.sentAt),
                                                style: GoogleFonts.ibmPlexMono(
                                                  color: const Color(0xFF6C6F79),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
