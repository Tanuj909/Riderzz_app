class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json)? fromJsonT) {
    return ApiResponse(
      success: json['success'] as bool? ?? true, // Assume true if not present for compatibility
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
    );
  }
}
