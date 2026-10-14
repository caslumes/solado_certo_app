import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/network/idempotency_key.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/domain/enum/checkout_step.dart';
import 'package:solado_certo_app/features/checkout/domain/usecases/checkout_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';

/// Drives checkout (RF-014, UC-006): address, one shipping option per item,
/// the server's summary, then the orders. One idempotency key is kept for
/// the whole page, so confirming again after a lost answer doesn't create
/// the orders twice.
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final GetAddressesUseCase _getAddressesUseCase;
  final PreviewCheckoutUseCase _previewCheckoutUseCase;
  final CheckoutUseCase _checkoutUseCase;
  final String idempotencyKey;

  CheckoutBloc({
    required CartEntity cart,
    required GetAddressesUseCase getAddressesUseCase,
    required PreviewCheckoutUseCase previewCheckoutUseCase,
    required CheckoutUseCase checkoutUseCase,
    String Function() newKey = newIdempotencyKey,
  }) : _getAddressesUseCase = getAddressesUseCase,
       _previewCheckoutUseCase = previewCheckoutUseCase,
       _checkoutUseCase = checkoutUseCase,
       idempotencyKey = newKey(),
       super(CheckoutState(cart: cart, shipping: _cheapestShipping(cart))) {
    on<LoadCheckoutEvent>(_onLoad);
    on<AddressAddedEvent>(_onAddressAdded);
    on<SelectAddressEvent>(
      (event, emit) => emit(state.copyWith(addressId: event.addressId)),
    );
    on<SelectShippingEvent>(_onSelectShipping);
    on<GoToCheckoutStepEvent>(_onGoToStep);
    on<ConfirmCheckoutEvent>(_onConfirm);
  }

  /// Options come cheapest first, so each item starts with the cheapest.
  static Map<String, String> _cheapestShipping(CartEntity cart) => {
    for (final item in cart.items)
      if (item.shippingOptions.isNotEmpty)
        item.advertisementId: item.shippingOptions.first.id,
  };

  Future<void> _onLoad(
    LoadCheckoutEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    try {
      final addresses = await _getAddressesUseCase.execute();
      final preferred = addresses.where((a) => a.isDefault).firstOrNull;
      final addressId = (preferred ?? addresses.firstOrNull)?.id;
      emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          addresses: addresses,
          addressId: addressId,
          clearAddress: addressId == null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CheckoutStatus.loadFailure,
          failure: Failure.from(e),
        ),
      );
    }
  }

  void _onAddressAdded(AddressAddedEvent event, Emitter<CheckoutState> emit) {
    emit(
      state.copyWith(
        addresses: [...state.addresses, event.address],
        addressId: event.address.id,
      ),
    );
  }

  void _onSelectShipping(
    SelectShippingEvent event,
    Emitter<CheckoutState> emit,
  ) {
    emit(
      state.copyWith(
        shipping: {
          ...state.shipping,
          event.advertisementId: event.shippingOptionId,
        },
      ),
    );
  }

  /// Going back is always allowed. Going forward needs an address, then a
  /// shipping option for every item; reaching the summary asks the server.
  Future<void> _onGoToStep(
    GoToCheckoutStepEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    if (state.isBusy || event.step == state.step) return;
    if (event.step.index < state.step.index) {
      emit(state.copyWith(step: event.step));
      return;
    }
    if (state.addressId == null) {
      emit(state.copyWith(step: CheckoutStep.address));
      return;
    }
    if (event.step == CheckoutStep.shipping) {
      emit(state.copyWith(step: CheckoutStep.shipping));
      return;
    }
    if (state.itemsWithoutShipping.isNotEmpty) {
      emit(
        state.copyWith(
          step: CheckoutStep.shipping,
          failure: ShippingRequiredFailure([
            for (final item in state.itemsWithoutShipping) item.advertisementId,
          ]),
        ),
      );
      return;
    }

    emit(state.copyWith(activity: CheckoutActivity.previewing));
    try {
      final plan = await _previewCheckoutUseCase.execute(state.selection!);
      emit(state.copyWith(step: CheckoutStep.review, plan: plan));
    } catch (e) {
      emit(_failed(e));
    }
  }

  Future<void> _onConfirm(
    ConfirmCheckoutEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    final selection = state.selection;
    if (state.isBusy ||
        state.step != CheckoutStep.review ||
        selection == null) {
      return;
    }

    emit(state.copyWith(activity: CheckoutActivity.submitting));
    try {
      final result = await _checkoutUseCase.execute(selection, idempotencyKey);
      emit(state.copyWith(result: result));
    } catch (e) {
      emit(_failed(e));
    }
  }

  CheckoutState _failed(Object error) {
    if (error is CheckoutConflict) {
      return state.copyWith(conflictCart: error.cart, failure: error.failure);
    }
    final failure = Failure.from(error);
    return switch (failure) {
      AddressNotFoundFailure() => state.copyWith(
        step: CheckoutStep.address,
        addresses: [
          for (final address in state.addresses)
            if (address.id != state.addressId) address,
        ],
        clearAddress: true,
        failure: failure,
      ),
      ShippingRequiredFailure() => state.copyWith(
        step: CheckoutStep.shipping,
        failure: failure,
      ),
      _ => state.copyWith(failure: failure),
    };
  }
}

