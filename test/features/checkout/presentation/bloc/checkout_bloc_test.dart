import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/domain/enum/checkout_step.dart';
import 'package:solado_certo_app/features/checkout/presentation/bloc/checkout_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

const pac = ShippingOptionEntity(
  id: 'pac',
  name: 'PAC',
  price: 19.9,
  deliveryDays: 7,
);
const sedex = ShippingOptionEntity(
  id: 'sedex',
  name: 'SEDEX',
  price: 29.9,
  deliveryDays: 3,
);

CartItemEntity itemWith(String id, List<ShippingOptionEntity> options) =>
    CartItemEntity(
      advertisementId: id,
      title: 'Palmilha $id',
      quantity: 1,
      unitPrice: 89.9,
      addedUnitPrice: 89.9,
      stock: 10,
      subtotal: 89.9,
      shippingOptions: options,
    );

void main() {
  late MockGetAddressesUseCase getAddresses;
  late MockPreviewCheckoutUseCase preview;
  late MockCheckoutUseCase checkout;

  final cart = buildCart({
    's1': [
      itemWith('601', [pac, sedex]),
      itemWith('602', [pac]),
    ],
    's2': [
      itemWith('603', [pac, sedex]),
    ],
  });
  final home = buildAddress(id: 'a1');
  final work = buildAddress(id: 'a2', label: 'Trabalho', isDefault: true);
  final plan = buildCheckoutPlan(sellers: ['s1', 's2']);
  final result = buildCheckoutResult();

  CheckoutBloc buildBloc({CartEntity? withCart}) => CheckoutBloc(
    cart: withCart ?? cart,
    getAddressesUseCase: getAddresses,
    previewCheckoutUseCase: preview,
    checkoutUseCase: checkout,
    newKey: () => 'key-1',
  );

  CheckoutState ready({CheckoutStep step = CheckoutStep.address}) =>
      CheckoutState(
        status: CheckoutStatus.ready,
        cart: cart,
        addresses: [home, work],
        addressId: home.id,
        shipping: const {'601': 'pac', '602': 'pac', '603': 'sedex'},
        step: step,
        plan: step == CheckoutStep.review ? plan : null,
      );

  setUpAll(() {
    registerFallbackValue(const CheckoutSelection(addressId: '', shipping: {}));
  });

  setUp(() {
    getAddresses = MockGetAddressesUseCase();
    preview = MockPreviewCheckoutUseCase();
    checkout = MockCheckoutUseCase();
  });

  test('starts with the cheapest shipping option of each item', () {
    final noOptions = buildCart({
      's1': [
        itemWith('601', [pac, sedex]),
        itemWith('602', []),
      ],
    });

    final state = buildBloc(withCart: noOptions).state;

    expect(state.shipping, {'601': 'pac'});
    expect(state.itemsWithoutShipping.map((i) => i.advertisementId), ['602']);
  });

  test('the shipping of a seller is its most expensive chosen option', () {
    final state = ready();

    expect(state.shippingFor(cart.groups[0]), 19.9);
    expect(state.shippingFor(cart.groups[1]), 29.9);
  });

  group('LoadCheckoutEvent', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'loads the addresses and chooses the default one',
      setUp: () =>
          when(getAddresses.execute).thenAnswer((_) async => [home, work]),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadCheckoutEvent()),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.loading,
        ),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.ready)
            .having((s) => s.addresses, 'addresses', [home, work])
            .having((s) => s.addressId, 'addressId', 'a2'),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'chooses the first address without a default, none without addresses',
      setUp: () => when(getAddresses.execute).thenAnswer((_) async => [home]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadCheckoutEvent());
        await bloc.stream.firstWhere((s) => s.status == CheckoutStatus.ready);
        when(getAddresses.execute).thenAnswer((_) async => []);
        bloc.add(LoadCheckoutEvent());
      },
      skip: 2,
      expect: () => [
        isA<CheckoutState>(),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.ready)
            .having((s) => s.addressId, 'addressId', isNull),
      ],
      verify: (bloc) => expect(bloc.state.addresses, isEmpty),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a failure shows the load error',
      setUp: () => when(
        getAddresses.execute,
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadCheckoutEvent()),
      skip: 1,
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.loadFailure)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });

  blocTest<CheckoutBloc, CheckoutState>(
    'an address added from checkout becomes the chosen one',
    build: buildBloc,
    seed: ready,
    act: (bloc) {
      bloc.add(AddressAddedEvent(address: buildAddress(id: 'a3')));
    },
    expect: () => [
      isA<CheckoutState>()
          .having((s) => s.addresses.map((a) => a.id), 'addresses', [
            'a1',
            'a2',
            'a3',
          ])
          .having((s) => s.addressId, 'addressId', 'a3'),
    ],
  );

  blocTest<CheckoutBloc, CheckoutState>(
    'selects an address and a shipping option',
    build: buildBloc,
    seed: ready,
    act: (bloc) => bloc
      ..add(SelectAddressEvent(addressId: 'a2'))
      ..add(
        SelectShippingEvent(advertisementId: '601', shippingOptionId: 'sedex'),
      ),
    expect: () => [
      isA<CheckoutState>().having((s) => s.addressId, 'addressId', 'a2'),
      isA<CheckoutState>().having((s) => s.shipping, 'shipping', {
        '601': 'sedex',
        '602': 'pac',
        '603': 'sedex',
      }),
    ],
  );

  group('GoToCheckoutStepEvent', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'needs an address before shipping',
      build: buildBloc,
      seed: () => CheckoutState(status: CheckoutStatus.ready, cart: cart),
      act: (bloc) =>
          bloc.add(GoToCheckoutStepEvent(step: CheckoutStep.shipping)),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.step,
          'step',
          CheckoutStep.address,
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'goes to shipping, then back, without asking the server',
      build: buildBloc,
      seed: ready,
      act: (bloc) => bloc
        ..add(GoToCheckoutStepEvent(step: CheckoutStep.shipping))
        ..add(GoToCheckoutStepEvent(step: CheckoutStep.address)),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.step,
          'step',
          CheckoutStep.shipping,
        ),
        isA<CheckoutState>().having(
          (s) => s.step,
          'step',
          CheckoutStep.address,
        ),
      ],
      verify: (_) => verifyNever(() => preview.execute(any())),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'reaching the summary previews the orders',
      setUp: () =>
          when(() => preview.execute(any())).thenAnswer((_) async => plan),
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.shipping),
      act: (bloc) => bloc.add(GoToCheckoutStepEvent(step: CheckoutStep.review)),
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.activity, 'activity', CheckoutActivity.previewing)
            .having((s) => s.step, 'step', CheckoutStep.shipping),
        isA<CheckoutState>()
            .having((s) => s.activity, 'activity', CheckoutActivity.idle)
            .having((s) => s.step, 'step', CheckoutStep.review)
            .having((s) => s.plan, 'plan', plan),
      ],
      verify: (_) {
        final selection =
            verify(() => preview.execute(captureAny())).captured.single
                as CheckoutSelection;
        expect(selection.addressId, 'a1');
        expect(selection.shipping, {
          '601': 'pac',
          '602': 'pac',
          '603': 'sedex',
        });
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'an item without shipping keeps the buyer on the shipping step',
      build: () => buildBloc(
        withCart: buildCart({
          's1': [itemWith('601', [])],
        }),
      ),
      seed: () => CheckoutState(
        status: CheckoutStatus.ready,
        cart: buildCart({
          's1': [itemWith('601', [])],
        }),
        addresses: [home],
        addressId: home.id,
        step: CheckoutStep.shipping,
      ),
      act: (bloc) => bloc.add(GoToCheckoutStepEvent(step: CheckoutStep.review)),
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.step, 'step', CheckoutStep.shipping)
            .having(
              (s) => s.failure,
              'failure',
              isA<ShippingRequiredFailure>().having(
                (f) => f.advertisementIds,
                'ids',
                ['601'],
              ),
            ),
      ],
      verify: (_) => verifyNever(() => preview.execute(any())),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a stock conflict in the preview hands back the current cart',
      setUp: () => when(() => preview.execute(any())).thenThrow(
        CheckoutConflict(
          failure: const OutOfStockFailure([]),
          cart: buildCart({
            's1': [buildCartItem()],
          }),
        ),
      ),
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.shipping),
      act: (bloc) => bloc.add(GoToCheckoutStepEvent(step: CheckoutStep.review)),
      skip: 1,
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.step, 'step', CheckoutStep.shipping)
            .having((s) => s.conflictCart?.items.length, 'conflictCart', 1)
            .having((s) => s.failure, 'failure', isA<OutOfStockFailure>()),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a deleted address goes back to the address step without it',
      setUp: () => when(() => preview.execute(any())).thenThrow(
        buildDioException(
          statusCode: 404,
          data: {'error': 'address not found'},
        ),
      ),
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.shipping),
      act: (bloc) => bloc.add(GoToCheckoutStepEvent(step: CheckoutStep.review)),
      skip: 1,
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.step, 'step', CheckoutStep.address)
            .having((s) => s.addresses, 'addresses', [work])
            .having((s) => s.addressId, 'addressId', isNull)
            .having((s) => s.failure, 'failure', isA<AddressNotFoundFailure>()),
      ],
    );
  });

  group('ConfirmCheckoutEvent', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'creates the orders with the idempotency key',
      setUp: () => when(
        () => checkout.execute(any(), any()),
      ).thenAnswer((_) async => result),
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.review),
      act: (bloc) => bloc.add(ConfirmCheckoutEvent()),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.activity,
          'activity',
          CheckoutActivity.submitting,
        ),
        isA<CheckoutState>()
            .having((s) => s.activity, 'activity', CheckoutActivity.idle)
            .having((s) => s.result, 'result', result),
      ],
      verify: (_) => verify(() => checkout.execute(any(), 'key-1')).called(1),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'retrying after a lost answer reuses the same key',
      setUp: () {
        var calls = 0;
        when(() => checkout.execute(any(), any())).thenAnswer((_) async {
          if (calls++ == 0) {
            throw buildDioException(type: DioExceptionType.receiveTimeout);
          }
          return result;
        });
      },
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.review),
      act: (bloc) async {
        bloc.add(ConfirmCheckoutEvent());
        await bloc.stream.firstWhere((s) => s.failure != null);
        bloc.add(ConfirmCheckoutEvent());
      },
      expect: () => [
        isA<CheckoutState>(),
        isA<CheckoutState>()
            .having((s) => s.failure, 'failure', isA<NetworkFailure>())
            .having((s) => s.step, 'step', CheckoutStep.review),
        isA<CheckoutState>(),
        isA<CheckoutState>().having((s) => s.result, 'result', result),
      ],
      verify: (_) => verify(() => checkout.execute(any(), 'key-1')).called(2),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a price change hands back the cart with the new prices',
      setUp: () => when(() => checkout.execute(any(), any())).thenThrow(
        CheckoutConflict(failure: PricesChangedFailure(), cart: cart),
      ),
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.review),
      act: (bloc) => bloc.add(ConfirmCheckoutEvent()),
      skip: 1,
      expect: () => [
        isA<CheckoutState>()
            .having((s) => s.conflictCart, 'conflictCart', cart)
            .having((s) => s.failure, 'failure', isA<PricesChangedFailure>())
            .having((s) => s.result, 'result', isNull),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'does nothing before the summary',
      build: buildBloc,
      seed: () => ready(step: CheckoutStep.shipping),
      act: (bloc) => bloc.add(ConfirmCheckoutEvent()),
      expect: () => <CheckoutState>[],
      verify: (_) => verifyNever(() => checkout.execute(any(), any())),
    );
  });
}
