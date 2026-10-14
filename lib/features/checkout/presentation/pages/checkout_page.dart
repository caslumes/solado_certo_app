import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/checkout/domain/enum/checkout_step.dart';
import 'package:solado_certo_app/features/checkout/domain/usecases/checkout_use_cases.dart';
import 'package:solado_certo_app/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:solado_certo_app/features/checkout/presentation/components/cart_changes.dart';
import 'package:solado_certo_app/features/checkout/presentation/components/checkout_steps.dart';
import 'package:solado_certo_app/features/checkout/presentation/pages/order_confirmation_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/add_address_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/address_form_page.dart';

/// Checkout in steps (RF-014, UC-006): endereço, frete, resumo. Ends on the
/// order confirmation; a stock or price conflict goes back to the cart.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.addAddress,
    this.onViewOrders,
    this.onKeepShopping,
  });

  final Future<AddressEntity> Function(NewAddress address) addAddress;

  /// Passed to the order confirmation.
  final VoidCallback? onViewOrders;
  final VoidCallback? onKeepShopping;

  static Route<void> route({
    required CartEntity cart,
    VoidCallback? onViewOrders,
    VoidCallback? onKeepShopping,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CheckoutBloc(
          cart: cart,
          getAddressesUseCase: getIt<GetAddressesUseCase>(),
          previewCheckoutUseCase: getIt<PreviewCheckoutUseCase>(),
          checkoutUseCase: getIt<CheckoutUseCase>(),
        )..add(LoadCheckoutEvent()),
        child: CheckoutPage(
          addAddress: getIt<AddAddressUseCase>().execute,
          onViewOrders: onViewOrders,
          onKeepShopping: onKeepShopping,
        ),
      ),
    );
  }

  Future<void> _openAddressForm(BuildContext context) async {
    final bloc = context.read<CheckoutBloc>();
    AddressEntity? added;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          initialIsDefault: bloc.state.addresses.isEmpty,
          onSubmit: (address) async => added = await addAddress(address),
        ),
      ),
    );
    if (added case final address?) {
      bloc.add(AddressAddedEvent(address: address));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (_, current) =>
          current.failure != null || current.result != null,
      listener: _onStateChanged,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text(
            'Finalizar compra'.toUpperCase(),
            style: textTheme.bodyMedium,
          ),
        ),
        body: switch (state.status) {
          CheckoutStatus.ready => _buildSteps(context, state),
          CheckoutStatus.loadFailure => _LoadError(failure: state.failure!),
          CheckoutStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: state.status == CheckoutStatus.ready
            ? _BottomBar(state: state)
            : null,
      ),
    );
  }

  Future<void> _onStateChanged(
    BuildContext context,
    CheckoutState state,
  ) async {
    final navigator = Navigator.of(context);
    final cartBloc = context.read<CartBloc>();

    if (state.result case final result?) {
      // The cart was turned into the orders, so it is empty now.
      cartBloc.add(LoadCartEvent());
      navigator.pushReplacement(
        OrderConfirmationPage.route(
          result: result,
          onViewOrders: onViewOrders,
          onKeepShopping: onKeepShopping,
        ),
      );
      return;
    }

    final failure = state.failure!;
    if (failure is UnauthorizedFailure) {
      navigator.popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }

    if (state.conflictCart case final cart?) {
      cartBloc.add(CartUpdatedEvent(cart: cart));
      await _showConflict(
        context,
        failure,
        describeCartChanges(context.read<CheckoutBloc>().state.cart, cart),
      );
      navigator.pop();
      return;
    }

    if (state.status == CheckoutStatus.loadFailure) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  /// UC-006 alternative flow: say what changed before going back to the cart.
  static Future<void> _showConflict(
    BuildContext context,
    Failure failure,
    List<String> changes,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(failure.message, style: textTheme.bodyMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.0,
          children: [
            for (final change in changes)
              Text('• $change', style: textTheme.bodySmall),
            Text(
              'Nenhum pedido foi criado. Confira o carrinho e continue.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ver carrinho'),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context, CheckoutState state) {
    final bloc = context.read<CheckoutBloc>();

    return Column(
      children: [
        _StepHeader(
          current: state.step,
          enabled: !state.isBusy,
          onSelected: (step) => bloc.add(GoToCheckoutStepEvent(step: step)),
        ),
        if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: switch (state.step) {
            CheckoutStep.address => CheckoutAddressStep(
              state: state,
              onSelect: (id) => bloc.add(SelectAddressEvent(addressId: id)),
              onAdd: state.isBusy ? null : () => _openAddressForm(context),
            ),
            CheckoutStep.shipping => CheckoutShippingStep(
              state: state,
              onSelect: (advertisementId, optionId) => bloc.add(
                SelectShippingEvent(
                  advertisementId: advertisementId,
                  shippingOptionId: optionId,
                ),
              ),
            ),
            CheckoutStep.review => CheckoutReviewStep(plan: state.plan!),
          },
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CheckoutBloc>();
    final step = state.step;
    final buttonStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(color: Colors.white);
    final canContinue = switch (step) {
      CheckoutStep.address => state.addressId != null,
      CheckoutStep.shipping => state.itemsWithoutShipping.isEmpty,
      CheckoutStep.review => true,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.0,
          children: [
            if (step.index > 0)
              ShoeTextButton(
                onPressed: state.isBusy
                    ? null
                    : () => bloc.add(
                        GoToCheckoutStepEvent(
                          step: CheckoutStep.values[step.index - 1],
                        ),
                      ),
                text: 'Voltar',
                textStyle: buttonStyle,
              ),
            step == CheckoutStep.review
                ? ShoeTextButton(
                    isLoading: state.activity == CheckoutActivity.submitting,
                    onPressed: () => bloc.add(ConfirmCheckoutEvent()),
                    text: 'Confirmar pedido',
                    textStyle: buttonStyle,
                  )
                : ShoeTextButton(
                    isLoading: state.activity == CheckoutActivity.previewing,
                    onPressed: canContinue && !state.isBusy
                        ? () => bloc.add(
                            GoToCheckoutStepEvent(
                              step: CheckoutStep.values[step.index + 1],
                            ),
                          )
                        : null,
                    text: 'Próximo',
                    textStyle: buttonStyle,
                  ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.current,
    required this.enabled,
    required this.onSelected,
  });

  final CheckoutStep current;
  final bool enabled;
  final ValueChanged<CheckoutStep> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        spacing: 8.0,
        children: [
          for (final step in CheckoutStep.values)
            ChoiceChip(
              label: Text(
                '${step.index + 1}. ${step.label}',
                style: step == current
                    ? textTheme.bodySmall?.copyWith(color: Colors.white)
                    : textTheme.bodySmall,
              ),
              showCheckmark: false,
              selectedColor: AppColors.primaryColor,
              selected: step == current,
              // Only earlier steps can be reopened from here.
              onSelected: enabled && step.index < current.index
                  ? (_) => onSelected(step)
                  : null,
            ),
        ],
      ),
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
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: () =>
                  context.read<CheckoutBloc>().add(LoadCheckoutEvent()),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
