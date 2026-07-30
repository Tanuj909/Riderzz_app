import 'package:flutter/material.dart';
import 'package:riderzz_app/features/support/data/models/support_ticket_model.dart';
import 'package:riderzz_app/features/support/data/repositories/support_repository.dart';

class SupportProvider extends ChangeNotifier {
  final SupportRepository _supportRepository;

  SupportProvider(this._supportRepository);

  List<SupportTicket> _tickets = [];
  SupportTicket? _selectedTicket;
  bool _isLoading = false;
  String? _errorMessage;

  List<SupportTicket> get tickets => _tickets;
  SupportTicket? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchTickets({String? status, bool force = false}) async {
    if (_tickets.isEmpty || force) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _supportRepository.getTickets(status: status);
      _tickets = list;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<SupportTicket?> createTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _supportRepository.raiseTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
      );
      _tickets = [ticket, ..._tickets];
      _isLoading = false;
      notifyListeners();
      return ticket;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchTicketDetails(int ticketId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _supportRepository.getTicketDetails(ticketId);
      _selectedTicket = ticket;
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = ticket;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required int ticketId,
    required String message,
    bool? internalNote,
  }) async {
    _errorMessage = null;

    try {
      final updatedTicket = await _supportRepository.addMessage(
        ticketId: ticketId,
        message: message,
        internalNote: internalNote,
      );
      _selectedTicket = updatedTicket;
      
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadTicketAttachment({
    required int ticketId,
    required String filePath,
  }) async {
    _errorMessage = null;

    try {
      final updatedTicket = await _supportRepository.uploadAttachment(
        ticketId: ticketId,
        filePath: filePath,
      );
      _selectedTicket = updatedTicket;

      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
