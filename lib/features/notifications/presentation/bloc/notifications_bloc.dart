import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/usecases/notification_use_cases.dart';

/// The bell's unread count and the notifications list, newest first.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;

  /// Bumped by every first-page load, so a next page that arrives after a
  /// refresh is dropped.
  int _generation = 0;

  NotificationsBloc({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _markNotificationReadUseCase = markNotificationReadUseCase,
       _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
       super(const NotificationsState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<LoadMoreNotificationsEvent>(_onLoadMore);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
    on<ClearNotificationsEvent>((_, emit) {
      _generation++;
      emit(const NotificationsState());
    });
  }

  /// Loads the first page. A refresh keeps the list on screen; a quiet one
  /// (the periodic check) also keeps quiet about failures.
  Future<void> _onLoad(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final generation = ++_generation;
    final refreshing = state.status == NotificationsStatus.loaded;
    if (!refreshing && !event.quiet) {
      emit(const NotificationsState(status: NotificationsStatus.loading));
    }
    try {
      final page = await _getNotificationsUseCase.execute(1);
      if (generation != _generation) return;
      emit(
        NotificationsState(
          status: NotificationsStatus.loaded,
          notifications: page.items,
          page: page.currentPage,
          hasNext: page.hasNext,
          unreadCount: page.unreadCount,
        ),
      );
    } catch (e) {
      if (generation != _generation || event.quiet) return;
      final failure = Failure.from(e);
      emit(
        refreshing
            ? state.copyWith(failure: failure)
            : NotificationsState(
                status: NotificationsStatus.failure,
                failure: failure,
              ),
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status != NotificationsStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getNotificationsUseCase.execute(state.page + 1);
      if (generation != _generation) return;
      final known = {for (final n in state.notifications) n.id};
      emit(
        state.copyWith(
          // A notification created meanwhile shifts the pages by one.
          notifications: [
            ...state.notifications,
            ...page.items.where((n) => !known.contains(n.id)),
          ],
          page: page.currentPage,
          hasNext: page.hasNext,
          unreadCount: page.unreadCount,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(loadingMore: false, failure: Failure.from(e)));
    }
  }

  /// Shown as read at once; put back if the request fails.
  Future<void> _onMarkRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final notification = state.notifications
        .where((n) => n.id == event.id)
        .firstOrNull;
    if (notification == null || notification.read) return;

    emit(
      state.copyWith(
        notifications: _withRead(state.notifications, {event.id}, true),
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ),
    );
    try {
      await _markNotificationReadUseCase.execute(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          notifications: _withRead(state.notifications, {event.id}, false),
          unreadCount: state.unreadCount + 1,
          failure: Failure.from(e),
        ),
      );
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.unreadCount == 0) return;

    final previous = state;
    emit(
      state.copyWith(
        notifications: [
          for (final n in state.notifications) n.copyWith(read: true),
        ],
        unreadCount: 0,
      ),
    );
    try {
      await _markAllNotificationsReadUseCase.execute();
    } catch (e) {
      emit(
        previous.copyWith(
          notifications: previous.notifications,
          failure: Failure.from(e),
        ),
      );
    }
  }

  static List<NotificationEntity> _withRead(
    List<NotificationEntity> notifications,
    Set<String> ids,
    bool read,
  ) => [
    for (final n in notifications)
      ids.contains(n.id) ? n.copyWith(read: read) : n,
  ];
}

class NotificationsEvent {}

class LoadNotificationsEvent extends NotificationsEvent {
  /// The periodic check: no spinner and no error shown.
  final bool quiet;

  LoadNotificationsEvent({this.quiet = false});
}

class LoadMoreNotificationsEvent extends NotificationsEvent {}

class MarkNotificationReadEvent extends NotificationsEvent {
  final String id;

  MarkNotificationReadEvent({required this.id});
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {}

/// Forgets the notifications when the user signs out.
class ClearNotificationsEvent extends NotificationsEvent {}

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final int unreadCount;
  final Failure? failure;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.page = 0,
    this.hasNext = false,
    this.loadingMore = false,
    this.unreadCount = 0,
    this.failure,
  });

  /// [failure] is one-shot: it is cleared unless passed.
  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    int? unreadCount,
    Failure? failure,
  }) => NotificationsState(
    status: status,
    notifications: notifications ?? this.notifications,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    unreadCount: unreadCount ?? this.unreadCount,
    failure: failure,
  );
}
