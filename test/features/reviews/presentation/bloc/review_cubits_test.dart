import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/product_reviews_cubit.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/review_form_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  const input = NewReview(productRating: 5, sellerRating: 4);

  setUpAll(() => registerFallbackValue(input));

  group('ReviewFormCubit', () {
    late MockCreateReviewUseCase createReview;

    ReviewFormCubit buildCubit() => ReviewFormCubit(
      createReviewUseCase: createReview,
      orderId: 'o1',
      itemId: 'i1',
    );

    void answer({bool suggestSupport = false}) =>
        when(() => createReview.execute('o1', 'i1', any())).thenAnswer(
          (_) async => (review: buildReview(), suggestSupport: suggestSupport),
        );

    setUp(() => createReview = MockCreateReviewUseCase());

    blocTest<ReviewFormCubit, ReviewFormState>(
      'sends the review',
      setUp: answer,
      build: buildCubit,
      act: (cubit) => cubit.submit(input, hadProblems: false),
      expect: () => [
        isA<ReviewFormState>().having((s) => s.sending, 'sending', true),
        isA<ReviewFormState>()
            .having((s) => s.sent, 'sent', isNotNull)
            .having((s) => s.suggestSupport, 'suggestSupport', false),
      ],
      verify: (_) =>
          verify(() => createReview.execute('o1', 'i1', input)).called(1),
    );

    for (final (name, suggest, problems) in [
      ('a low comfort', true, false),
      ('a problem the buyer ticked', false, true),
    ]) {
      blocTest<ReviewFormCubit, ReviewFormState>(
        'suggests support after $name (UC-010)',
        setUp: () => answer(suggestSupport: suggest),
        build: buildCubit,
        act: (cubit) => cubit.submit(input, hadProblems: problems),
        skip: 1,
        expect: () => [
          isA<ReviewFormState>().having(
            (s) => s.suggestSupport,
            'suggestSupport',
            true,
          ),
        ],
      );
    }

    blocTest<ReviewFormCubit, ReviewFormState>(
      'shows why it could not send',
      setUp: () =>
          when(() => createReview.execute('o1', 'i1', any())).thenThrow(
            buildDioException(
              statusCode: 409,
              data: {'error': 'item already reviewed'},
            ),
          ),
      build: buildCubit,
      act: (cubit) => cubit.submit(input, hadProblems: false),
      skip: 1,
      expect: () => [
        isA<ReviewFormState>()
            .having((s) => s.failure, 'failure', isA<AlreadyReviewedFailure>())
            .having((s) => s.sending, 'sending', false),
      ],
    );

    blocTest<ReviewFormCubit, ReviewFormState>(
      'sends once',
      setUp: answer,
      build: buildCubit,
      seed: () => ReviewFormState(sent: buildReview()),
      act: (cubit) => cubit.submit(input, hadProblems: false),
      expect: () => const <ReviewFormState>[],
      verify: (_) =>
          verifyNever(() => createReview.execute(any(), any(), any())),
    );
  });

  group('ProductReviewsCubit', () {
    late MockGetProductReviewsUseCase getReviews;

    ProductReviewsCubit buildCubit() => ProductReviewsCubit(
      getProductReviewsUseCase: getReviews,
      advertisementId: '601',
    );

    ReviewsPageEntity page(int number, {required bool hasNext}) =>
        ReviewsPageEntity(
          items: [buildPublicReview(id: 'r$number')],
          currentPage: number,
          totalItems: 6,
          hasNext: hasNext,
        );

    setUp(() => getReviews = MockGetProductReviewsUseCase());

    blocTest<ProductReviewsCubit, ProductReviewsState>(
      'loads the first reviews and then more',
      setUp: () {
        when(
          () => getReviews.execute('601', 1),
        ).thenAnswer((_) async => page(1, hasNext: true));
        when(
          () => getReviews.execute('601', 2),
        ).thenAnswer((_) async => page(2, hasNext: false));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
        await cubit.loadMore();
      },
      expect: () => [
        isA<ProductReviewsState>().having(
          (s) => s.status,
          'status',
          ProductReviewsStatus.loading,
        ),
        isA<ProductReviewsState>()
            .having((s) => s.reviews.length, 'reviews', 1)
            .having((s) => s.total, 'total', 6),
        isA<ProductReviewsState>().having(
          (s) => s.loadingMore,
          'loadingMore',
          true,
        ),
        isA<ProductReviewsState>()
            .having((s) => s.reviews.map((r) => r.id), 'reviews', ['r1', 'r2'])
            .having((s) => s.hasNext, 'hasNext', false),
      ],
      verify: (_) => verify(() => getReviews.execute('601', 2)).called(1),
    );

    blocTest<ProductReviewsCubit, ProductReviewsState>(
      'a failed load can be retried',
      setUp: () => when(
        () => getReviews.execute('601', 1),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<ProductReviewsState>().having(
          (s) => s.status,
          'status',
          ProductReviewsStatus.failure,
        ),
      ],
    );
  });
}
