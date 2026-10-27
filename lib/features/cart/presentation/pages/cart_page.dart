import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/cart/presentation/components/cart_item_tile.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key, this.onCheckout});

  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          current is CartLoaded &&
          (current.failure != null || current.notice != null),
      listener: (context, state) {
        state as CartLoaded;
        final failure = state.failure;
        if (failure is UnauthorizedFailure) {
          context.read<AuthBloc>().add(SignOutEvent());
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure?.message ?? state.notice!)),
          );
      },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Carrinho'.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        body: switch (state) {
          CartLoaded(:final cart) when cart.isEmpty => const _EmptyCart(),
          CartLoaded() => _CartContent(state: state),
          CartLoadFailure(:final failure) => _LoadError(failure: failure),
          CartLoading() => const Center(child: CircularProgressIndicator()),
          CartInactive() => const SizedBox.shrink(),
        },
        bottomNavigationBar: state is CartLoaded && !state.cart.isEmpty
            ? _Summary(cart: state.cart, onCheckout: onCheckout)
            : null,
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.state});

  final CartLoaded state;

  @override
  Widget build(BuildContext context) {
    final cart = state.cart;
    final bloc = context.read<CartBloc>();
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(LoadCartEvent());
        await bloc.stream.firstWhere((s) => s is! CartLoading);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (cart.hasProblems)
            const _Warning(
              text:
                  'Alguns itens estão indisponíveis ou sem estoque suficiente. '
                  'Diminua a quantidade ou remova-os para continuar.',
            ),
          if (cart.hasPriceChanges)
            const _Warning(
              text: 'Alguns preços mudaram desde que você adicionou os itens.',
            ),
          for (final group in cart.groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Vendido por ${group.sellerName}',
                style: textTheme.bodyMedium,
              ),
            ),
            for (final item in group.items)
              CartItemTile(
                key: ValueKey(item.advertisementId),
                item: item,
                busy: state.busyItemId == item.advertisementId,
                enabled: state.busyItemId == null,
                onQuantityChanged: (quantity) => bloc.add(
                  ChangeCartItemQuantityEvent(
                    advertisementId: item.advertisementId,
                    quantity: quantity,
                  ),
                ),
                onRemove: () => bloc.add(
                  RemoveCartItemEvent(advertisementId: item.advertisementId),
                ),
                onOpen: () => Navigator.of(
                  context,
                ).push(ProductDetailPage.route(item.advertisementId)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal do vendedor', style: textTheme.bodySmall),
                  Text(
                    formatCurrency(group.subtotal),
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart, required this.onCheckout});

  final CartEntity cart;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = cart.itemCount == 1 ? '1 item' : '${cart.itemCount} itens';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.0,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal ($units)', style: textTheme.bodyLarge),
                Text(
                  formatCurrency(cart.subtotal),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            Text(
              'O frete é escolhido no checkout.',
              style: textTheme.bodySmall,
            ),
            ShoeTextButton(
              onPressed: cart.hasProblems || cart.itemCount == 0
                  ? null
                  : onCheckout,
              text: 'Continuar',
            ),
          ],
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      color: AppColors.warningBackgroundColor,
      child: Row(
        spacing: 8.0,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warningColor),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warningColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async => context.read<CartBloc>().add(LoadCartEvent()),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          const Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: AppColors.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Seu carrinho está vazio',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Os produtos que você adicionar aparecem aqui.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
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
              onPressed: () => context.read<CartBloc>().add(LoadCartEvent()),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
