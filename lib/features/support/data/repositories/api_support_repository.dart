import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/support/data/models/support_ticket_model.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/repositories/support_repository.dart';

class ApiSupportRepository implements SupportRepositoryInterface {
  static const pageSize = 10;

  final ClientInterface client;

  ApiSupportRepository(this.client);

  @override
  Future<SupportTicketsPageEntity> getTickets(int page) async {
    final response = await client.get(
      '/support/tickets?page=$page&limit=$pageSize',
    );
    return supportTicketsPageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicketDetailEntity> getTicket(String id) async {
    final response = await client.get('/support/tickets/$id');
    return supportTicketDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicketDetailEntity> createTicket(
    NewSupportTicket ticket,
  ) async {
    final response = await client.post(
      '/support/tickets',
      data: newSupportTicketToJson(ticket),
    );
    return supportTicketDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicketDetailEntity> sendMessage(
    String id,
    String message, {
    UploadFile? file,
  }) async {
    final url = '/support/tickets/$id/messages';
    final response = file == null
        ? await client.post(url, data: {'message': message})
        : await client.upload(
            url,
            field: 'file',
            file: file,
            fields: {'message': message},
          );
    return supportTicketDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportQueuePageEntity> getQueue(
    SupportQueueFilter filter,
    int page,
  ) async {
    final response = await client.get(
      '/admin/support/tickets?${supportQueueQuery(filter)}'
      '&page=$page&limit=$pageSize',
    );
    return supportQueuePageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicketDetailEntity> assignTicket(String id) async {
    final response = await client.post('/admin/support/tickets/$id/assign');
    return supportTicketDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicketDetailEntity> closeTicket(
    String id,
    String resolution,
  ) async {
    final response = await client.post(
      '/admin/support/tickets/$id/close',
      data: {'resolution': resolution},
    );
    return supportTicketDetailFromJson(response as Map<String, dynamic>);
  }
}
