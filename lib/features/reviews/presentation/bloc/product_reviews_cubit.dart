import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';

class ProductReviewsCubit extends Cubit<ProductReviewsState> {
  final GetProductReviewsUseCase _getProductReviewsUseCase;
  final String advertisementId;

  ProductReviewsCubit({
    required GetProductReviewsUseCase getProductReviewsUseCase,
    required this.advertisementId,
  }) : _getProductReviewsUseCase = getProductReviewsUseCase,
       super(const ProductReviewsState());

  Future<void> load() async {
    emit(const ProductReviewsState());
    try {
      final page = await _getProductReviewsUseCase.execute(advertisementId, 1);
      if (isClosed) return;
      emit(
        ProductReviewsState(
          status: ProductReviewsStatus.loaded,
          reviews: page.items,
          page: page.currentPage,
          total: page.totalItems,
          hasNext: page.hasNext,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(const ProductReviewsState(status: ProductReviewsStatus.failure));
    }
  }

  Future<void> loadMore() async {
    if (state.status != ProductReviewsStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getProductReviewsUseCase.execute(
        advertisementId,
        state.page + 1,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          reviews: [...state.reviews, ...page.items],
          page: page.currentPage,
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(loadingMore: false));
    }
  }
}

enum ProductReviewsStatus { loading, loaded, failure }

class ProductReviewsState {
  final ProductReviewsStatus status;
  final List<PublicReviewEntity> reviews;
  final int page;
  final int total;
  final bool hasNext;
  final bool loadingMore;

  const ProductReviewsState({
    this.status = ProductReviewsStatus.loading,
    this.reviews = const [],
    this.page = 0,
    this.total = 0,
    this.hasNext = false,
    this.loadingMore = false,
  });

  ProductReviewsState copyWith({
    List<PublicReviewEntity>? reviews,
    int? page,
    bool? hasNext,
    bool? loadingMore,
  }) => ProductReviewsState(
    status: status,
    reviews: reviews ?? this.reviews,
    page: page ?? this.page,
    total: total,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}
