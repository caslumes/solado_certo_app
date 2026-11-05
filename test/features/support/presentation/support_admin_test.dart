import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/support/data/repositories/api_support_repository.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_detail_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_detail_page.dart';

import '../../../support/builders.dart';
import '../../../support/mocks.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> detailJson() => {
  'id': 't1',
  'category': 'order',
  'status': 'in_progress',
  'subject': 'Palmilha errada',
  'order_id': 'o1',
  'order_number': 'SC-1',
  'opened_by_me': false,
  'assigned_to_me': true,
  'opened_at': '2026-11-01T12:00:00Z',
  'updated_at': '2026-11-02T12:00:00Z',
  'closed_at': null,
  'description': 'A palmilha chegou com o tamanho errado.',
  'resolution': null,
  'can_reply': true,
  'messages': [],
};

void main() {
  setUpAll(initializeFormatting);

  group('ApiSupportRepository admin queue', () {
    late MockClient client;
    late ApiSupportRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiSupportRepository(client);
    });

    test('lists the queue with the filter', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => {
          'items': [
            {
              ...detailJson(),
              'opened_by': {'id': 'u1', 'name': 'Ana'},
              'assigned_to': null,
            },
          ],
          'current_page': 1,
          'has_next': false,
        },
      );

      final page = await repository.getQueue(SupportQueueFilter.unassigned, 1);
      await repository.getQueue(SupportQueueFilter.mine, 2);
      await repository.getQueue(SupportQueueFilter.resolved, 1);

      verifyInOrder([
        () => client.get(
          '/admin/support/tickets?status=active&assigned=none&page=1&limit=10',
        ),
        () => client.get(
          '/admin/support/tickets?status=active&assigned=me&page=2&limit=10',
        ),
        () => client.get(
          '/admin/support/tickets?status=resolved&page=1&limit=10',
        ),
      ]);
      expect(page.items.single.openedBy, 'Ana');
      expect(page.items.single.assignedTo, isNull);
      expect(page.items.single.ticket.assignedToMe, isTrue);
    });

    test('assigns and closes a ticket', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => detailJson());

      await repository.assignTicket('t1');
      await repository.closeTicket('t1', 'Troca aprovada pelo vendedor.');

      verifyInOrder([
        () => client.post('/admin/support/tickets/t1/assign'),
        () => client.post(
          '/admin/support/tickets/t1/close',
          data: {'resolution': 'Troca aprovada pelo vendedor.'},
        ),
      ]);
    });
  });

  group('SupportTicketDetailCubit as admin', () {
    late MockGetSupportTicketUseCase getTicket;
    late MockSendSupportMessageUseCase sendMessage;
    late MockAssignSupportTicketUseCase assignTicket;
    late MockCloseSupportTicketUseCase closeTicket;

    final open = buildSupportTicketDetail();
    final assigned = buildSupportTicketDetail(
      status: SupportTicketStatus.inProgress,
      assignedToMe: true,
    );
    final resolved = buildSupportTicketDetail(
      status: SupportTicketStatus.resolved,
      resolution: 'Troca aprovada.',
      canReply: false,
    );

    SupportTicketDetailCubit buildCubit() => SupportTicketDetailCubit(
      getTicketUseCase: getTicket,
      sendMessageUseCase: sendMessage,
      assignTicketUseCase: assignTicket,
      closeTicketUseCase: closeTicket,
      ticketId: 't1',
    );

    setUp(() {
      getTicket = MockGetSupportTicketUseCase();
      sendMessage = MockSendSupportMessageUseCase();
      assignTicket = MockAssignSupportTicketUseCase();
      closeTicket = MockCloseSupportTicketUseCase();
      when(() => getTicket.execute('t1')).thenAnswer((_) async => open);
    });

    blocTest<SupportTicketDetailCubit, SupportTicketDetailState>(
      'assigns the ticket',
      setUp: () => when(
        () => assignTicket.execute('t1'),
      ).thenAnswer((_) async => assigned),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.assign(), isTrue);
      },
      skip: 2,
      expect: () => [
        isA<SupportTicketDetailLoaded>().having(
          (s) => s.sending,
          'sending',
          true,
        ),
        isA<SupportTicketDetailLoaded>().having(
          (s) => s.detail.ticket.assignedToMe,
          'assignedToMe',
          true,
        ),
      ],
    );

    blocTest<SupportTicketDetailCubit, SupportTicketDetailState>(
      'resolves the ticket with the decision',
      setUp: () => when(
        () => closeTicket.execute('t1', 'Troca aprovada.'),
      ).thenAnswer((_) async => resolved),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.resolve('Troca aprovada.'), isTrue);
      },
      verify: (cubit) {
        final state = cubit.state as SupportTicketDetailLoaded;
        expect(state.detail.resolution, 'Troca aprovada.');
        expect(state.detail.canReply, isFalse);
      },
    );

    blocTest<SupportTicketDetailCubit, SupportTicketDetailState>(
      'reloads the ticket when it was closed meanwhile',
      setUp: () => when(
        () => closeTicket.execute('t1', any()),
      ).thenThrow(TicketStatusChangedFailure()),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        when(() => getTicket.execute('t1')).thenAnswer((_) async => resolved);
        expect(await cubit.resolve('Troca aprovada.'), isFalse);
      },
      verify: (cubit) {
        final state = cubit.state as SupportTicketDetailLoaded;
        expect(state.failure, isA<TicketStatusChangedFailure>());
        expect(state.detail.ticket.status, SupportTicketStatus.resolved);
      },
    );
  });

  group('SupportTicketDetailPage as admin', () {
    late MockGetSupportTicketUseCase getTicket;
    late MockAssignSupportTicketUseCase assignTicket;
    late MockCloseSupportTicketUseCase closeTicket;

    Future<void> pumpDetail(
      WidgetTester tester,
      SupportTicketDetailEntity detail, {
      bool admin = true,
    }) async {
      when(() => getTicket.execute('t1')).thenAnswer((_) async => detail);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SupportTicketDetailCubit(
              getTicketUseCase: getTicket,
              sendMessageUseCase: MockSendSupportMessageUseCase(),
              assignTicketUseCase: assignTicket,
              closeTicketUseCase: closeTicket,
              ticketId: 't1',
            )..load(),
            child: SupportTicketDetailPage(admin: admin),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      getTicket = MockGetSupportTicketUseCase();
      assignTicket = MockAssignSupportTicketUseCase();
      closeTicket = MockCloseSupportTicketUseCase();
    });

    testWidgets('hides the admin actions from a party', (tester) async {
      await pumpDetail(tester, buildSupportTicketDetail(), admin: false);

      expect(find.byTooltip('Assumir chamado'), findsNothing);
      expect(find.byTooltip('Encerrar chamado'), findsNothing);
    });

    testWidgets('hides the actions once the ticket is resolved', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        buildSupportTicketDetail(
          status: SupportTicketStatus.resolved,
          resolution: 'Troca aprovada.',
          canReply: false,
        ),
      );

      expect(find.byTooltip('Assumir chamado'), findsNothing);
      expect(find.byTooltip('Encerrar chamado'), findsNothing);
    });

    testWidgets('assigns the ticket to the admin', (tester) async {
      when(() => assignTicket.execute('t1')).thenAnswer(
        (_) async => buildSupportTicketDetail(
          status: SupportTicketStatus.inProgress,
          assignedToMe: true,
        ),
      );
      await pumpDetail(tester, buildSupportTicketDetail());

      await tester.tap(find.byTooltip('Assumir chamado'));
      await tester.pumpAndSettle();

      verify(() => assignTicket.execute('t1')).called(1);
      expect(find.text('Em atendimento'), findsOneWidget);
      expect(find.byTooltip('Assumir chamado'), findsNothing);
      expect(
        find.text('Você é o responsável por este chamado.'),
        findsOneWidget,
      );
    });

    testWidgets('requires a decision of 10 characters to close', (
      tester,
    ) async {
      when(() => closeTicket.execute('t1', any())).thenAnswer(
        (_) async => buildSupportTicketDetail(
          status: SupportTicketStatus.resolved,
          resolution: 'Troca aprovada pelo vendedor.',
          canReply: false,
        ),
      );
      await pumpDetail(
        tester,
        buildSupportTicketDetail(
          status: SupportTicketStatus.inProgress,
          assignedToMe: true,
        ),
      );

      await tester.tap(find.byTooltip('Encerrar chamado'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reason-field')), 'Ok');
      await tester.tap(find.widgetWithText(TextButton, 'Encerrar'));
      await tester.pump();

      expect(find.text('Escreva pelo menos 10 caracteres'), findsOneWidget);
      verifyNever(() => closeTicket.execute(any(), any()));

      await tester.enterText(
        find.byKey(const ValueKey('reason-field')),
        'Troca aprovada pelo vendedor.',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Encerrar'));
      await tester.pumpAndSettle();

      verify(
        () => closeTicket.execute('t1', 'Troca aprovada pelo vendedor.'),
      ).called(1);
      expect(find.text('Decisão do suporte'), findsOneWidget);
      expect(find.text('Chamado resolvido.'), findsOneWidget);
      expect(find.byTooltip('Encerrar chamado'), findsNothing);
    });
  });
}
