import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:solado_certo_app/features/notifications/presentation/components/notification_bell.dart';
import 'package:solado_certo_app/features/notifications/presentation/pages/notifications_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetNotificationsUseCase getNotifications;
  late MockMarkNotificationReadUseCase markRead;
  late MockMarkAllNotificationsReadUseCase markAllRead;
  late NotificationsBloc bloc;
  late List<NotificationEntity> opened;

  void answer(List<NotificationEntity> items, {int unreadCount = 0}) {
    when(() => getNotifications.execute(any())).thenAnswer(
      (_) async => NotificationsPageEntity(
        items: items,
        currentPage: 1,
        hasNext: false,
        unreadCount: unreadCount,
      ),
    );
  }

  Route<void>? fakeRoute(NotificationEntity notification) {
    opened.add(notification);
    if (notification.type.forSeller) return null;
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Text('Pedido ${notification.orderId}')),
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    bloc = NotificationsBloc(
      getNotificationsUseCase: getNotifications,
      markNotificationReadUseCase: markRead,
      markAllNotificationsReadUseCase: markAllRead,
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<NotificationsBloc>.value(value: bloc),
          BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
        ],
        child: MaterialApp(home: child),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await pump(tester, NotificationsPage(routeFor: fakeRoute));
    bloc.add(LoadNotificationsEvent());
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getNotifications = MockGetNotificationsUseCase();
    markRead = MockMarkNotificationReadUseCase();
    markAllRead = MockMarkAllNotificationsReadUseCase();
    when(() => markRead.execute(any())).thenAnswer((_) async {});
    when(() => markAllRead.execute()).thenAnswer((_) async {});
    opened = [];
  });

  testWidgets('lists the notifications with title, body and time', (
    tester,
  ) async {
    answer([
      buildNotification(),
      buildNotification(id: 'n2', read: true),
    ], unreadCount: 1);
    await pumpPage(tester);

    expect(find.text('Título n1'), findsOneWidget);
    expect(find.text('Corpo n1'), findsOneWidget);
    expect(
      find.text(formatDateTime(DateTime.utc(2026, 10, 20, 12))),
      findsNWidgets(2),
    );
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('tapping a purchase marks it as read and opens the order', (
    tester,
  ) async {
    answer([buildNotification()], unreadCount: 1);
    await pumpPage(tester);

    await tester.tap(find.text('Título n1'));
    await tester.pumpAndSettle();

    verify(() => markRead.execute('n1')).called(1);
    expect(find.text('Pedido o1'), findsOneWidget);
    expect(bloc.state.unreadCount, 0);
  });

  testWidgets('tapping a sale only marks it as read for now', (tester) async {
    answer([
      buildNotification(type: NotificationType.orderPaid),
    ], unreadCount: 1);
    await pumpPage(tester);

    await tester.tap(find.text('Título n1'));
    await tester.pumpAndSettle();

    verify(() => markRead.execute('n1')).called(1);
    expect(opened.single.type, NotificationType.orderPaid);
    expect(find.byType(NotificationsPage), findsOneWidget);
  });

  testWidgets('marks all as read', (tester) async {
    answer([buildNotification(), buildNotification(id: 'n2')], unreadCount: 2);
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Marcar todas como lidas'));
    await tester.pumpAndSettle();

    verify(() => markAllRead.execute()).called(1);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byTooltip('Marcar todas como lidas'), findsNothing);
  });

  testWidgets('says when there are none', (tester) async {
    answer([]);
    await pumpPage(tester);

    expect(find.text('Nenhuma notificação'), findsOneWidget);
    expect(find.byTooltip('Marcar todas como lidas'), findsNothing);
  });

  testWidgets('shows a load error and tries again', (tester) async {
    when(
      () => getNotifications.execute(any()),
    ).thenThrow(buildDioException(type: DioExceptionType.connectionError));
    await pumpPage(tester);

    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);

    answer([buildNotification()], unreadCount: 1);
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();

    expect(find.text('Título n1'), findsOneWidget);
  });

  testWidgets('the bell shows the unread and opens the list, refreshed', (
    tester,
  ) async {
    answer([buildNotification()], unreadCount: 3);
    await pump(tester, const Scaffold(body: NotificationBell()));
    bloc.add(LoadNotificationsEvent(quiet: true));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notificações (3 não lidas)'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    clearInteractions(getNotifications);

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    verify(() => getNotifications.execute(1)).called(1);
  });

  testWidgets('the bell has no number with nothing unread', (tester) async {
    answer([]);
    await pump(tester, const Scaffold(body: NotificationBell()));
    bloc.add(LoadNotificationsEvent(quiet: true));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notificações'), findsOneWidget);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  test('a purchase or a sale leads to its order, none to nothing', () {
    expect(
      NotificationsPage.defaultRouteFor(buildNotification()),
      isA<Route<void>>(),
    );
    expect(
      NotificationsPage.defaultRouteFor(
        buildNotification(type: NotificationType.orderPaid),
      ),
      isA<Route<void>>(),
    );
    expect(
      NotificationsPage.defaultRouteFor(buildNotification(orderId: null)),
      isNull,
    );
  });
}
