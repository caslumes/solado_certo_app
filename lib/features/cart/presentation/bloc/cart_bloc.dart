import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/usecases/cart_use_cases.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCartUseCase _getCartUseCase;
  final ChangeCartItemQuantityUseCase _changeCartItemQuantityUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;

  CartBloc({
    required GetCartUseCase getCartUseCase,
    required ChangeCartItemQuantityUseCase changeCartItemQuantityUseCase,
    required RemoveCartItemUseCase removeCartItemUseCase,
  }) : _getCartUseCase = getCartUseCase,
       _changeCartItemQuantityUseCase = changeCartItemQuantityUseCase,
       _removeCartItemUseCase = removeCartItemUseCase,
       super(CartInactive()) {
    on<LoadCartEvent>(_onLoad);
    on<ClearCartEvent>((_, emit) => emit(CartInactive()));
    on<CartUpdatedEvent>((event, emit) => emit(CartLoaded(cart: event.cart)));
    on<ChangeCartItemQuantityEvent>(_onChangeQuantity);
    on<RemoveCartItemEvent>(_onRemove);
  }

  Future<void> _onLoad(LoadCartEvent event, Emitter<CartState> emit) async {
    final currentState = state;
    if (currentState is! CartLoaded) emit(CartLoading());
    try {
      emit(CartLoaded(cart: await _getCartUseCase.execute()));
    } catch (e) {
      final failure = Failure.from(e);
      emit(
        currentState is CartLoaded
            ? CartLoaded(cart: currentState.cart, failure: failure)
            : CartLoadFailure(failure: failure),
      );
    }
  }

  Future<void> _onChangeQuantity(
    ChangeCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) => _act(
    emit,
    event.advertisementId,
    null,
    () => _changeCartItemQuantityUseCase.execute(
      event.advertisementId,
      event.quantity,
    ),
  );

  Future<void> _onRemove(RemoveCartItemEvent event, Emitter<CartState> emit) =>
      _act(
        emit,
        event.advertisementId,
        'Produto removido do carrinho.',
        () => _removeCartItemUseCase.execute(event.advertisementId),
      );

  Future<void> _act(
    Emitter<CartState> emit,
    String advertisementId,
    String? notice,
    Future<CartEntity> Function() action,
  ) async {
    final currentState = state;
    if (currentState is! CartLoaded || currentState.busyItemId != null) return;

    final cart = currentState.cart;
    emit(CartLoaded(cart: cart, busyItemId: advertisementId));
    try {
      emit(CartLoaded(cart: await action(), notice: notice));
    } catch (e) {
      var failure = Failure.from(e);
      if (failure is OutOfStockFailure || failure is NotFoundFailure) {
        if (failure is NotFoundFailure) failure = ProductUnavailableFailure();
        emit(CartLoaded(cart: await _reloadOr(cart), failure: failure));
        return;
      }
      emit(CartLoaded(cart: cart, failure: failure));
    }
  }

  Future<CartEntity> _reloadOr(CartEntity cart) async {
    try {
      return await _getCartUseCase.execute();
    } catch (_) {
      return cart;
    }
  }
}

class CartEvent {}

class LoadCartEvent extends CartEvent {}

class ClearCartEvent extends CartEvent {}

class CartUpdatedEvent extends CartEvent {
  final CartEntity cart;

  CartUpdatedEvent({required this.cart});
}

class ChangeCartItemQuantityEvent extends CartEvent {
  final String advertisementId;
  final int quantity;

  ChangeCartItemQuantityEvent({
    required this.advertisementId,
    required this.quantity,
  });
}

class RemoveCartItemEvent extends CartEvent {
  final String advertisementId;

  RemoveCartItemEvent({required this.advertisementId});
}

sealed class CartState {}

class CartInactive extends CartState {}

class CartLoading extends CartState {}

class CartLoadFailure extends CartState {
  final Failure failure;

  CartLoadFailure({required this.failure});
}

class CartLoaded extends CartState {
  final CartEntity cart;

  final String? busyItemId;
  final Failure? failure;
  final String? notice;

  CartLoaded({required this.cart, this.busyItemId, this.failure, this.notice});
}
