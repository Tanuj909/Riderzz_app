import 'package:riderzz_app/features/support/data/datasource/support_remote_datasource.dart';
import 'package:riderzz_app/features/support/data/models/support_ticket_model.dart';

class SupportRepository {
  final SupportRemoteDataSource _remoteDataSource;

  SupportRepository(this._remoteDataSource);

  Future<SupportTicket> raiseTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    final response = await _remoteDataSource.raiseTicket(
      subject: subject,
      description: description,
      category: category,
      priority: priority,
    );
    if (!response.success) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<List<SupportTicket>> getTickets({
    int? page,
    int? size,
    String? status,
  }) async {
    final response = await _remoteDataSource.getTickets(
      page: page,
      size: size,
      status: status,
    );
    if (!response.success) {
      throw Exception(response.message);
    }
    return response.data ?? [];
  }

  Future<SupportTicket> getTicketDetails(int ticketId) async {
    final response = await _remoteDataSource.getTicketDetails(ticketId);
    if (!response.success) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<SupportTicket> addMessage({
    required int ticketId,
    required String message,
    bool? internalNote,
  }) async {
    final response = await _remoteDataSource.addMessage(
      ticketId: ticketId,
      message: message,
      internalNote: internalNote,
    );
    if (!response.success) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<SupportTicket> uploadAttachment({
    required int ticketId,
    required String filePath,
  }) async {
    final response = await _remoteDataSource.uploadAttachment(
      ticketId: ticketId,
      filePath: filePath,
    );
    if (!response.success) {
      throw Exception(response.message);
    }
    return response.data!;
  }
}
