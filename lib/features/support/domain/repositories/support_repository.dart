import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';

abstract class SupportRepositoryInterface {
  Future<SupportTicketsPageEntity> getTickets(int page);
  Future<SupportTicketDetailEntity> getTicket(String id);
  Future<SupportTicketDetailEntity> createTicket(NewSupportTicket ticket);
  Future<SupportTicketDetailEntity> sendMessage(
    String id,
    String message, {
    UploadFile? file,
  });
  Future<SupportQueuePageEntity> getQueue(SupportQueueFilter filter, int page);
  Future<SupportTicketDetailEntity> assignTicket(String id);
  Future<SupportTicketDetailEntity> closeTicket(String id, String resolution);
}
