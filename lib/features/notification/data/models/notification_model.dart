class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final String? actionUrl;
  final int? bookingId;
  final String? bookingStatus;
  final bool readFlag;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionUrl,
    this.bookingId,
    this.bookingStatus,
    this.readFlag = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'GENERAL',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionUrl: json['actionUrl'] as String?,
      bookingId: (json['bookingId'] as num?)?.toInt(),
      bookingStatus: json['bookingStatus'] as String?,
      readFlag: json['readFlag'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
