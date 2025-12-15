import '../services/api_service.dart';

class TicketRepository {
  final ApiService _apiService;

  TicketRepository(this._apiService);

  Future<List<Map<String, dynamic>>> getTickets() async {
    return _apiService.getTickets();
  }

  Future<void> replyTicket(
    String ticketId,
    String message,
    String authorId,
    String authorName,
  ) async {
    await _apiService.replyTicket(ticketId, message, authorId, authorName);
  }

  Future<List<Map<String, dynamic>>> getTicketMessages(String ticketId) async {
    return _apiService.getTicketMessages(ticketId);
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _apiService.updateTicketStatus(ticketId, status);
  }
}
