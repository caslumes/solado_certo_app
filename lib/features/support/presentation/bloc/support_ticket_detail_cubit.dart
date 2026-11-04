import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';

class SupportTicketDetailCubit extends Cubit<SupportTicketDetailState> {
  final GetSupportTicketUseCase _getTicketUseCase;
  final SendSupportMessageUseCase _sendMessageUseCase;
  final String ticketId;

  SupportTicketDetailCubit({
    required GetSupportTicketUseCase getTicketUseCase,
    required SendSupportMessageUseCase sendMessageUseCase,
    required this.ticketId,
  }) : _getTicketUseCase = getTicketUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       super(SupportTicketDetailLoading());

  Future<void> load() async {
    final current = state;
    if (current is! SupportTicketDetailLoaded) {
      emit(SupportTicketDetailLoading());
    }
    try {
      final detail = await _getTicketUseCase.execute(ticketId);
      if (isClosed) return;
      emit(SupportTicketDetailLoaded(detail: detail));
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is SupportTicketDetailLoaded
            ? SupportTicketDetailLoaded(
                detail: current.detail,
                failure: failure,
              )
            : SupportTicketDetailLoadFailure(failure: failure),
      );
    }
  }

  Future<bool> send(String message, {UploadFile? file}) async {
    final current = state;
    if (current is! SupportTicketDetailLoaded || current.sending) return false;

    emit(SupportTicketDetailLoaded(detail: current.detail, sending: true));
    try {
      final detail = await _sendMessageUseCase.execute(
        ticketId,
        message,
        file: file,
      );
      if (!isClosed) emit(SupportTicketDetailLoaded(detail: detail));
      return true;
    } catch (e) {
      final failure = Failure.from(e);
      var detail = current.detail;
      if (failure is TicketStatusChangedFailure) {
        try {
          detail = await _getTicketUseCase.execute(ticketId);
        } catch (_) {}
      }
      if (!isClosed) {
        emit(SupportTicketDetailLoaded(detail: detail, failure: failure));
      }
      return false;
    }
  }
}

sealed class SupportTicketDetailState {}

class SupportTicketDetailLoading extends SupportTicketDetailState {}

class SupportTicketDetailLoadFailure extends SupportTicketDetailState {
  final Failure failure;

  SupportTicketDetailLoadFailure({required this.failure});
}

class SupportTicketDetailLoaded extends SupportTicketDetailState {
  final SupportTicketDetailEntity detail;
  final bool sending;
  final Failure? failure;

  SupportTicketDetailLoaded({
    required this.detail,
    this.sending = false,
    this.failure,
  });
}
