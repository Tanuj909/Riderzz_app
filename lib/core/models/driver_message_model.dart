class DriverMessageModel {
  final int messageId;
  final String adminName;
  final String message;
  final String sentAt;
  final bool read;

  DriverMessageModel({
    required this.messageId,
    required this.adminName,
    required this.message,
    required this.sentAt,
    required this.read,
  });

  factory DriverMessageModel.fromJson(Map<String, dynamic> json) {
    return DriverMessageModel(
      messageId: json['messageId'] as int? ?? 0,
      adminName: json['adminName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      sentAt: json['sentAt'] as String? ?? '',
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'adminName': adminName,
      'message': message,
      'sentAt': sentAt,
      'read': read,
    };
  }
}
