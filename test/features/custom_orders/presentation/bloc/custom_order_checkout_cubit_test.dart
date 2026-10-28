import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_checkout_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetAddressesUseCase getAddresses;
  late MockGetProductDetailUseCase getProduct;
  late MockCheckoutCustomOrderUseCase checkout;

  final request = buildCustomOrder(
    status: CustomOrderStatus.approved,
    quotedPrice: 320,
  );
  final ordered = buildCustomOrderDetail(
    status: CustomOrderStatus.approved,
    quotedPrice: 320,
    orderId: 'o1',
    actions: const {},
  );

  CustomOrderCheckoutCubit buildCubit() => CustomOrderCheckoutCubit(
    getAddressesUseCase: getAddresses,
    getProductDetailUseCase: getProduct,
    checkoutUseCase: checkout,
    request: request,
    newKey: () => 'k1',
  );

  setUp(() {
    getAddresses = MockGetAddressesUseCase();
    getProduct = MockGetProductDetailUseCase();
    checkout = MockCheckoutCustomOrderUseCase();
    when(getAddresses.execute).thenAnswer(
      (_) async => [buildAddress(), buildAddress(id: 'a2', isDefault: true)],
    );
    when(
      () => getProduct.execute('603'),
    ).thenAnswer((_) async => buildProductDetail());
  });

  blocTest<CustomOrderCheckoutCubit, CustomOrderCheckoutState>(
    'starts with the default address and the only shipping option',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CustomOrderCheckoutState>().having(
        (s) => s.status,
        'status',
        CustomOrderCheckoutStatus.loading,
      ),
      isA<CustomOrderCheckoutState>()
          .having((s) => s.status, 'status', CustomOrderCheckoutStatus.ready)
          .having((s) => s.addressId, 'addressId', 'a2')
          .having((s) => s.shippingOptionId, 'shippingOptionId', '701')
          .having((s) => s.shippingOption?.price, 'shipping', 19.9),
    ],
  );

  blocTest<CustomOrderCheckoutCubit, CustomOrderCheckoutState>(
    'a removed ad shows the load error',
    setUp: () => when(
      () => getProduct.execute('603'),
    ).thenThrow(buildDioException(statusCode: 404)),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<CustomOrderCheckoutState>()
          .having(
            (s) => s.status,
            'status',
            CustomOrderCheckoutStatus.loadFailure,
          )
          .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
    ],
  );

  blocTest<CustomOrderCheckoutCubit, CustomOrderCheckoutState>(
    'confirms with the chosen address, option and one key',
    setUp: () => when(
      () => checkout.execute(
        'c1',
        addressId: 'a1',
        shippingOptionId: '701',
        idempotencyKey: 'k1',
      ),
    ).thenAnswer((_) async => ordered),
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      cubit.selectAddress('a1');
      await cubit.confirm();
    },
    skip: 3,
    expect: () => [
      isA<CustomOrderCheckoutState>().having(
        (s) => s.submitting,
        'submitting',
        true,
      ),
      isA<CustomOrderCheckoutState>().having(
        (s) => s.result?.orderId,
        'orderId',
        'o1',
      ),
    ],
  );

  blocTest<CustomOrderCheckoutCubit, CustomOrderCheckoutState>(
    'keeps the choices when the checkout fails',
    setUp: () =>
        when(
          () => checkout.execute(
            any(),
            addressId: any(named: 'addressId'),
            shippingOptionId: any(named: 'shippingOptionId'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenThrow(
          buildDioException(
            statusCode: 404,
            data: {'error': 'address not found'},
          ),
        ),
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.confirm();
    },
    skip: 3,
    expect: () => [
      isA<CustomOrderCheckoutState>()
          .having((s) => s.failure, 'failure', isA<AddressNotFoundFailure>())
          .having((s) => s.addressId, 'addressId', 'a2')
          .having((s) => s.submitting, 'submitting', false),
    ],
  );
}
