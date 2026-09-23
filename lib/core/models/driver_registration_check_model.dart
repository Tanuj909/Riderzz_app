class DriverRegistrationCheckModel {
  final bool formSubmitted;
  final bool termsAccepted;
  final String? status;
  final String? message;

  DriverRegistrationCheckModel({
    required this.formSubmitted,
    required this.termsAccepted,
    this.status,
    this.message,
  });

  factory DriverRegistrationCheckModel.fromJson(Map<String, dynamic> json) {
    // Check if fields are wrapped in 'data'
    final Map<String, dynamic> data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return DriverRegistrationCheckModel(
      formSubmitted: data['formSubmitted'] == true,
      termsAccepted: data['termsAccepted'] == true,
      status: data['status']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formSubmitted': formSubmitted,
      'termsAccepted': termsAccepted,
      'status': status,
      if (message != null) 'message': message,
    };
  }
}
