import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_detail_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_form_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_tickets_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  const newTicket = NewSupportTicket(
    category: SupportTicketCategory.other,
    subject: 'Dúvida',
    description: 'Como faço para trocar meu e-mail?',
  );
  const file = UploadFile(bytes: [1], filename: 'foto.jpg');

  setUpAll(() => registerFallbackValue(newTicket));

  group('SupportTicketsCubit', () {
    late MockGetSupportTicketsUseCase getTickets;

    SupportTicketsCubit buildCubit() =>
        SupportTicketsCubit(getTicketsUseCase: getTickets);

    SupportTicketsPageEntity page(int number, {required bool hasNext}) =>
        SupportTicketsPageEntity(
          items: [buildSupportTicket(id: 't$number')],
          currentPage: number,
          hasNext: hasNext,
        );

    setUp(() => getTickets = MockGetSupportTicketsUseCase());

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'loads the first page',
      setUp: () => when(
        () => getTickets.execute(1),
      ).thenAnswer((_) async => page(1, hasNext: true)),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SupportTicketsState>().having(
          (s) => s.status,
          'status',
          SupportTicketsStatus.loading,
        ),
        isA<SupportTicketsState>()
            .having((s) => s.status, 'status', SupportTicketsStatus.loaded)
            .having((s) => s.tickets.length, 'tickets', 1)
            .having((s) => s.hasNext, 'hasNext', true),
      ],
    );

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'reports a load failure',
      setUp: () =>
          when(() => getTickets.execute(1)).thenThrow(NotFoundFailure()),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<SupportTicketsState>()
            .having((s) => s.status, 'status', SupportTicketsStatus.failure)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
      ],
    );

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'appends the next page',
      setUp: () {
        when(
          () => getTickets.execute(1),
        ).thenAnswer((_) async => page(1, hasNext: true));
        when(
          () => getTickets.execute(2),
        ).thenAnswer((_) async => page(2, hasNext: false));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 3,
      expect: () => [
        isA<SupportTicketsState>()
            .having((s) => s.tickets.map((t) => t.id), 'ids', ['t1', 't2'])
            .having((s) => s.hasNext, 'hasNext', false),
      ],
    );
  });

  group('SupportTicketDetailCubit', () {
    late MockGetSupportTicketUseCase getTicket;
    late MockSendSupportMessageUseCase sendMessage;

    final detail = buildSupportTicketDetail();
    final replied = buildSupportTicketDetail(messages: [buildSupportMessage()]);
    final resolved = buildSupportTicketDetail(
      status: SupportTicketStatus.resolved,
      resolution: 'Troca aprovada.',
      canReply: false,
    );

    SupportTicketDetailCubit buildCubit() => SupportTicketDetailCubit(
      getTicketUseCase: getTicket,
      sendMessageUseCase: sendMessage,
      ticketId: 't1',
    );

    setUp(() {
      getTicket = MockGetSupportTicketUseCase();
      sendMessage = MockSendSupportMessageUseCase();
    });

    blocTest<SupportTicketDetailCubit, SupportTicketDetailState>(
      'loads the ticket',
      setUp: () =>
          when(() => getTicket.execute('t1')).thenAnswer((_) async => detail),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<SupportTicketDetailLoaded>().having(
          (s) => s.detail,
          'detail',
          detail,
        ),
      ],
    );

    blocTest<SupportTicketDetailCubit, SupportTicketDetailState>(
      'keeps the ticket when a refresh fails',
      setUp: () =>
          when(() => getTicket.execute('t1')).thenThrow(NotFoundFailure()),
      build: buildCubit,
      seed: () => SupportTicketDetailLoaded(detail: detail),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SupportTicketDetailLoaded>()
            .having((s) => s.detail, 'detail', detail)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
      ],
    );

    test('sends a message with its attachment', () async {
      when(
        () => sendMessage.execute('t1', 'Olá', file: file),
      ).thenAnswer((_) async => replied);
      final cubit = buildCubit();
      cubit.emit(SupportTicketDetailLoaded(detail: detail));

      final sent = await cubit.send('Olá', file: file);

      expect(sent, isTrue);
      expect((cubit.state as SupportTicketDetailLoaded).detail, replied);
    });

    test('reports a refused message and keeps the ticket', () async {
      when(
        () => sendMessage.execute('t1', 'Olá'),
      ).thenThrow(AttachmentFileTypeFailure());
      final cubit = buildCubit();
      cubit.emit(SupportTicketDetailLoaded(detail: detail));

      final sent = await cubit.send('Olá');

      final state = cubit.state as SupportTicketDetailLoaded;
      expect(sent, isFalse);
      expect(state.detail, detail);
      expect(state.failure, isA<AttachmentFileTypeFailure>());
    });

    test('reloads the ticket when it was closed meanwhile', () async {
      when(
        () => sendMessage.execute('t1', 'Olá'),
      ).thenThrow(TicketStatusChangedFailure());
      when(() => getTicket.execute('t1')).thenAnswer((_) async => resolved);
      final cubit = buildCubit();
      cubit.emit(SupportTicketDetailLoaded(detail: detail));

      await cubit.send('Olá');

      final state = cubit.state as SupportTicketDetailLoaded;
      expect(state.detail.canReply, isFalse);
      expect(state.failure, isA<TicketStatusChangedFailure>());
    });
  });

  group('SupportTicketFormCubit', () {
    late MockCreateSupportTicketUseCase createTicket;

    final detail = buildSupportTicketDetail();

    SupportTicketFormCubit buildCubit() =>
        SupportTicketFormCubit(createTicketUseCase: createTicket);

    setUp(() => createTicket = MockCreateSupportTicketUseCase());

    blocTest<SupportTicketFormCubit, SupportTicketFormState>(
      'opens the ticket',
      setUp: () => when(
        () => createTicket.execute(any()),
      ).thenAnswer((_) async => detail),
      build: buildCubit,
      act: (cubit) => cubit.submit(newTicket),
      expect: () => [
        isA<SupportTicketFormState>().having((s) => s.sending, 'sending', true),
        isA<SupportTicketFormState>().having(
          (s) => s.created,
          'created',
          detail,
        ),
      ],
    );

    blocTest<SupportTicketFormCubit, SupportTicketFormState>(
      'reports a failure so the user can try again',
      setUp: () =>
          when(() => createTicket.execute(any())).thenThrow(NotFoundFailure()),
      build: buildCubit,
      act: (cubit) => cubit.submit(newTicket),
      skip: 1,
      expect: () => [
        isA<SupportTicketFormState>()
            .having((s) => s.sending, 'sending', false)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
      ],
    );
  });
}
