import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/add_to_cart_cubit.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/seller.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/product_detail_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/product_reviews_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockProductDetailCubit extends MockCubit<ProductDetailState>
    implements ProductDetailCubit {}

class MockProductReviewsCubit extends MockCubit<ProductReviewsState>
    implements ProductReviewsCubit {}

void main() {
  late MockProductDetailCubit cubit;
  late MockCartBloc cartBloc;
  late MockAddToCartCubit addToCart;
  late MockProductReviewsCubit reviews;

  Future<void> pumpPage(WidgetTester tester, ProductDetailState state) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    return tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>.value(value: cartBloc),
          BlocProvider<ProductDetailCubit>.value(value: cubit),
          BlocProvider<AddToCartCubit>.value(value: addToCart),
          BlocProvider<ProductReviewsCubit>.value(value: reviews),
        ],
        child: MaterialApp(
          home: const ProductDetailPage(),
          routes: {'/sign-in': (_) => const Text('Entrar')},
        ),
      ),
    );
  }

  setUpAll(initializeFormatting);

  setUp(() {
    cubit = MockProductDetailCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    cartBloc = buildCartBloc(CartLoaded(cart: buildCart({})));
    addToCart = MockAddToCartCubit();
    when(() => addToCart.state).thenReturn(AddToCartIdle());
    when(() => addToCart.add(any(), any())).thenAnswer((_) async {});
    reviews = MockProductReviewsCubit();
    when(() => reviews.state).thenReturn(
      const ProductReviewsState(status: ProductReviewsStatus.loaded),
    );
  });

  testWidgets('shows the product, its attributes, seller and shipping', (
    tester,
  ) async {
    await pumpPage(tester, ProductDetailLoaded(product: buildProductDetail()));

    expect(find.text('Órtese corretora para joanete'), findsOneWidget);
    expect(find.text(formatCurrency(129.5)), findsOneWidget);
    expect(find.text('Em estoque (15 unidades)'), findsOneWidget);
    expect(find.text('Correção'), findsOneWidget);
    expect(find.text('Joanete'), findsOneWidget);
    expect(find.text('Pé esquerdo'), findsOneWidget);
    expect(find.text('Rígido'), findsOneWidget);
    expect(find.text('Loja Pé Bem'), findsOneWidget);
    expect(find.text('No Solado Certo desde outubro de 2026'), findsOneWidget);
    expect(find.text('PAC · Correios'), findsOneWidget);
    expect(find.text('Até 7 dias úteis'), findsOneWidget);
  });

  testWidgets('shows the safety section without a warning when complete', (
    tester,
  ) async {
    await pumpPage(tester, ProductDetailLoaded(product: buildProductDetail()));

    expect(find.text('Segurança de uso'), findsOneWidget);
    expect(find.text('Uso noturno'), findsOneWidget);
    expect(
      find.text('Uso apenas com orientação profissional.'),
      findsOneWidget,
    );
    expect(find.text('Pós-operatório recente.'), findsOneWidget);
    expect(
      find.text('Exige prescrição de um profissional de saúde.'),
      findsOneWidget,
    );
    expect(find.text('Informações de segurança incompletas'), findsNothing);
  });

  testWidgets('warns when the safety information is incomplete', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ProductDetailLoaded(
        product: buildProductDetail(
          contraindications: null,
          safetyInfoComplete: false,
        ),
      ),
    );

    expect(find.text('Informações de segurança incompletas'), findsOneWidget);
    expect(find.text('Não informado'), findsOneWidget);
  });

  testWidgets('shows a sold out product and keeps the cart disabled', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ProductDetailLoaded(product: buildProductDetail(stock: 0)),
    );

    expect(find.text('Esgotado'), findsOneWidget);
    expect(find.text('ADICIONAR AO CARRINHO'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('ESGOTADO'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('says when the product no longer exists', (tester) async {
    await pumpPage(
      tester,
      ProductDetailLoadFailure(failure: NotFoundFailure()),
    );

    expect(find.text('Produto não encontrado'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsNothing);
    expect(find.text('ADICIONAR AO CARRINHO'), findsNothing);
  });

  testWidgets('retries after other failures', (tester) async {
    final failure = NetworkFailure();
    await pumpPage(tester, ProductDetailLoadFailure(failure: failure));

    expect(find.text(failure.message), findsOneWidget);
    await tester.tap(find.text('TENTAR NOVAMENTE'));

    verify(() => cubit.load()).called(1);
  });

  group('add to cart', () {
    setUpAll(() => registerFallbackValue(LoadCartEvent()));

    testWidgets('adds the chosen quantity', (tester) async {
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail()),
      );

      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await tester.pump();
      await tester.tap(find.text('ADICIONAR AO CARRINHO'));

      verify(() => addToCart.add('603', 2)).called(1);
    });

    testWidgets('limits the quantity to the stock', (tester) async {
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail(stock: 2)),
      );

      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(plus.onPressed, isNull);
    });

    testWidgets('asks a signed-out visitor to sign in', (tester) async {
      cartBloc = buildCartBloc();
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail()),
      );

      await tester.tap(find.text('ADICIONAR AO CARRINHO'));
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);
      verifyNever(() => addToCart.add(any(), any()));
    });

    testWidgets('hands the new cart to the cart bloc', (tester) async {
      final cart = buildCart({
        's1': [buildCartItem(id: '603')],
      });
      whenListen(
        addToCart,
        Stream<AddToCartState>.fromIterable([
          AddToCartInProgress(),
          AddToCartSuccess(cart: cart),
        ]),
        initialState: AddToCartIdle(),
      );
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail()),
      );
      await tester.pump();

      verify(
        () => cartBloc.add(
          any(
            that: isA<CartUpdatedEvent>().having((e) => e.cart, 'cart', cart),
          ),
        ),
      ).called(1);
      expect(find.text('Produto adicionado ao carrinho.'), findsOneWidget);
    });

    testWidgets('shows why it could not add', (tester) async {
      whenListen(
        addToCart,
        Stream<AddToCartState>.fromIterable([
          AddToCartFailure(failure: OwnAdvertisementFailure()),
        ]),
        initialState: AddToCartIdle(),
      );
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail()),
      );
      await tester.pump();

      expect(
        find.text('Você não pode comprar um anúncio seu.'),
        findsOneWidget,
      );
      verifyNever(() => cartBloc.add(any()));
    });
  });

  group('reviews (RF-024)', () {
    testWidgets("shows the seller's average and the latest reviews", (
      tester,
    ) async {
      when(() => reviews.state).thenReturn(
        ProductReviewsState(
          status: ProductReviewsStatus.loaded,
          reviews: [buildPublicReview()],
          page: 1,
          total: 6,
          hasNext: true,
        ),
      );
      when(() => reviews.loadMore()).thenAnswer((_) async {});
      await pumpPage(
        tester,
        ProductDetailLoaded(
          product: buildProductDetail(
            seller: SellerEntity(
              id: '2',
              name: 'Loja Pé Bem',
              state: 'SP',
              averageRating: 4.5,
              reviewCount: 12,
              memberSince: DateTime(2026, 10, 1),
            ),
          ),
        ),
      );

      expect(find.text('SP · ★ 4,5 (12)'), findsOneWidget);
      expect(find.text('Avaliações (6)'), findsOneWidget);
      expect(find.text('Maria · 21/10/2026'), findsOneWidget);
      expect(find.text('Conforto: Muito confortável'), findsOneWidget);
      expect(find.text('Confortável desde o primeiro dia'), findsOneWidget);

      await tester.tap(find.text('Ver mais avaliações'));
      verify(() => reviews.loadMore()).called(1);
    });

    testWidgets('says when there are none yet', (tester) async {
      await pumpPage(
        tester,
        ProductDetailLoaded(product: buildProductDetail()),
      );

      expect(find.text('Avaliações'), findsOneWidget);
      expect(
        find.text('Ainda não há avaliações deste produto.'),
        findsOneWidget,
      );
    });
  });
}
