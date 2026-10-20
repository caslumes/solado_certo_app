import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetNotificationsUseCase getNotifications;
  late MockMarkNotificationReadUseCase markRead;
  late MockMarkAllNotificationsReadUseCase markAllRead;

  final unread = buildNotification(id: 'n1');
  final other = buildNotification(id: 'n2');
  final alreadyRead = buildNotification(id: 'n3', read: true);

  NotificationsPageEntity page(
    List<NotificationEntity> items, {
    int at = 1,
    bool next = false,
    int unreadCount = 0,
  }) => NotificationsPageEntity(
    items: items,
    currentPage: at,
    hasNext: next,
    unreadCount: unreadCount,
  );

  NotificationsState loaded(
    List<NotificationEntity> items, {
    int at = 1,
    bool next = false,
    int unreadCount = 0,
  }) => NotificationsState(
    status: NotificationsStatus.loaded,
    notifications: items,
    page: at,
    hasNext: next,
    unreadCount: unreadCount,
  );

  TypeMatcher<NotificationsState> matches({
    NotificationsStatus status = NotificationsStatus.loaded,
    List<String>? ids,
    List<bool>? read,
    int? unreadCount,
    TypeMatcher<Failure>? failure,
  }) {
    var matcher = isA<NotificationsState>()
        .having((s) => s.status, 'status', status)
        .having((s) => s.failure, 'failure', failure ?? isNull);
    if (ids != null) {
      matcher = matcher.having(
        (s) => s.notifications.map((n) => n.id),
        'ids',
        ids,
      );
    }
    if (read != null) {
      matcher = matcher.having(
        (s) => s.notifications.map((n) => n.read),
        'read',
        read,
      );
    }
    if (unreadCount != null) {
      matcher = matcher.having((s) => s.unreadCount, 'unread', unreadCount);
    }
    return matcher;
  }

  final offline = buildDioException(type: DioExceptionType.connectionError);

  NotificationsBloc buildBloc() => NotificationsBloc(
    getNotificationsUseCase: getNotifications,
    markNotificationReadUseCase: markRead,
    markAllNotificationsReadUseCase: markAllRead,
  );

  setUp(() {
    getNotifications = MockGetNotificationsUseCase();
    markRead = MockMarkNotificationReadUseCase();
    markAllRead = MockMarkAllNotificationsReadUseCase();
  });

  group('LoadNotificationsEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'loads the first page with the unread count',
      setUp: () => when(
        () => getNotifications.execute(1),
      ).thenAnswer((_) async => page([unread, alreadyRead], unreadCount: 5)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadNotificationsEvent()),
      expect: () => [
        matches(status: NotificationsStatus.loading),
        matches(ids: ['n1', 'n3'], unreadCount: 5),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'a quiet check shows no spinner',
      setUp: () => when(
        () => getNotifications.execute(1),
      ).thenAnswer((_) async => page([unread], unreadCount: 1)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadNotificationsEvent(quiet: true)),
      expect: () => [
        matches(ids: ['n1'], unreadCount: 1),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'a quiet check that fails changes nothing',
      setUp: () => when(() => getNotifications.execute(1)).thenThrow(offline),
      build: buildBloc,
      seed: () => loaded([unread], unreadCount: 1),
      act: (bloc) => bloc.add(LoadNotificationsEvent(quiet: true)),
      expect: () => <NotificationsState>[],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'a first load that fails shows the error',
      setUp: () => when(() => getNotifications.execute(1)).thenThrow(offline),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadNotificationsEvent()),
      expect: () => [
        matches(status: NotificationsStatus.loading),
        matches(
          status: NotificationsStatus.failure,
          failure: isA<NetworkFailure>(),
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'a refresh that fails keeps the list',
      setUp: () => when(() => getNotifications.execute(1)).thenThrow(offline),
      build: buildBloc,
      seed: () => loaded([unread], unreadCount: 1),
      act: (bloc) => bloc.add(LoadNotificationsEvent()),
      expect: () => [
        matches(ids: ['n1'], unreadCount: 1, failure: isA<NetworkFailure>()),
      ],
    );
  });

  group('LoadMoreNotificationsEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'appends the next page, skipping one already shown',
      setUp: () => when(
        () => getNotifications.execute(2),
      ).thenAnswer((_) async => page([unread, other], at: 2, unreadCount: 2)),
      build: buildBloc,
      seed: () => loaded([unread], next: true, unreadCount: 2),
      act: (bloc) => bloc.add(LoadMoreNotificationsEvent()),
      skip: 1,
      expect: () => [
        matches(ids: ['n1', 'n2'], unreadCount: 2),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing on the last page',
      build: buildBloc,
      seed: () => loaded([unread]),
      act: (bloc) => bloc.add(LoadMoreNotificationsEvent()),
      expect: () => <NotificationsState>[],
      verify: (_) => verifyNever(() => getNotifications.execute(any())),
    );
  });

  group('MarkNotificationReadEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'shows it as read at once and tells the backend',
      setUp: () => when(() => markRead.execute('n1')).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => loaded([unread, other], unreadCount: 2),
      act: (bloc) => bloc.add(MarkNotificationReadEvent(id: 'n1')),
      expect: () => [
        matches(read: [true, false], unreadCount: 1),
      ],
      verify: (_) => verify(() => markRead.execute('n1')).called(1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'puts it back when the backend fails',
      setUp: () => when(() => markRead.execute('n1')).thenThrow(offline),
      build: buildBloc,
      seed: () => loaded([unread], unreadCount: 1),
      act: (bloc) => bloc.add(MarkNotificationReadEvent(id: 'n1')),
      expect: () => [
        matches(read: [true], unreadCount: 0),
        matches(read: [false], unreadCount: 1, failure: isA<NetworkFailure>()),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing for one already read',
      build: buildBloc,
      seed: () => loaded([alreadyRead]),
      act: (bloc) => bloc.add(MarkNotificationReadEvent(id: 'n3')),
      expect: () => <NotificationsState>[],
      verify: (_) => verifyNever(() => markRead.execute(any())),
    );
  });

  group('MarkAllNotificationsReadEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'marks every one as read',
      setUp: () => when(() => markAllRead.execute()).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => loaded([unread, other, alreadyRead], unreadCount: 30),
      act: (bloc) => bloc.add(MarkAllNotificationsReadEvent()),
      expect: () => [
        matches(read: [true, true, true], unreadCount: 0),
      ],
      verify: (_) => verify(() => markAllRead.execute()).called(1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'puts them back when the backend fails',
      setUp: () => when(() => markAllRead.execute()).thenThrow(offline),
      build: buildBloc,
      seed: () => loaded([unread, alreadyRead], unreadCount: 1),
      act: (bloc) => bloc.add(MarkAllNotificationsReadEvent()),
      expect: () => [
        matches(read: [true, true], unreadCount: 0),
        matches(
          read: [false, true],
          unreadCount: 1,
          failure: isA<NetworkFailure>(),
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing with none unread',
      build: buildBloc,
      seed: () => loaded([alreadyRead]),
      act: (bloc) => bloc.add(MarkAllNotificationsReadEvent()),
      expect: () => <NotificationsState>[],
      verify: (_) => verifyNever(() => markAllRead.execute()),
    );
  });

  blocTest<NotificationsBloc, NotificationsState>(
    'ClearNotificationsEvent forgets everything',
    build: buildBloc,
    seed: () => loaded([unread], unreadCount: 1),
    act: (bloc) => bloc.add(ClearNotificationsEvent()),
    expect: () => [
      matches(status: NotificationsStatus.initial, ids: [], unreadCount: 0),
    ],
  );
}
