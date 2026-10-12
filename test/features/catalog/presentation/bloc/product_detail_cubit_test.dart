import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/product_detail_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetProductDetailUseCase getProductDetail;

  ProductDetailCubit buildCubit() => ProductDetailCubit(
    getProductDetailUseCase: getProductDetail,
    productId: '603',
  );

  setUp(() => getProductDetail = MockGetProductDetailUseCase());

  blocTest<ProductDetailCubit, ProductDetailState>(
    'loads the product by its id',
    setUp: () => when(
      () => getProductDetail.execute('603'),
    ).thenAnswer((_) async => buildProductDetail()),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ProductDetailLoading>(),
      isA<ProductDetailLoaded>().having(
        (state) => state.product.id,
        'product id',
        '603',
      ),
    ],
  );

  blocTest<ProductDetailCubit, ProductDetailState>(
    'maps a missing product to NotFoundFailure',
    setUp: () => when(
      () => getProductDetail.execute('603'),
    ).thenThrow(buildDioException(statusCode: 404)),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ProductDetailLoading>(),
      isA<ProductDetailLoadFailure>().having(
        (state) => state.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    ],
  );
}
