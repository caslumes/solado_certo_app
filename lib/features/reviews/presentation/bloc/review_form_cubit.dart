import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';

class ReviewFormCubit extends Cubit<ReviewFormState> {
  final CreateReviewUseCase _createReviewUseCase;
  final String orderId;
  final String itemId;

  ReviewFormCubit({
    required CreateReviewUseCase createReviewUseCase,
    required this.orderId,
    required this.itemId,
  }) : _createReviewUseCase = createReviewUseCase,
       super(const ReviewFormState());

  /// Support is suggested when the backend finds the comfort low or the
  /// buyer says they [hadProblems] (UC-010).
  Future<void> submit(NewReview review, {required bool hadProblems}) async {
    if (state.sending || state.sent != null) return;
    emit(const ReviewFormState(sending: true));
    try {
      final created = await _createReviewUseCase.execute(
        orderId,
        itemId,
        review,
      );
      emit(
        ReviewFormState(
          sent: created.review,
          suggestSupport: created.suggestSupport || hadProblems,
        ),
      );
    } catch (e) {
      emit(ReviewFormState(failure: Failure.from(e)));
    }
  }
}

class ReviewFormState {
  final bool sending;
  final ReviewEntity? sent;
  final bool suggestSupport;
  final Failure? failure;

  const ReviewFormState({
    this.sending = false,
    this.sent,
    this.suggestSupport = false,
    this.failure,
  });
}
