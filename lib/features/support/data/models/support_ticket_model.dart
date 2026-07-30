class TicketCreator {
  final int userId;
  final String fullName;
  final String role;

  TicketCreator({
    required this.userId,
    required this.fullName,
    required this.role,
  });

  factory TicketCreator.fromJson(Map<String, dynamic> json) {
    return TicketCreator(
      userId: json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'role': role,
    };
  }
}

class TicketMessage {
  final int id;
  final TicketCreator? sender;
  final String message;
  final bool internalNote;
  final String createdAt;

  TicketMessage({
    required this.id,
    this.sender,
    required this.message,
    required this.internalNote,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int? ?? 0,
      sender: json['sender'] != null
          ? TicketCreator.fromJson(Map<String, dynamic>.from(json['sender']))
          : null,
      message: json['message'] as String? ?? '',
      internalNote: json['internalNote'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender?.toJson(),
      'message': message,
      'internalNote': internalNote,
      'createdAt': createdAt,
    };
  }
}

class TicketAttachment {
  final int id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String contentType;
  final String createdAt;

  TicketAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.contentType,
    required this.createdAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] as int? ?? 0,
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      contentType: json['contentType'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'contentType': contentType,
      'createdAt': createdAt,
    };
  }
}

class SupportTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final TicketCreator? createdBy;
  final String? createdByName;
  final String createdAt;
  final String updatedAt;
  final List<TicketMessage> messages;
  final List<TicketAttachment> attachments;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.attachments = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    var msgs = <TicketMessage>[];
    if (json['messages'] != null) {
      msgs = (json['messages'] as List)
          .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    var atts = <TicketAttachment>[];
    if (json['attachments'] != null) {
      atts = (json['attachments'] as List)
          .map((e) => TicketAttachment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return SupportTicket(
      id: json['id'] as int? ?? 0,
      ticketNumber: json['ticketNumber'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'OTHER',
      priority: json['priority'] as String? ?? 'LOW',
      status: json['status'] as String? ?? 'OPEN',
      createdBy: json['createdBy'] != null
          ? TicketCreator.fromJson(Map<String, dynamic>.from(json['createdBy']))
          : null,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      messages: msgs,
      attachments: atts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdBy': createdBy?.toJson(),
      'createdByName': createdByName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messages': messages.map((e) => e.toJson()).toList(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }
}
