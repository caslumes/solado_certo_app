import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_detail_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_form_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_tickets_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/pages/my_support_tickets_page.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_detail_page.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_form_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  const newTicket = NewSupportTicket(
    category: SupportTicketCategory.other,
    subject: '',
    description: '',
  );

  setUpAll(() async {
    registerFallbackValue(newTicket);
    await initializeFormatting();
  });

  group('SupportTicketFormPage', () {
    late MockCreateSupportTicketUseCase createTicket;
    late List<SupportTicketDetailEntity> opened;

    final subjectField = find.descendant(
      of: find.byKey(const ValueKey('ticket-subject')),
      matching: find.byType(TextFormField),
    );
    final descriptionField = find.descendant(
      of: find.byKey(const ValueKey('ticket-description')),
      matching: find.byType(TextFormField),
    );

    Future<void> pumpForm(
      WidgetTester tester, {
      String? orderId,
      String? orderNumber,
      SupportTicketCategory? category,
    }) => tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              SupportTicketFormCubit(createTicketUseCase: createTicket),
          child: SupportTicketFormPage(
            orderId: orderId,
            orderNumber: orderNumber,
            category: category,
            onCreated: (_, detail) => opened.add(detail),
          ),
        ),
      ),
    );

    Future<void> tapSubmit(WidgetTester tester) async {
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }

    setUp(() {
      createTicket = MockCreateSupportTicketUseCase();
      opened = [];
    });

    testWidgets('asks for more details before opening (UC-011)', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(subjectField, 'Oi');
      await tester.enterText(descriptionField, 'Curto demais');
      await tapSubmit(tester);

      expect(find.text('Escreva pelo menos 5 caracteres'), findsOneWidget);
      expect(find.text('Escreva pelo menos 20 caracteres'), findsOneWidget);
      verifyNever(() => createTicket.execute(any()));
    });

    testWidgets('without an order, offers only the general subjects', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.tap(
        find.byType(DropdownButtonFormField<SupportTicketCategory>),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adaptação ao produto'), findsWidgets);
      expect(find.text('Outro assunto'), findsWidgets);
      expect(find.text('Pagamento'), findsNothing);
    });

    testWidgets('opens the ticket linked to the order', (tester) async {
      final detail = buildSupportTicketDetail();
      when(() => createTicket.execute(any())).thenAnswer((_) async => detail);
      await pumpForm(tester, orderId: 'o1', orderNumber: 'SC-1');

      expect(find.text('Pedido SC-1'), findsOneWidget);
      await tester.enterText(subjectField, ' Pedido atrasado ');
      await tester.enterText(
        descriptionField,
        'O prazo de entrega já passou há três dias.',
      );
      await tapSubmit(tester);
      await tester.pump();

      final sent =
          verify(() => createTicket.execute(captureAny())).captured.single
              as NewSupportTicket;
      expect(sent.category, SupportTicketCategory.order);
      expect(sent.subject, 'Pedido atrasado');
      expect(sent.orderId, 'o1');
      expect(opened, [detail]);
    });

    testWidgets('starts on the category the caller chose', (tester) async {
      when(
        () => createTicket.execute(any()),
      ).thenAnswer((_) async => buildSupportTicketDetail());
      await pumpForm(
        tester,
        orderId: 'o1',
        orderNumber: 'SC-1',
        category: SupportTicketCategory.adaptation,
      );

      await tester.enterText(subjectField, 'Palmilha apertada');
      await tester.enterText(
        descriptionField,
        'Machuca o calcanhar depois de uma hora.',
      );
      await tapSubmit(tester);

      final sent =
          verify(() => createTicket.execute(captureAny())).captured.single
              as NewSupportTicket;
      expect(sent.category, SupportTicketCategory.adaptation);
    });

    testWidgets('shows a failure in a SnackBar', (tester) async {
      when(() => createTicket.execute(any())).thenThrow(NotFoundFailure());
      await pumpForm(tester, orderId: 'o1', orderNumber: 'SC-1');

      await tester.enterText(subjectField, 'Pedido atrasado');
      await tester.enterText(
        descriptionField,
        'O prazo de entrega já passou há três dias.',
      );
      await tapSubmit(tester);
      await tester.pump();

      expect(
        find.text('O conteúdo procurado não foi encontrado.'),
        findsOneWidget,
      );
      expect(opened, isEmpty);
    });
  });

  group('SupportTicketDetailPage', () {
    late MockGetSupportTicketUseCase getTicket;
    late MockSendSupportMessageUseCase sendMessage;
    late List<String> openedAttachments;

    const file = UploadFile(bytes: [1], filename: 'foto.jpg');
    final composer = find.byType(TextFormField);

    Future<void> pumpDetail(
      WidgetTester tester,
      SupportTicketDetailEntity detail, {
      UploadFile? picked,
    }) async {
      when(() => getTicket.execute('t1')).thenAnswer((_) async => detail);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SupportTicketDetailCubit(
              getTicketUseCase: getTicket,
              sendMessageUseCase: sendMessage,
              ticketId: 't1',
            )..load(),
            child: SupportTicketDetailPage(
              pickFile: (_) async => picked,
              openAttachment: (_, url) => openedAttachments.add(url),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      getTicket = MockGetSupportTicketUseCase();
      sendMessage = MockSendSupportMessageUseCase();
      openedAttachments = [];
    });

    testWidgets('shows the ticket and its messages', (tester) async {
      await pumpDetail(
        tester,
        buildSupportTicketDetail(
          messages: [
            buildSupportMessage(message: 'Pode enviar uma foto?'),
            buildSupportMessage(id: 'm2', mine: true, message: 'Claro'),
          ],
        ),
      );

      expect(find.text('Assunto t1'), findsOneWidget);
      expect(find.text('Aberto'), findsOneWidget);
      expect(find.text('Pedido · Pedido SC-1'), findsOneWidget);
      expect(
        find.text('A palmilha chegou com o tamanho errado.'),
        findsOneWidget,
      );
      expect(find.text('Suporte Solado Certo'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
    });

    testWidgets('opens an attachment', (tester) async {
      await pumpDetail(
        tester,
        buildSupportTicketDetail(
          messages: [buildSupportMessage(attachmentUrl: '/anexo')],
        ),
      );

      await tester.tap(find.text('Ver anexo'));

      expect(openedAttachments, ['/anexo']);
    });

    testWidgets('does not send an empty message', (tester) async {
      await pumpDetail(tester, buildSupportTicketDetail());

      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsOneWidget);
      verifyNever(
        () => sendMessage.execute(any(), any(), file: any(named: 'file')),
      );
    });

    testWidgets('sends a message with an attachment and clears the composer', (
      tester,
    ) async {
      when(
        () => sendMessage.execute('t1', 'Segue a foto', file: file),
      ).thenAnswer(
        (_) async => buildSupportTicketDetail(
          messages: [buildSupportMessage(mine: true, message: 'Segue a foto')],
        ),
      );
      await pumpDetail(tester, buildSupportTicketDetail(), picked: file);

      await tester.tap(find.byTooltip('Anexar arquivo'));
      await tester.pump();
      expect(find.text('foto.jpg'), findsOneWidget);

      await tester.enterText(composer, ' Segue a foto ');
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pump();
      await tester.pump();

      verify(
        () => sendMessage.execute('t1', 'Segue a foto', file: file),
      ).called(1);
      expect(find.text('foto.jpg'), findsNothing);
      expect(tester.widget<TextFormField>(composer).controller!.text, isEmpty);
    });

    testWidgets('keeps the text when the message is refused', (tester) async {
      when(
        () => sendMessage.execute('t1', 'Olá'),
      ).thenThrow(AttachmentFileTypeFailure());
      await pumpDetail(tester, buildSupportTicketDetail());

      await tester.enterText(composer, 'Olá');
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Envie o anexo em PDF, JPEG ou PNG.'), findsOneWidget);
      expect(tester.widget<TextFormField>(composer).controller!.text, 'Olá');
    });

    testWidgets('a resolved ticket shows the decision and takes no replies', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        buildSupportTicketDetail(
          status: SupportTicketStatus.resolved,
          resolution: 'Troca aprovada pelo vendedor.',
          canReply: false,
        ),
      );

      expect(find.text('Decisão do suporte'), findsOneWidget);
      expect(find.text('Troca aprovada pelo vendedor.'), findsOneWidget);
      expect(
        find.text('Este chamado foi encerrado e não recebe mais mensagens.'),
        findsOneWidget,
      );
      expect(composer, findsNothing);
    });

    testWidgets('retries after a load failure', (tester) async {
      when(() => getTicket.execute('t1')).thenThrow(NotFoundFailure());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SupportTicketDetailCubit(
              getTicketUseCase: getTicket,
              sendMessageUseCase: sendMessage,
              ticketId: 't1',
            )..load(),
            child: const SupportTicketDetailPage(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('O conteúdo procurado não foi encontrado.'),
        findsOneWidget,
      );
      when(
        () => getTicket.execute('t1'),
      ).thenAnswer((_) async => buildSupportTicketDetail());
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('Assunto t1'), findsOneWidget);
    });
  });

  group('MySupportTicketsPage', () {
    late MockGetSupportTicketsUseCase getTickets;
    late List<String> openedTickets;
    late int formsOpened;

    Future<void> pumpList(
      WidgetTester tester,
      List<SupportTicketEntity> tickets,
    ) async {
      when(() => getTickets.execute(1)).thenAnswer(
        (_) async => SupportTicketsPageEntity(
          items: tickets,
          currentPage: 1,
          hasNext: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) =>
                SupportTicketsCubit(getTicketsUseCase: getTickets)..load(),
            child: MySupportTicketsPage(
              openTicket: (_, id) async => openedTickets.add(id),
              openForm: (_) async => formsOpened++,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      getTickets = MockGetSupportTicketsUseCase();
      openedTickets = [];
      formsOpened = 0;
    });

    testWidgets('shows an empty message', (tester) async {
      await pumpList(tester, const []);

      expect(find.text('Nenhum chamado'), findsOneWidget);
    });

    testWidgets('opens a ticket and reloads the list on return', (
      tester,
    ) async {
      await pumpList(tester, [
        buildSupportTicket(status: SupportTicketStatus.awaitingCustomer),
      ]);

      expect(find.text('Aguardando resposta'), findsOneWidget);
      await tester.tap(find.text('Assunto t1'));
      await tester.pump();

      expect(openedTickets, ['t1']);
      verify(() => getTickets.execute(1)).called(2);
    });

    testWidgets('opens the form and reloads the list on return', (
      tester,
    ) async {
      await pumpList(tester, const []);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(formsOpened, 1);
      verify(() => getTickets.execute(1)).called(2);
    });
  });
}
