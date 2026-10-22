import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/reviews/data/models/review_model.dart';
import 'package:solado_certo_app/features/reviews/data/repositories/api_review_repository.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> createdJson({bool suggestSupport = false}) => {
  'id': 'r1',
  'order_item_id': 'i1',
  'product_rating': 4,
  'seller_rating': 5,
  'comfort_rating': 2,
  'comment': null,
  'adaptation_feedback': 'Machucou no calcanhar',
  'suggest_support': suggestSupport,
  'created_at': '2026-10-21T13:00:00Z',
};

Map<String, dynamic> reviewsJson() => {
  'items': [
    {
      'id': 'r1',
      'reviewer_name': 'Maria',
      'product_rating': 4,
      'seller_rating': 5,
      'comfort_rating': 5,
      'comment': 'Ótima',
      'created_at': '2026-10-21T13:00:00Z',
    },
  ],
  'current_page': 1,
  'total_pages': 2,
  'total_items': 6,
  'has_next': true,
  'has_previous': false,
};

void main() {
  group('models', () {
    test('reads a review just sent, with the support suggestion', () {
      final created = createdReviewFromJson(createdJson(suggestSupport: true));

      expect(created.suggestSupport, isTrue);
      expect(created.review.productRating, 4);
      expect(created.review.comfortRating, 2);
      expect(created.review.adaptationFeedback, 'Machucou no calcanhar');
      expect(created.review.createdAt, DateTime.utc(2026, 10, 21, 13));
    });

    test("reads a page of a product's reviews", () {
      final page = reviewsPageFromJson(reviewsJson());

      expect(page.totalItems, 6);
      expect(page.hasNext, isTrue);
      final review = page.items.single;
      expect(review.reviewerName, 'Maria');
      expect(review.productRating, 4);
      expect(review.comment, 'Ótima');
    });

    test('sends the ratings and leaves empty texts out', () {
      expect(
        newReviewToJson(
          const NewReview(
            productRating: 5,
            sellerRating: 4,
            comment: '  ',
            adaptationFeedback: ' Sem dores ',
          ),
        ),
        {
          'product_rating': 5,
          'seller_rating': 4,
          'adaptation_feedback': 'Sem dores',
        },
      );
    });
  });

  group('ApiReviewRepository', () {
    late MockClient client;
    late ApiReviewRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiReviewRepository(client);
    });

    test('reviews one item of an order', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => createdJson());

      final created = await repository.createReview(
        'o1',
        'i1',
        const NewReview(productRating: 4, sellerRating: 5, comfortRating: 2),
      );

      expect(created.suggestSupport, isFalse);
      verify(
        () => client.post(
          '/orders/o1/items/i1/review',
          data: {'product_rating': 4, 'seller_rating': 5, 'comfort_rating': 2},
        ),
      ).called(1);
    });

    test("asks for a page of a product's reviews", () async {
      when(() => client.get(any())).thenAnswer((_) async => reviewsJson());

      await repository.getProductReviews('601', 2);

      verify(
        () => client.get('/catalog/items/601/reviews?page=2&limit=5'),
      ).called(1);
    });
  });
}
