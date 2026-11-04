import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/support/data/models/support_ticket_model.dart';
import 'package:solado_certo_app/features/support/data/repositories/api_support_repository.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> ticketJson() => {
  'id': 't1',
  'category': 'adaptation',
  'status': 'awaiting_customer',
  'subject': 'Palmilha apertada',
  'order_id': 'o1',
  'order_number': 'SC-1',
  'opened_by_me': true,
  'assigned_to_me': false,
  'opened_at': '2026-11-01T12:00:00Z',
  'updated_at': '2026-11-02T12:00:00Z',
  'closed_at': null,
};

Map<String, dynamic> detailJson() => {
  ...ticketJson(),
  'description': 'A palmilha ficou apertada no calcanhar.',
  'resolution': null,
  'can_reply': true,
  'messages': [
    {
      'id': 'm1',
      'sender_role': 'support',
      'sender_name': 'Suporte Solado Certo',
      'mine': false,
      'message': 'Pode enviar uma foto?',
      'attachment_url': '/support/tickets/t1/messages/m1/attachment',
      'created_at': '2026-11-02T12:00:00Z',
    },
  ],
};

void main() {
  test('parses a ticket with its messages', () {
    final detail = supportTicketDetailFromJson(detailJson());

    expect(detail.ticket.category, SupportTicketCategory.adaptation);
    expect(detail.ticket.status, SupportTicketStatus.awaitingCustomer);
    expect(detail.ticket.orderNumber, 'SC-1');
    expect(detail.canReply, isTrue);
    expect(detail.messages.single.senderName, 'Suporte Solado Certo');
    expect(
      detail.messages.single.attachmentUrl,
      '/support/tickets/t1/messages/m1/attachment',
    );
  });

  test('takes a ticket without messages', () {
    final detail = supportTicketDetailFromJson({
      ...detailJson(),
      'messages': null,
    });

    expect(detail.messages, isEmpty);
  });

  group('ApiSupportRepository', () {
    late MockClient client;
    late ApiSupportRepository repository;

    const file = UploadFile(bytes: [1, 2], filename: 'foto.jpg');

    setUp(() {
      client = MockClient();
      repository = ApiSupportRepository(client);
    });

    test('lists a page of tickets', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => {
          'items': [ticketJson()],
          'current_page': 2,
          'has_next': false,
        },
      );

      final page = await repository.getTickets(2);

      verify(() => client.get('/support/tickets?page=2&limit=10')).called(1);
      expect(page.items.single.id, 't1');
      expect(page.currentPage, 2);
    });

    test('opens a ticket with the backend field names', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => detailJson());

      await repository.createTicket(
        const NewSupportTicket(
          category: SupportTicketCategory.payment,
          subject: 'Cobrança dupla',
          description: 'Fui cobrado duas vezes neste pedido.',
          orderId: 'o1',
        ),
      );

      verify(
        () => client.post(
          '/support/tickets',
          data: {
            'category': 'payment',
            'subject': 'Cobrança dupla',
            'description': 'Fui cobrado duas vezes neste pedido.',
            'order_id': 'o1',
          },
        ),
      ).called(1);
    });

    test('sends a text message as JSON', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => detailJson());

      await repository.sendMessage('t1', 'Olá');

      verify(
        () => client.post(
          '/support/tickets/t1/messages',
          data: {'message': 'Olá'},
        ),
      ).called(1);
    });

    test('sends a message with an attachment as multipart', () async {
      when(
        () => client.upload(
          any(),
          field: any(named: 'field'),
          file: file,
          fields: any(named: 'fields'),
        ),
      ).thenAnswer((_) async => detailJson());

      await repository.sendMessage('t1', 'Segue a foto', file: file);

      verify(
        () => client.upload(
          '/support/tickets/t1/messages',
          field: 'file',
          file: file,
          fields: {'message': 'Segue a foto'},
        ),
      ).called(1);
    });
  });
}
