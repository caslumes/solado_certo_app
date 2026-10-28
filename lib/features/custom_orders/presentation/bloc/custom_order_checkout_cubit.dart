import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/network/idempotency_key.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';

class CustomOrderCheckoutCubit extends Cubit<CustomOrderCheckoutState> {
  final GetAddressesUseCase _getAddressesUseCase;
  final GetProductDetailUseCase _getProductDetailUseCase;
  final CheckoutCustomOrderUseCase _checkoutUseCase;
  final CustomOrderEntity request;
  final String _idempotencyKey;

  CustomOrderCheckoutCubit({
    required GetAddressesUseCase getAddressesUseCase,
    required GetProductDetailUseCase getProductDetailUseCase,
    required CheckoutCustomOrderUseCase checkoutUseCase,
    required this.request,
    String Function() newKey = newIdempotencyKey,
  }) : _getAddressesUseCase = getAddressesUseCase,
       _getProductDetailUseCase = getProductDetailUseCase,
       _checkoutUseCase = checkoutUseCase,
       _idempotencyKey = newKey(),
       super(const CustomOrderCheckoutState());

  Future<void> load() async {
    emit(const CustomOrderCheckoutState());
    try {
      final addresses = await _getAddressesUseCase.execute();
      final product = await _getProductDetailUseCase.execute(
        request.advertisementId,
      );
      if (isClosed) return;
      final options = product.shippingOptions;
      emit(
        CustomOrderCheckoutState(
          status: CustomOrderCheckoutStatus.ready,
          addresses: addresses,
          shippingOptions: options,
          addressId: _defaultAddress(addresses)?.id,
          shippingOptionId: options.length == 1 ? options.single.id : null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        CustomOrderCheckoutState(
          status: CustomOrderCheckoutStatus.loadFailure,
          failure: Failure.from(e),
        ),
      );
    }
  }

  static AddressEntity? _defaultAddress(List<AddressEntity> addresses) {
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.firstOrNull;
  }

  void selectAddress(String id) => emit(state.copyWith(addressId: id));

  void selectShippingOption(String id) =>
      emit(state.copyWith(shippingOptionId: id));

  void addressAdded(AddressEntity address) => emit(
    state.copyWith(
      addresses: [...state.addresses, address],
      addressId: address.id,
    ),
  );

  Future<void> confirm() async {
    final addressId = state.addressId;
    final shippingOptionId = state.shippingOptionId;
    if (state.submitting || addressId == null || shippingOptionId == null) {
      return;
    }

    emit(state.copyWith(submitting: true));
    try {
      final detail = await _checkoutUseCase.execute(
        request.id,
        addressId: addressId,
        shippingOptionId: shippingOptionId,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(state.copyWith(result: detail));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(failure: Failure.from(e)));
    }
  }
}

enum CustomOrderCheckoutStatus { loading, ready, loadFailure }

class CustomOrderCheckoutState {
  final CustomOrderCheckoutStatus status;
  final List<AddressEntity> addresses;
  final List<ShippingOptionEntity> shippingOptions;
  final String? addressId;
  final String? shippingOptionId;
  final bool submitting;
  final Failure? failure;
  final CustomOrderDetailEntity? result;

  const CustomOrderCheckoutState({
    this.status = CustomOrderCheckoutStatus.loading,
    this.addresses = const [],
    this.shippingOptions = const [],
    this.addressId,
    this.shippingOptionId,
    this.submitting = false,
    this.failure,
    this.result,
  });

  ShippingOptionEntity? get shippingOption {
    for (final option in shippingOptions) {
      if (option.id == shippingOptionId) return option;
    }
    return null;
  }

  bool get canConfirm =>
      addressId != null && shippingOptionId != null && !submitting;

  CustomOrderCheckoutState copyWith({
    List<AddressEntity>? addresses,
    String? addressId,
    String? shippingOptionId,
    bool submitting = false,
    Failure? failure,
    CustomOrderDetailEntity? result,
  }) => CustomOrderCheckoutState(
    status: status,
    addresses: addresses ?? this.addresses,
    shippingOptions: shippingOptions,
    addressId: addressId ?? this.addressId,
    shippingOptionId: shippingOptionId ?? this.shippingOptionId,
    submitting: submitting,
    failure: failure,
    result: result,
  );
}
