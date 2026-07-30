import 'package:dio/dio.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_response.dart';
import 'package:riderzz_app/features/support/data/models/support_ticket_model.dart';

class SupportRemoteDataSource {
  final ApiClient _apiClient;

  SupportRemoteDataSource(this._apiClient);

  Future<ApiResponse<SupportTicket>> raiseTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.supportTickets,
      data: {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
      },
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => SupportTicket.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  Future<ApiResponse<List<SupportTicket>>> getTickets({
    int? page,
    int? size,
    String? status,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (page != null) queryParameters['page'] = page;
    if (size != null) queryParameters['size'] = size;
    if (status != null) queryParameters['status'] = status;

    final response = await _apiClient.get(
      ApiConstants.supportTickets,
      queryParameters: queryParameters,
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
        final List contentList = dataMap['content'] as List? ?? [];
        return contentList
            .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  Future<ApiResponse<SupportTicket>> getTicketDetails(int ticketId) async {
    final response = await _apiClient.get(
      '${ApiConstants.supportTickets}/$ticketId',
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => SupportTicket.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  Future<ApiResponse<SupportTicket>> addMessage({
    required int ticketId,
    required String message,
    bool? internalNote,
  }) async {
    final Map<String, dynamic> body = {
      'message': message,
    };
    if (internalNote != null) {
      body['internalNote'] = internalNote;
    }
    final response = await _apiClient.post(
      '${ApiConstants.supportTickets}/$ticketId/messages',
      data: body,
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => SupportTicket.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  Future<ApiResponse<SupportTicket>> uploadAttachment({
    required int ticketId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.post(
      '${ApiConstants.supportTickets}/$ticketId/attachments',
      data: formData,
    );
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data),
      (data) => SupportTicket.fromJson(Map<String, dynamic>.from(data)),
    );
  }
}
