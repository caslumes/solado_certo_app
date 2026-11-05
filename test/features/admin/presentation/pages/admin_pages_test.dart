import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/enum/account_status.dart';
import 'package:solado_certo_app/features/admin/presentation/bloc/indicators_cubit.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_ads_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_audit_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_home_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_indicators_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_support_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_users_page.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

AdminUserEntity buildUser({
  String id = 'u1',
  String name = 'Ana Souza',
  AccountStatus status = AccountStatus.active,
  List<UserRole> roles = const [UserRole.buyer],
}) => AdminUserEntity(
  id: id,
  name: name,
  email: '$id@example.com',
  phone: '+5511999990000',
  status: status,
  roles: roles,
  createdAt: DateTime.utc(2026, 10, 1, 12),
);

AdminAdEntity buildAd({AdStatus status = AdStatus.published}) => AdminAdEntity(
  id: 'a1',
  title: 'Palmilha ortopédica',
  status: status,
  price: 129.9,
  stock: 3,
  sellerName: 'Loja Pé Bom',
  createdAt: DateTime.utc(2026, 10, 2, 12),
);

void main() {
  setUpAll(() async {
    registerFallbackValue(
      const UserModeration(action: UserModerationAction.block, reason: ''),
    );
    await initializeFormatting();
  });

  Future<void> openMenu(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('Moderar conta').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  final reasonField = find.byKey(const ValueKey('reason-field'));

  group('AdminUsersPage', () {
    late MockModerateUserUseCase moderate;
    late List<AdminUserFilter> filters;

    Future<void> pumpUsers(
      WidgetTester tester,
      List<AdminUserEntity> users, {
      DateTime? until,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AdminUsersCubit(
              loader: (filter, page) async {
                filters.add(filter);
                return (items: users, page: 1, hasNext: false);
              },
              filter: const AdminUserFilter(),
            )..load(),
            child: AdminUsersPage(
              moderateUseCase: moderate,
              pickSuspensionEnd: (_) async => until,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      moderate = MockModerateUserUseCase();
      filters = [];
    });

    testWidgets('offers no moderation for administrators', (tester) async {
      await pumpUsers(tester, [
        buildUser(roles: const [UserRole.admin], name: 'Admin'),
      ]);

      expect(find.text('Administrador'), findsOneWidget);
      expect(find.byTooltip('Moderar conta'), findsNothing);
    });

    testWidgets('requires a reason before blocking', (tester) async {
      when(
        () => moderate.execute('u1', any()),
      ).thenAnswer((_) async => buildUser(status: AccountStatus.blocked));
      await pumpUsers(tester, [buildUser()]);

      await openMenu(tester, 'Bloquear');
      expect(find.text('Bloquear Ana Souza?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Bloquear'));
      await tester.pump();
      expect(find.text('Campo obrigatório'), findsOneWidget);

      await tester.enterText(reasonField, 'abc');
      await tester.tap(find.widgetWithText(TextButton, 'Bloquear'));
      await tester.pump();
      expect(find.text('Escreva pelo menos 5 caracteres'), findsOneWidget);
      verifyNever(() => moderate.execute(any(), any()));

      await tester.enterText(reasonField, 'Fraude no pagamento');
      await tester.tap(find.widgetWithText(TextButton, 'Bloquear'));
      await tester.pumpAndSettle();

      final moderation =
          verify(() => moderate.execute('u1', captureAny())).captured.single
              as UserModeration;
      expect(moderation.action, UserModerationAction.block);
      expect(moderation.reason, 'Fraude no pagamento');
      expect(moderation.until, isNull);
      expect(find.text('Bloqueada'), findsOneWidget);
      expect(find.text('Conta bloqueada.'), findsOneWidget);
    });

    testWidgets('does nothing when the dialog is dismissed', (tester) async {
      await pumpUsers(tester, [buildUser()]);

      await openMenu(tester, 'Bloquear');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      verifyNever(() => moderate.execute(any(), any()));
    });

    testWidgets('suspends until the picked day', (tester) async {
      final until = DateTime(2026, 11, 20, 23, 59, 59);
      when(
        () => moderate.execute('u1', any()),
      ).thenAnswer((_) async => buildUser(status: AccountStatus.suspended));
      await pumpUsers(tester, [buildUser()], until: until);

      await openMenu(tester, 'Suspender');
      expect(
        find.textContaining('Suspensão até 20/11/2026 às 23:59'),
        findsOneWidget,
      );
      await tester.enterText(reasonField, 'Ofensas no chat');
      await tester.tap(find.widgetWithText(TextButton, 'Suspender'));
      await tester.pumpAndSettle();

      final moderation =
          verify(() => moderate.execute('u1', captureAny())).captured.single
              as UserModeration;
      expect(moderation.action, UserModerationAction.suspend);
      expect(moderation.until, until);
    });

    testWidgets('skips the dialog when no day is picked', (tester) async {
      await pumpUsers(tester, [buildUser()]);

      await openMenu(tester, 'Suspender');

      expect(reasonField, findsNothing);
    });

    testWidgets('offers only reactivation to a blocked account', (
      tester,
    ) async {
      await pumpUsers(tester, [buildUser(status: AccountStatus.blocked)]);

      await tester.tap(find.byTooltip('Moderar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Reativar'), findsOneWidget);
      expect(find.text('Bloquear'), findsNothing);
      expect(find.text('Suspender'), findsNothing);
    });

    testWidgets('shows a refused moderation', (tester) async {
      when(
        () => moderate.execute('u1', any()),
      ).thenThrow(AccountStatusChangedFailure());
      await pumpUsers(tester, [buildUser()]);

      await openMenu(tester, 'Bloquear');
      await tester.enterText(reasonField, 'Fraude no pagamento');
      await tester.tap(find.widgetWithText(TextButton, 'Bloquear'));
      await tester.pumpAndSettle();

      expect(find.text(AccountStatusChangedFailure().message), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
    });

    testWidgets('filters by status and search', (tester) async {
      await pumpUsers(tester, [buildUser()]);

      await tester.tap(find.text('Bloqueadas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ana');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(filters.map((f) => (f.search, f.status)), [
        ('', null),
        ('', AccountStatus.blocked),
        ('ana', AccountStatus.blocked),
      ]);
    });
  });

  group('AdminAdsPage', () {
    late MockTakeDownAdUseCase takeDown;

    Future<void> pumpAds(WidgetTester tester, AdminAdEntity ad) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AdminAdsCubit(
              loader: (_, _) async => (items: [ad], page: 1, hasNext: false),
              filter: const AdminAdFilter(),
            )..load(),
            child: AdminAdsPage(takeDownAdUseCase: takeDown),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() => takeDown = MockTakeDownAdUseCase());

    testWidgets('removes an ad with a reason', (tester) async {
      when(
        () => takeDown.execute('a1', 'Produto proibido'),
      ).thenAnswer((_) async => buildAd(status: AdStatus.removed));
      await pumpAds(tester, buildAd());

      await tester.tap(find.byTooltip('Remover anúncio'));
      await tester.pumpAndSettle();
      await tester.enterText(reasonField, 'Produto proibido');
      await tester.tap(find.widgetWithText(TextButton, 'Remover'));
      await tester.pumpAndSettle();

      verify(() => takeDown.execute('a1', 'Produto proibido')).called(1);
      expect(find.text('Anúncio removido.'), findsOneWidget);
      expect(find.byTooltip('Remover anúncio'), findsNothing);
    });

    testWidgets('offers no removal for a removed ad', (tester) async {
      await pumpAds(tester, buildAd(status: AdStatus.removed));

      expect(find.text('Removido'), findsWidgets);
      expect(find.byTooltip('Remover anúncio'), findsNothing);
    });
  });

  testWidgets('AdminSupportPage opens a ticket as admin and reloads', (
    tester,
  ) async {
    var loads = 0;
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SupportQueueCubit(
            loader: (_, _) async {
              loads++;
              return (
                items: [
                  SupportQueueItemEntity(
                    ticket: buildSupportTicket(),
                    openedBy: 'Ana',
                  ),
                ],
                page: 1,
                hasNext: false,
              );
            },
            filter: SupportQueueFilter.active,
          )..load(),
          child: AdminSupportPage(openTicket: (_, id) async => opened.add(id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aberto por Ana'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AdminTile),
        matching: find.text('Sem responsável'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Assunto t1'));
    await tester.pumpAndSettle();

    expect(opened, ['t1']);
    expect(loads, 2);
  });

  testWidgets('AdminAuditPage shows the action and its reason', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuditLogsCubit(
            loader: (_, _) async => (
              items: [
                AuditLogEntity(
                  id: 'l1',
                  userName: 'Admin',
                  entity: 'user',
                  entityId: 'u1',
                  action: 'admin.user_blocked',
                  context: const {
                    'reason': 'Fraude',
                    'previous_status': 'active',
                    'extra': null,
                  },
                  createdAt: DateTime.utc(2026, 11, 1, 12),
                ),
              ],
              page: 1,
              hasNext: false,
            ),
            filter: const AuditLogFilter(),
          )..load(),
          child: const AdminAuditPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conta bloqueada'), findsOneWidget);
    expect(find.text('Por: Admin'), findsOneWidget);
    expect(find.text('Motivo: Fraude'), findsOneWidget);
    expect(find.text('Situação anterior: active'), findsOneWidget);
    expect(find.textContaining('extra'), findsNothing);
  });

  testWidgets('AdminIndicatorsPage shows the numbers of the period', (
    tester,
  ) async {
    final getIndicators = MockGetIndicatorsUseCase();
    when(() => getIndicators.execute(any(), any())).thenAnswer(
      (_) async => IndicatorsEntity(
        from: DateTime(2026, 10, 6),
        to: DateTime(2026, 11, 4),
        newUsers: 4,
        blockedUsers: 1,
        suspendedUsers: 0,
        newAds: 2,
        publishedAds: 9,
        orders: 5,
        ordersByStatus: const {OrderStatus.paid: 3, OrderStatus.delivered: 2},
        paidOrders: 5,
        paidAmount: 640.5,
        paymentsByStatus: const {
          PaymentStatus.captured: AmountEntity(count: 5, amount: 640.5),
        },
        refundsGivenUp: 1,
        ticketsOpened: 3,
        ticketsResolved: 2,
        openTickets: 1,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              IndicatorsCubit(getIndicatorsUseCase: getIndicators)..load(),
          child: const AdminIndicatorsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('De 06/10/2026 a 04/11/2026'), findsOneWidget);
    expect(find.text(formatCurrency(640.5)), findsOneWidget);
    expect(find.text('Entregue'), findsOneWidget);
    expect(find.text('5 · ${formatCurrency(640.5)}'), findsOneWidget);

    await tester.tap(find.text('7 dias'));
    await tester.pump();
    verify(() => getIndicators.execute(any(), any())).called(2);
  });

  testWidgets('AdminHomePage lists every admin section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminHomePage()));

    for (final title in [
      'Indicadores',
      'Suporte',
      'Usuários',
      'Anúncios',
      'Pedidos',
      'Pagamentos',
      'Auditoria',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('a refused admin list shows the failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AdminUsersCubit(
            loader: (_, _) async => throw ForbiddenFailure(),
            filter: const AdminUserFilter(),
          )..load(),
          child: AdminUsersPage(moderateUseCase: MockModerateUserUseCase()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(ForbiddenFailure().message), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
  });
}
