import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/review_form_cubit.dart';
import 'package:solado_certo_app/features/reviews/presentation/pages/review_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockCreateReviewUseCase createReview;
  late List<bool?> results;
  late int supportOpened;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final reviewed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => ReviewFormCubit(
                          createReviewUseCase: createReview,
                          orderId: 'o1',
                          itemId: 'i1',
                        ),
                        child: ReviewPage(
                          item: buildOrderItem(itemId: 'i1'),
                          sellerName: 'Loja s1',
                          openSupport: (_) => supportOpened++,
                        ),
                      ),
                    ),
                  );
                  results.add(reviewed);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  void answer({bool suggestSupport = false}) =>
      when(() => createReview.execute('o1', 'i1', any())).thenAnswer(
        (_) async => (review: buildReview(), suggestSupport: suggestSupport),
      );

  /// The product's stars come first, the seller's second.
  Future<void> rate(
    WidgetTester tester, {
    required int product,
    required int seller,
  }) async {
    String stars(int count) => count == 1 ? '1 estrela' : '$count estrelas';
    await tester.tap(find.byTooltip(stars(product)).at(0));
    await tester.tap(find.byTooltip(stars(seller)).at(1));
    await tester.pump();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.text('ENVIAR AVALIAÇÃO'));
    await tester.pumpAndSettle();
  }

  NewReview sent() =>
      verify(
            () => createReview.execute('o1', 'i1', captureAny()),
          ).captured.single
          as NewReview;

  setUpAll(
    () => registerFallbackValue(
      const NewReview(productRating: 1, sellerRating: 1),
    ),
  );

  setUp(() {
    createReview = MockCreateReviewUseCase();
    results = [];
    supportOpened = 0;
  });

  testWidgets('needs both ratings before sending', (tester) async {
    await pumpPage(tester);

    await send(tester);

    expect(find.text('Escolha de 1 a 5 estrelas.'), findsNWidgets(2));
    verifyNever(() => createReview.execute(any(), any(), any()));
  });

  testWidgets('sends the ratings, comfort and texts, then goes back', (
    tester,
  ) async {
    answer();
    await pumpPage(tester);

    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.text('Vendido por Loja s1'), findsOneWidget);
    await rate(tester, product: 5, seller: 4);
    await tester.tap(find.text('Confortável'));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Duas semanas para acostumar',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Muito boa');
    await send(tester);

    final review = sent();
    expect(review.productRating, 5);
    expect(review.sellerRating, 4);
    expect(review.comfortRating, 4);
    expect(review.adaptationFeedback, 'Duas semanas para acostumar');
    expect(review.comment, 'Muito boa');
    expect(find.byType(ReviewPage), findsNothing);
    expect(results, [true]);
    expect(supportOpened, 0);
  });

  testWidgets('offers support after a low comfort (UC-010)', (tester) async {
    answer(suggestSupport: true);
    await pumpPage(tester);
    await rate(tester, product: 2, seller: 3);
    await tester.tap(find.text('Muito desconfortável'));
    await send(tester);

    expect(find.text('Precisa de ajuda?'), findsOneWidget);
    await tester.tap(find.text('Abrir suporte'));
    await tester.pumpAndSettle();

    expect(supportOpened, 1);
    expect(results, [true]);
  });

  testWidgets('offers support when the buyer had problems', (tester) async {
    answer();
    await pumpPage(tester);
    await rate(tester, product: 4, seller: 4);
    await tester.tap(find.text('Tive problemas com o produto'));
    await send(tester);

    expect(find.text('Precisa de ajuda?'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(supportOpened, 0);
    expect(results, [true]);
  });

  testWidgets('an item already reviewed goes back with the message', (
    tester,
  ) async {
    when(() => createReview.execute('o1', 'i1', any())).thenThrow(
      buildDioException(
        statusCode: 409,
        data: {'error': 'item already reviewed'},
      ),
    );
    await pumpPage(tester);
    await rate(tester, product: 4, seller: 4);
    await send(tester);

    expect(find.text('Você já avaliou este item.'), findsOneWidget);
    expect(results, [true]);
  });

  testWidgets('other failures keep the form', (tester) async {
    when(
      () => createReview.execute('o1', 'i1', any()),
    ).thenThrow(buildDioException(statusCode: 500));
    await pumpPage(tester);
    await rate(tester, product: 4, seller: 4);
    await send(tester);

    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.textContaining('Erro no servidor'), findsOneWidget);
    expect(results, isEmpty);
  });
}
