import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';

class SupportTicketFormCubit extends Cubit<SupportTicketFormState> {
  final CreateSupportTicketUseCase _createTicketUseCase;

  SupportTicketFormCubit({
    required CreateSupportTicketUseCase createTicketUseCase,
  }) : _createTicketUseCase = createTicketUseCase,
       super(const SupportTicketFormState());

  Future<void> submit(NewSupportTicket ticket) async {
    if (state.sending || state.created != null) return;
    emit(const SupportTicketFormState(sending: true));
    try {
      final created = await _createTicketUseCase.execute(ticket);
      emit(SupportTicketFormState(created: created));
    } catch (e) {
      emit(SupportTicketFormState(failure: Failure.from(e)));
    }
  }
}

class SupportTicketFormState {
  final bool sending;
  final SupportTicketDetailEntity? created;
  final Failure? failure;

  const SupportTicketFormState({
    this.sending = false,
    this.created,
    this.failure,
  });
}
