import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final GetProductDetailUseCase _getProductDetailUseCase;
  final String productId;

  ProductDetailCubit({
    required GetProductDetailUseCase getProductDetailUseCase,
    required this.productId,
  }) : _getProductDetailUseCase = getProductDetailUseCase,
       super(ProductDetailLoading());

  Future<void> load() async {
    emit(ProductDetailLoading());
    try {
      final product = await _getProductDetailUseCase.execute(productId);
      if (!isClosed) emit(ProductDetailLoaded(product: product));
    } catch (e) {
      if (!isClosed) emit(ProductDetailLoadFailure(failure: Failure.from(e)));
    }
  }
}

sealed class ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  ProductDetailLoaded({required this.product});

  final ProductDetailEntity product;
}

class ProductDetailLoadFailure extends ProductDetailState {
  ProductDetailLoadFailure({required this.failure});

  final Failure failure;
}
