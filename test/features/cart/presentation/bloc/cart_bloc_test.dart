import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/add_to_cart_cubit.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetCartUseCase getCart;
  late MockChangeCartItemQuantityUseCase changeQuantity;
  late MockRemoveCartItemUseCase removeItem;

  final cart = buildCart({
    's1': [buildCartItem(quantity: 2)],
    's2': [buildCartItem(id: '602')],
  });
  final changed = buildCart({
    's1': [buildCartItem(quantity: 3)],
    's2': [buildCartItem(id: '602')],
  });
  final withoutSocks = buildCart({
    's1': [buildCartItem(quantity: 2)],
  });

  CartBloc buildBloc() => CartBloc(
    getCartUseCase: getCart,
    changeCartItemQuantityUseCase: changeQuantity,
    removeCartItemUseCase: removeItem,
  );

  TypeMatcher<CartLoaded> loaded({
    CartEntity? cart,
    String? busyItemId,
    String? notice,
    TypeMatcher<Failure>? failure,
  }) {
    var matcher = isA<CartLoaded>()
        .having((s) => s.busyItemId, 'busyItemId', busyItemId)
        .having((s) => s.notice, 'notice', notice)
        .having((s) => s.failure, 'failure', failure ?? isNull);
    if (cart != null) matcher = matcher.having((s) => s.cart, 'cart', cart);
    return matcher;
  }

  setUp(() {
    getCart = MockGetCartUseCase();
    changeQuantity = MockChangeCartItemQuantityUseCase();
    removeItem = MockRemoveCartItemUseCase();
  });

  test('starts inactive', () {
    expect(buildBloc().state, isA<CartInactive>());
  });

  group('LoadCartEvent', () {
    blocTest<CartBloc, CartState>(
      'loads the cart',
      setUp: () => when(getCart.execute).thenAnswer((_) async => cart),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadCartEvent()),
      expect: () => [isA<CartLoading>(), loaded(cart: cart)],
    );

    blocTest<CartBloc, CartState>(
      'emits a load failure on the first load',
      setUp: () =>
          when(getCart.execute).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadCartEvent()),
      expect: () => [
        isA<CartLoading>(),
        isA<CartLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ],
    );

    blocTest<CartBloc, CartState>(
      'a failed refresh keeps the cart on screen',
      setUp: () => when(
        getCart.execute,
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(LoadCartEvent()),
      expect: () => [loaded(cart: cart, failure: isA<NetworkFailure>())],
    );
  });

  blocTest<CartBloc, CartState>(
    'ClearCartEvent forgets the cart',
    build: buildBloc,
    seed: () => CartLoaded(cart: cart),
    act: (bloc) => bloc.add(ClearCartEvent()),
    expect: () => [isA<CartInactive>()],
  );

  blocTest<CartBloc, CartState>(
    'CartUpdatedEvent shows a cart changed elsewhere',
    build: buildBloc,
    seed: () => CartLoaded(cart: cart),
    act: (bloc) => bloc.add(CartUpdatedEvent(cart: changed)),
    expect: () => [loaded(cart: changed)],
  );

  group('ChangeCartItemQuantityEvent', () {
    blocTest<CartBloc, CartState>(
      'marks the item busy, then shows the new cart',
      setUp: () => when(
        () => changeQuantity.execute('601', 3),
      ).thenAnswer((_) async => changed),
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(
        ChangeCartItemQuantityEvent(advertisementId: '601', quantity: 3),
      ),
      expect: () => [
        loaded(cart: cart, busyItemId: '601'),
        loaded(cart: changed),
      ],
    );

    blocTest<CartBloc, CartState>(
      'ignores actions while another one runs',
      build: buildBloc,
      seed: () => CartLoaded(cart: cart, busyItemId: '602'),
      act: (bloc) => bloc.add(
        ChangeCartItemQuantityEvent(advertisementId: '601', quantity: 3),
      ),
      expect: () => <CartState>[],
      verify: (_) => verifyNever(() => changeQuantity.execute(any(), any())),
    );

    blocTest<CartBloc, CartState>(
      'ignores actions before the cart is loaded',
      build: buildBloc,
      act: (bloc) => bloc.add(
        ChangeCartItemQuantityEvent(advertisementId: '601', quantity: 3),
      ),
      expect: () => <CartState>[],
    );

    blocTest<CartBloc, CartState>(
      'reloads the cart when the stock changed',
      setUp: () {
        when(() => changeQuantity.execute('601', 3)).thenThrow(
          buildDioException(
            statusCode: 409,
            data: {
              'error': 'out of stock',
              'items': [
                {'advertisement_id': '601', 'requested': 3, 'available': 2},
              ],
            },
          ),
        );
        when(getCart.execute).thenAnswer((_) async => withoutSocks);
      },
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(
        ChangeCartItemQuantityEvent(advertisementId: '601', quantity: 3),
      ),
      expect: () => [
        loaded(cart: cart, busyItemId: '601'),
        loaded(cart: withoutSocks, failure: isA<OutOfStockFailure>()),
      ],
    );

    blocTest<CartBloc, CartState>(
      'keeps the cart on other failures',
      setUp: () => when(
        () => changeQuantity.execute('601', 3),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(
        ChangeCartItemQuantityEvent(advertisementId: '601', quantity: 3),
      ),
      expect: () => [
        loaded(cart: cart, busyItemId: '601'),
        loaded(cart: cart, failure: isA<ServerFailure>()),
      ],
    );
  });

  group('RemoveCartItemEvent', () {
    blocTest<CartBloc, CartState>(
      'removes the item with a notice',
      setUp: () => when(
        () => removeItem.execute('602'),
      ).thenAnswer((_) async => withoutSocks),
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(RemoveCartItemEvent(advertisementId: '602')),
      expect: () => [
        loaded(cart: cart, busyItemId: '602'),
        loaded(cart: withoutSocks, notice: 'Produto removido do carrinho.'),
      ],
    );

    blocTest<CartBloc, CartState>(
      'a gone item reloads the cart, keeping it if the reload fails',
      setUp: () {
        when(
          () => removeItem.execute('602'),
        ).thenThrow(buildDioException(statusCode: 404));
        when(getCart.execute).thenThrow(buildDioException(statusCode: 500));
      },
      build: buildBloc,
      seed: () => CartLoaded(cart: cart),
      act: (bloc) => bloc.add(RemoveCartItemEvent(advertisementId: '602')),
      expect: () => [
        loaded(cart: cart, busyItemId: '602'),
        loaded(cart: cart, failure: isA<ProductUnavailableFailure>()),
      ],
    );
  });

  group('AddToCartCubit', () {
    late MockAddToCartUseCase addToCart;

    setUp(() => addToCart = MockAddToCartUseCase());

    blocTest<AddToCartCubit, AddToCartState>(
      'adds and returns the new cart',
      setUp: () =>
          when(() => addToCart.execute('601', 2)).thenAnswer((_) async => cart),
      build: () => AddToCartCubit(addToCartUseCase: addToCart),
      act: (cubit) => cubit.add('601', 2),
      expect: () => [
        isA<AddToCartInProgress>(),
        isA<AddToCartSuccess>().having((s) => s.cart, 'cart', cart),
      ],
    );

    blocTest<AddToCartCubit, AddToCartState>(
      'reports the failure',
      setUp: () => when(() => addToCart.execute('601', 1)).thenThrow(
        buildDioException(
          statusCode: 409,
          data: {'error': 'cannot buy your own advertisement'},
        ),
      ),
      build: () => AddToCartCubit(addToCartUseCase: addToCart),
      act: (cubit) => cubit.add('601', 1),
      expect: () => [
        isA<AddToCartInProgress>(),
        isA<AddToCartFailure>().having(
          (s) => s.failure,
          'failure',
          isA<OwnAdvertisementFailure>(),
        ),
      ],
    );

    blocTest<AddToCartCubit, AddToCartState>(
      'ignores a second tap while adding',
      build: () => AddToCartCubit(addToCartUseCase: addToCart),
      seed: () => AddToCartInProgress(),
      act: (cubit) => cubit.add('601', 1),
      expect: () => <AddToCartState>[],
      verify: (_) => verifyNever(() => addToCart.execute(any(), any())),
    );
  });
}
