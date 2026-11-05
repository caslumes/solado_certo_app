import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/repositories/support_repository.dart';

class GetSupportTicketsUseCase {
  final SupportRepositoryInterface repository;

  GetSupportTicketsUseCase(this.repository);

  Future<SupportTicketsPageEntity> execute(int page) =>
      repository.getTickets(page);
}

class GetSupportTicketUseCase {
  final SupportRepositoryInterface repository;

  GetSupportTicketUseCase(this.repository);

  Future<SupportTicketDetailEntity> execute(String id) =>
      repository.getTicket(id);
}

class CreateSupportTicketUseCase {
  final SupportRepositoryInterface repository;

  CreateSupportTicketUseCase(this.repository);

  Future<SupportTicketDetailEntity> execute(NewSupportTicket ticket) =>
      repository.createTicket(ticket);
}

class SendSupportMessageUseCase {
  final SupportRepositoryInterface repository;

  SendSupportMessageUseCase(this.repository);

  Future<SupportTicketDetailEntity> execute(
    String id,
    String message, {
    UploadFile? file,
  }) => repository.sendMessage(id, message, file: file);
}

class GetSupportQueueUseCase {
  final SupportRepositoryInterface repository;

  GetSupportQueueUseCase(this.repository);

  Future<SupportQueuePageEntity> execute(SupportQueueFilter filter, int page) =>
      repository.getQueue(filter, page);
}

class AssignSupportTicketUseCase {
  final SupportRepositoryInterface repository;

  AssignSupportTicketUseCase(this.repository);

  Future<SupportTicketDetailEntity> execute(String id) =>
      repository.assignTicket(id);
}

class CloseSupportTicketUseCase {
  final SupportRepositoryInterface repository;

  CloseSupportTicketUseCase(this.repository);

  Future<SupportTicketDetailEntity> execute(String id, String resolution) =>
      repository.closeTicket(id, resolution);
}
