import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/support/providers/support_provider.dart';
import 'package:riderzz_app/features/support/data/models/support_ticket_model.dart';

class TicketDetailsScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTicketDetails();
    });
  }

  void _loadTicketDetails() async {
    await context.read<SupportProvider>().fetchTicketDetails(widget.ticketId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await context.read<SupportProvider>().sendMessage(
      ticketId: widget.ticketId,
      message: text,
    );

    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _pickAndUploadAttachment() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploadingAttachment = true;
      });

      final success = await context.read<SupportProvider>().uploadTicketAttachment(
        ticketId: widget.ticketId,
        filePath: image.path,
      );

      setState(() {
        _isUploadingAttachment = false;
      });

      if (success) {
        _scrollToBottom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment uploaded successfully! 📁'),
              backgroundColor: Color(0xFF15803D),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload attachment'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingAttachment = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'ROLE_ADMIN':
        return const Color(0xFFD90429); // Premium Red
      case 'DRIVER':
      case 'ROLE_DRIVER':
        return const Color(0xFF10B981); // Emerald Green
      case 'CUSTOMER':
      case 'ROLE_USER':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFE0F2FE);
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7);
      case 'RESOLVED':
        return const Color(0xFFDCFCE7);
      case 'CLOSED':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFF0369A1);
      case 'IN_PROGRESS':
        return const Color(0xFFB45309);
      case 'RESOLVED':
        return const Color(0xFF15803D);
      case 'CLOSED':
        return const Color(0xFF4B5563);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.userId ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Consumer<SupportProvider>(
          builder: (context, provider, _) {
            final ticket = provider.selectedTicket;
            return Column(
              children: [
                Text(
                  ticket?.ticketNumber ?? 'Ticket Details',
                  style: GoogleFonts.ibmPlexMono(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (ticket != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusTextColor(ticket.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.status.replaceAll('_', ' '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _getStatusTextColor(ticket.status),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadTicketDetails,
          ),
        ],
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          final ticket = provider.selectedTicket;

          if (provider.isLoading && ticket == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
              ),
            );
          }

          if (ticket == null) {
            return Center(
              child: Text(
                'Could not load ticket details',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
              ),
            );
          }

          // Merge initial ticket description as the first message or show it in header
          final messages = ticket.messages;

          return Column(
            children: [
              // Ticket Header Details Card
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(ticket.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Priority: ${ticket.priority}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: _getStatusTextColor(ticket.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ticket.subject,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ticket.description!,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                    // Show attachments if any
                    if (ticket.attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'ATTACHMENTS (${ticket.attachments.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ticket.attachments.length,
                          itemBuilder: (context, i) {
                            final att = ticket.attachments[i];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded, size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            att.fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: const Color(0xFF334155),
                                            ),
                                          ),
                                          Text(
                                            '${(att.fileSize / 1024).toStringAsFixed(1)} KB',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9.5,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chat Messages Area
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Send a message to start the conversation.',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13.5),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final sender = msg.sender;
                          final isMe = sender != null && sender.userId == currentUserId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe && sender != null) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _getRoleColor(sender.role).withOpacity(0.12),
                                    child: Text(
                                      sender.fullName.isNotEmpty ? sender.fullName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: _getRoleColor(sender.role),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color(0xFFFDF2F4) // Warm light red/pink for me
                                          : (msg.internalNote 
                                              ? const Color(0xFFFEF3C7) // Yellow for internal notes
                                              : Colors.white),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                                        bottomRight: Radius.circular(isMe ? 0 : 16),
                                      ),
                                      border: Border.all(
                                        color: isMe
                                            ? const Color(0xFFFCA5A5).withOpacity(0.5)
                                            : (msg.internalNote
                                                ? const Color(0xFFF59E0B).withOpacity(0.4)
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Sender Name and Role Tag
                                        if (sender != null) ...[
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isMe ? 'You' : sender.fullName,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11.5,
                                                  color: const Color(0xFF334155),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: _getRoleColor(sender.role).withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  sender.role,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 8.5,
                                                    color: _getRoleColor(sender.role),
                                                  ),
                                                ),
                                              ),
                                              if (msg.internalNote) ...[
                                                const SizedBox(width: 6),
                                                const Icon(Icons.lock_rounded, size: 10, color: Color(0xFFD97706)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'INTERNAL',
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 8.5,
                                                    color: const Color(0xFFD97706),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        // Message Body
                                        Text(
                                          msg.message,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13.5,
                                            color: const Color(0xFF1E293B),
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Message Timestamp
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Spacer(),
                                            Text(
                                              _formatDate(msg.createdAt),
                                              style: GoogleFonts.outfit(
                                                fontSize: 9.5,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Input & Attach Bar
              if (_isUploadingAttachment)
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                ),

              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Attach Button
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF64748B), size: 24),
                        onPressed: _pickAndUploadAttachment,
                      ),
                      // Text input field
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _messageController,
                            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13.5),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Button
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFFD90429), size: 24),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
