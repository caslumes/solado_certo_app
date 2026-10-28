import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';

class SellerCustomOrderDetailCubit extends Cubit<CustomOrderDetailState> {
  final GetSellerCustomOrderUseCase _getCustomOrderUseCase;
  final ReviewCustomOrderUseCase _reviewUseCase;
  final AcceptCustomOrderUseCase _acceptUseCase;
  final RejectCustomOrderUseCase _rejectUseCase;
  final RequestCustomOrderInfoUseCase _requestInfoUseCase;
  final SendFittingReportUseCase _sendReportUseCase;
  final String requestId;

  SellerCustomOrderDetailCubit({
    required GetSellerCustomOrderUseCase getCustomOrderUseCase,
    required ReviewCustomOrderUseCase reviewUseCase,
    required AcceptCustomOrderUseCase acceptUseCase,
    required RejectCustomOrderUseCase rejectUseCase,
    required RequestCustomOrderInfoUseCase requestInfoUseCase,
    required SendFittingReportUseCase sendReportUseCase,
    required this.requestId,
  }) : _getCustomOrderUseCase = getCustomOrderUseCase,
       _reviewUseCase = reviewUseCase,
       _acceptUseCase = acceptUseCase,
       _rejectUseCase = rejectUseCase,
       _requestInfoUseCase = requestInfoUseCase,
       _sendReportUseCase = sendReportUseCase,
       super(CustomOrderDetailLoading());

  Future<void> load() async {
    final current = state;
    if (current is! CustomOrderDetailLoaded) emit(CustomOrderDetailLoading());
    try {
      final detail = await _getCustomOrderUseCase.execute(requestId);
      if (isClosed) return;
      emit(CustomOrderDetailLoaded(detail: detail));
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is CustomOrderDetailLoaded
            ? CustomOrderDetailLoaded(detail: current.detail, failure: failure)
            : CustomOrderDetailLoadFailure(failure: failure),
      );
    }
  }

  Future<Failure?> review() => _change(
    () => _reviewUseCase.execute(requestId),
    notice: 'Análise iniciada. O comprador foi avisado.',
  );

  Future<Failure?> accept(String quotedPrice) => _change(
    () => _acceptUseCase.execute(requestId, quotedPrice),
    notice: 'Solicitação aceita. O comprador vai confirmar e pagar.',
  );

  Future<Failure?> reject(String reason) => _change(
    () => _rejectUseCase.execute(requestId, reason),
    notice: 'Solicitação recusada.',
  );

  Future<Failure?> requestInfo(String question) => _change(
    () => _requestInfoUseCase.execute(requestId, question),
    notice: 'Pergunta enviada ao comprador.',
  );

  Future<Failure?> sendReport(UploadFile file, String adaptationInstructions) =>
      _change(
        () => _sendReportUseCase.execute(
          requestId,
          file: file,
          adaptationInstructions: adaptationInstructions,
        ),
        notice: 'Laudo enviado ao comprador.',
      );

  Future<Failure?> _change(
    Future<CustomOrderDetailEntity> Function() action, {
    required String notice,
  }) async {
    final current = state;
    if (current is! CustomOrderDetailLoaded || current.working) return null;

    emit(CustomOrderDetailLoaded(detail: current.detail, working: true));
    try {
      final detail = await action();
      if (!isClosed) {
        emit(CustomOrderDetailLoaded(detail: detail, notice: notice));
      }
      return null;
    } catch (e) {
      final failure = Failure.from(e);
      var detail = current.detail;
      if (failure is OrderStatusChangedFailure) {
        try {
          detail = await _getCustomOrderUseCase.execute(requestId);
        } catch (_) {}
      }
      if (!isClosed) {
        emit(CustomOrderDetailLoaded(detail: detail, failure: failure));
      }
      return failure;
    }
  }
}
