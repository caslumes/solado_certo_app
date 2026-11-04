import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';

class SupportTicketsCubit extends Cubit<SupportTicketsState> {
  final GetSupportTicketsUseCase _getTicketsUseCase;

  int _generation = 0;

  SupportTicketsCubit({required GetSupportTicketsUseCase getTicketsUseCase})
    : _getTicketsUseCase = getTicketsUseCase,
      super(const SupportTicketsState());

  Future<void> load() async {
    final generation = ++_generation;
    final refreshing = state.status == SupportTicketsStatus.loaded;
    if (!refreshing) {
      emit(const SupportTicketsState(status: SupportTicketsStatus.loading));
    }
    try {
      final page = await _getTicketsUseCase.execute(1);
      if (isClosed || generation != _generation) return;
      emit(
        SupportTicketsState(
          status: SupportTicketsStatus.loaded,
          tickets: page.items,
          page: page.currentPage,
          hasNext: page.hasNext,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      final failure = Failure.from(e);
      emit(
        refreshing
            ? state.copyWith(failure: failure)
            : SupportTicketsState(
                status: SupportTicketsStatus.failure,
                failure: failure,
              ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != SupportTicketsStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getTicketsUseCase.execute(state.page + 1);
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          tickets: [...state.tickets, ...page.items],
          page: page.currentPage,
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loadingMore: false, failure: Failure.from(e)));
    }
  }
}

enum SupportTicketsStatus { initial, loading, loaded, failure }

class SupportTicketsState {
  final SupportTicketsStatus status;
  final List<SupportTicketEntity> tickets;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final Failure? failure;

  const SupportTicketsState({
    this.status = SupportTicketsStatus.initial,
    this.tickets = const [],
    this.page = 0,
    this.hasNext = false,
    this.loadingMore = false,
    this.failure,
  });

  SupportTicketsState copyWith({
    List<SupportTicketEntity>? tickets,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    Failure? failure,
  }) => SupportTicketsState(
    status: status,
    tickets: tickets ?? this.tickets,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure,
  );
}
