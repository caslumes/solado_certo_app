import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/usecases/cart_use_cases.dart';

class AddToCartCubit extends Cubit<AddToCartState> {
  final AddToCartUseCase _addToCartUseCase;

  AddToCartCubit({required AddToCartUseCase addToCartUseCase})
    : _addToCartUseCase = addToCartUseCase,
      super(AddToCartIdle());

  Future<void> add(String advertisementId, int quantity) async {
    if (state is AddToCartInProgress) return;
    emit(AddToCartInProgress());
    try {
      final cart = await _addToCartUseCase.execute(advertisementId, quantity);
      emit(AddToCartSuccess(cart: cart));
    } catch (e) {
      emit(AddToCartFailure(failure: Failure.from(e)));
    }
  }
}

sealed class AddToCartState {}

class AddToCartIdle extends AddToCartState {}

class AddToCartInProgress extends AddToCartState {}

class AddToCartSuccess extends AddToCartState {
  final CartEntity cart;

  AddToCartSuccess({required this.cart});
}

class AddToCartFailure extends AddToCartState {
  final Failure failure;

  AddToCartFailure({required this.failure});
}