class CheckoutEvent {}

class LoadCheckoutEvent extends CheckoutEvent {}

/// An address created from checkout; it becomes the chosen one.
class AddressAddedEvent extends CheckoutEvent {
  final AddressEntity address;

  AddressAddedEvent({required this.address});
}

class SelectAddressEvent extends CheckoutEvent {
  final String addressId;

  SelectAddressEvent({required this.addressId});
}

class SelectShippingEvent extends CheckoutEvent {
  final String advertisementId;
  final String shippingOptionId;

  SelectShippingEvent({
    required this.advertisementId,
    required this.shippingOptionId,
  });
}

class GoToCheckoutStepEvent extends CheckoutEvent {
  final CheckoutStep step;

  GoToCheckoutStepEvent({required this.step});
}

class ConfirmCheckoutEvent extends CheckoutEvent {}

enum CheckoutStatus { loading, loadFailure, ready }

enum CheckoutActivity { idle, previewing, submitting }

class CheckoutState {
  final CheckoutStatus status;

  /// The cart when checkout started; the server checks it again.
  final CartEntity cart;
  final List<AddressEntity> addresses;
  final String? addressId;

  /// Shipping option ID by advertisement ID.
  final Map<String, String> shipping;
  final CheckoutStep step;
  final CheckoutActivity activity;

  /// The server's summary, shown in the last step.
  final CheckoutPlanEntity? plan;

  /// The created orders; the page then shows the confirmation.
  final CheckoutResultEntity? result;

  /// The cart after a stock, price or cart conflict; the page hands it to
  /// the cart and goes back there.
  final CartEntity? conflictCart;
  final Failure? failure;

  const CheckoutState({
    this.status = CheckoutStatus.loading,
    required this.cart,
    this.addresses = const [],
    this.addressId,
    this.shipping = const {},
    this.step = CheckoutStep.address,
    this.activity = CheckoutActivity.idle,
    this.plan,
    this.result,
    this.conflictCart,
    this.failure,
  });

  bool get isBusy => activity != CheckoutActivity.idle;

  List<CartItemEntity> get itemsWithoutShipping => [
    for (final item in cart.items)
      if (!item.shippingOptions.any(
        (option) => option.id == shipping[item.advertisementId],
      ))
        item,
  ];

  /// The shipping charged for [group]: one package per seller, so the most
  /// expensive option chosen among its items (the server applies the same
  /// rule).
  double shippingFor(CartGroupEntity group) {
    var highest = 0.0;
    for (final item in group.items) {
      for (final option in item.shippingOptions) {
        if (option.id == shipping[item.advertisementId] &&
            option.price > highest) {
          highest = option.price;
        }
      }
    }
    return highest;
  }

  CheckoutSelection? get selection {
    final addressId = this.addressId;
    if (addressId == null) return null;
    return CheckoutSelection(addressId: addressId, shipping: shipping);
  }

  /// [failure], [conflictCart] and [result] are one-shot, and [activity]
  /// goes back to idle, unless passed.
  CheckoutState copyWith({
    CheckoutStatus? status,
    List<AddressEntity>? addresses,
    String? addressId,
    bool clearAddress = false,
    Map<String, String>? shipping,
    CheckoutStep? step,
    CheckoutActivity? activity,
    CheckoutPlanEntity? plan,
    CheckoutResultEntity? result,
    CartEntity? conflictCart,
    Failure? failure,
  }) => CheckoutState(
    status: status ?? this.status,
    cart: cart,
    addresses: addresses ?? this.addresses,
    addressId: clearAddress ? null : addressId ?? this.addressId,
    shipping: shipping ?? this.shipping,
    step: step ?? this.step,
    activity: activity ?? CheckoutActivity.idle,
    plan: plan ?? this.plan,
    result: result,
    conflictCart: conflictCart,
    failure: failure,
  );
}
