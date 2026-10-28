import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';
import 'package:solado_certo_app/features/checkout/presentation/components/checkout_steps.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_checkout_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/components/amount_row.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/add_address_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/address_form_page.dart';

class CustomOrderCheckoutPage extends StatelessWidget {
  const CustomOrderCheckoutPage({
    super.key,
    required this.addAddress,
    this.openOrder = _openOrder,
  });

  final Future<AddressEntity> Function(NewAddress address) addAddress;
  final void Function(BuildContext context, String orderId) openOrder;

  static void _openOrder(BuildContext context, String orderId) =>
      Navigator.of(context).pushReplacement(OrderDetailPage.route(orderId));

  static Route<void> route(CustomOrderEntity request) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CustomOrderCheckoutCubit(
          getAddressesUseCase: getIt<GetAddressesUseCase>(),
          getProductDetailUseCase: getIt<GetProductDetailUseCase>(),
          checkoutUseCase: getIt<CheckoutCustomOrderUseCase>(),
          request: request,
        )..load(),
        child: CustomOrderCheckoutPage(
          addAddress: getIt<AddAddressUseCase>().execute,
        ),
      ),
    );
  }

  Future<void> _openAddressForm(BuildContext context) async {
    final cubit = context.read<CustomOrderCheckoutCubit>();
    AddressEntity? added;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          initialIsDefault: cubit.state.addresses.isEmpty,
          onSubmit: (address) async => added = await addAddress(address),
        ),
      ),
    );
    if (added case final address?) cubit.addressAdded(address);
  }

  void _onStateChanged(BuildContext context, CustomOrderCheckoutState state) {
    if (state.failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (state.result?.orderId case final orderId?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Pedido criado. Agora é só pagar.')),
        );
      openOrder(context, orderId);
      return;
    }
    if (state.status == CustomOrderCheckoutStatus.loadFailure) return;
    if (state.failure case final failure?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<CustomOrderCheckoutCubit, CustomOrderCheckoutState>(
      listenWhen: (_, current) =>
          current.failure != null || current.result != null,
      listener: _onStateChanged,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text(
            'Confirmar sob medida'.toUpperCase(),
            style: textTheme.bodyMedium,
          ),
        ),
        body: switch (state.status) {
          CustomOrderCheckoutStatus.ready => _Choices(
            state: state,
            request: context.read<CustomOrderCheckoutCubit>().request,
            onAddAddress: state.submitting
                ? null
                : () => _openAddressForm(context),
          ),
          CustomOrderCheckoutStatus.loadFailure => _LoadError(
            failure: state.failure!,
          ),
          CustomOrderCheckoutStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: state.status == CustomOrderCheckoutStatus.ready
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ShoeTextButton(
                    onPressed: state.canConfirm && state.result == null
                        ? context.read<CustomOrderCheckoutCubit>().confirm
                        : null,
                    isLoading: state.submitting,
                    text: 'Confirmar pedido',
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.state,
    required this.request,
    required this.onAddAddress,
  });

  final CustomOrderCheckoutState state;
  final CustomOrderEntity request;
  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<CustomOrderCheckoutCubit>();
    final price = request.quotedPrice ?? 0;
    final shipping = state.shippingOption?.price;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4.0,
            children: [
              Text(request.advertisementTitle, style: textTheme.bodyMedium),
              Text(
                'Sob medida · vendido por ${request.sellerName}',
                style: textTheme.bodySmall,
              ),
              Text(
                'Feito sob encomenda: depois do pagamento o vendedor produz o '
                'item e o envia com o laudo e as instruções de adaptação.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            state.addresses.isEmpty
                ? 'Cadastre um endereço para receber o pedido.'
                : 'Onde você quer receber?',
            style: textTheme.bodyMedium,
          ),
        ),
        for (final address in state.addresses)
          CheckoutChoiceTile(
            key: ValueKey(address.id),
            selected: address.id == state.addressId,
            title: address.label ?? address.receiver,
            subtitle: formatAddress(address),
            onTap: state.submitting
                ? null
                : () => cubit.selectAddress(address.id),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(Icons.add),
              label: Text('Adicionar endereço'.toUpperCase()),
            ),
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            state.shippingOptions.isEmpty
                ? 'O vendedor não tem opções de envio ativas neste anúncio.'
                : 'Como você quer receber?',
            style: textTheme.bodyMedium,
          ),
        ),
        for (final option in state.shippingOptions)
          CheckoutChoiceTile(
            key: ValueKey(option.id),
            selected: option.id == state.shippingOptionId,
            title: shippingOptionName(option),
            subtitle: deliveryTime(option.deliveryDays),
            trailing: formatCurrency(option.price),
            onTap: state.submitting
                ? null
                : () => cubit.selectShippingOption(option.id),
          ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AmountRow(label: 'Preço combinado', value: price),
              if (shipping != null) ...[
                AmountRow(label: 'Frete', value: shipping),
                const Divider(),
                AmountRow(
                  label: 'Total',
                  value: price + shipping,
                  emphasized: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              failure is NotFoundFailure
                  ? 'O anúncio deste item não está mais disponível.'
                  : failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: () => context.read<CustomOrderCheckoutCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
