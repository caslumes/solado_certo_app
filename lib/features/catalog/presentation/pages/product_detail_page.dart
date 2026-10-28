import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_quantity_stepper.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/cart/domain/usecases/cart_use_cases.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/add_to_cart_cubit.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/cart/presentation/components/cart_item_tile.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_image.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/seller.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/product_attributes.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/product_detail_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_safety_section.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_request_page.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/product_reviews_cubit.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/product_reviews_section.dart';

final _rating = NumberFormat('0.0', appLocale);

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    this.requestCustomOrder = _requestCustomOrder,
  });

  final void Function(BuildContext context, ProductDetailEntity product)
  requestCustomOrder;

  static void _requestCustomOrder(
    BuildContext context,
    ProductDetailEntity product,
  ) => Navigator.of(context).push(CustomOrderRequestPage.route(product));

  static Route<void> route(String productId) {
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProductDetailCubit(
              getProductDetailUseCase: getIt<GetProductDetailUseCase>(),
              productId: productId,
            )..load(),
          ),
          BlocProvider(
            create: (_) =>
                AddToCartCubit(addToCartUseCase: getIt<AddToCartUseCase>()),
          ),
          BlocProvider(
            create: (_) => ProductReviewsCubit(
              getProductReviewsUseCase: getIt<GetProductReviewsUseCase>(),
              advertisementId: productId,
            )..load(),
          ),
        ],
        child: const ProductDetailPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryColor,
          surfaceTintColor: Colors.white,
        ),
        body: switch (state) {
          ProductDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductDetailLoadFailure(:final failure) => _LoadFailure(
            failure: failure,
          ),
          ProductDetailLoaded(:final product) => _ProductDetail(
            product: product,
          ),
        },
        bottomNavigationBar: state is ProductDetailLoaded
            ? _AddToCartBar(
                product: state.product,
                requestCustomOrder: requestCustomOrder,
              )
            : null,
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final notFound = failure is NotFoundFailure;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              notFound ? 'Produto não encontrado' : failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (notFound)
              Text(
                'Ele pode ter sido removido ou pausado pelo vendedor.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              ShoeTextButton(
                onPressed: context.read<ProductDetailCubit>().load,
                text: 'Tentar novamente',
              ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartBar extends StatefulWidget {
  const _AddToCartBar({
    required this.product,
    required this.requestCustomOrder,
  });

  final ProductDetailEntity product;
  final void Function(BuildContext context, ProductDetailEntity product)
  requestCustomOrder;

  @override
  State<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends State<_AddToCartBar> {
  int _quantity = 1;

  void _add() {
    if (context.read<CartBloc>().state is CartInactive) {
      Navigator.of(context).pushNamed(AuthRoutes.signIn);
      return;
    }
    context.read<AddToCartCubit>().add(widget.product.id, _quantity);
  }

  void _requestCustomOrder() {
    if (context.read<CartBloc>().state is CartInactive) {
      Navigator.of(context).pushNamed(AuthRoutes.signIn);
      return;
    }
    widget.requestCustomOrder(context, widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.product.stock;

    return BlocConsumer<AddToCartCubit, AddToCartState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        switch (state) {
          case AddToCartSuccess(:final cart):
            context.read<CartBloc>().add(CartUpdatedEvent(cart: cart));
            messenger.showSnackBar(
              const SnackBar(content: Text('Produto adicionado ao carrinho.')),
            );
          case AddToCartFailure(:final failure):
            messenger.showSnackBar(SnackBar(content: Text(failure.message)));
          case AddToCartIdle() || AddToCartInProgress():
        }
      },
      builder: (context, state) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.product.customMadeAllowed)
                TextButton.icon(
                  onPressed: _requestCustomOrder,
                  icon: const Icon(Icons.straighten),
                  label: const Text('Solicitar sob medida'),
                ),
              stock == 0
                  ? const ShoeTextButton(onPressed: null, text: 'Esgotado')
                  : Row(
                      spacing: 12.0,
                      children: [
                        ShoeQuantityStepper(
                          value: _quantity,
                          max: stock.clamp(1, maxCartItemQuantity),
                          onChanged: (value) =>
                              setState(() => _quantity = value),
                        ),
                        Expanded(
                          child: ShoeTextButton(
                            onPressed: _add,
                            isLoading: state is AddToCartInProgress,
                            text: 'Adicionar ao carrinho',
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    final reviews = context.read<ProductReviewsCubit>();

    return RefreshIndicator(
      onRefresh: () {
        reviews.load();
        return context.read<ProductDetailCubit>().load();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ImageCarousel(images: product.images, title: product.title),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24.0,
              children: [
                _Summary(product: product),
                if (product.description.trim().isNotEmpty)
                  _Section(
                    title: 'Descrição',
                    child: Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                _Attributes(product: product),
                ProductSafetySection(product: product),
                if (product.seller != null)
                  _Section(
                    title: 'Vendedor',
                    child: _SellerCard(seller: product.seller!),
                  ),
                _Shipping(product: product),
                const ProductReviewsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images, required this.title});

  final List<ProductImageEntity> images;
  final String title;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return const AspectRatio(aspectRatio: 1, child: ProductImage(url: null));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (_, index) => ProductImage(
              url: images[index].url,
              semanticLabel: images[index].altText.isEmpty
                  ? widget.title
                  : images[index].altText,
            ),
          ),
          if (images.length > 1)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6.0,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _current
                              ? AppColors.primaryColor
                              : Colors.white,
                          border: Border.all(color: AppColors.primaryColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detailStyle = textTheme.labelLarge?.copyWith(
      color: AppColors.tertiaryColor,
    );
    final tags = [
      for (final purpose in product.purposes) purpose.name,
      for (final condition in product.conditions) condition.name,
      if (product.customMadeAllowed) 'Sob medida',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Text(
          product.title,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          product.averageRating == null
              ? 'Sem avaliações'
              : '★ ${_rating.format(product.averageRating)} '
                    '(${product.reviewCount})',
          style: detailStyle,
        ),
        Text(formatCurrency(product.price), style: textTheme.bodyMedium),
        Text(
          product.isAvailable
              ? product.stock == 1
                    ? 'Em estoque (1 unidade)'
                    : 'Em estoque (${product.stock} unidades)'
              : 'Esgotado',
          style: textTheme.labelLarge?.copyWith(
            color: product.isAvailable
                ? AppColors.primaryColor
                : AppColors.tertiaryColor,
          ),
        ),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.secondaryColor,
                  side: BorderSide.none,
                  shape: const RoundedRectangleBorder(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8.0,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        child,
      ],
    );
  }
}

class _Attributes extends StatelessWidget {
  const _Attributes({required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final side = product.side;
    final rigidity = product.rigidity;
    final rows = <(String, String)>[
      if (side != null) ('Lado', sideLabels[side] ?? side),
      if (product.size != null) ('Tamanho', product.size!),
      if (product.material != null) ('Material', product.material!),
      if (rigidity != null) ('Rigidez', rigidityLabels[rigidity] ?? rigidity),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Características',
      child: Column(
        spacing: 4.0,
        children: [
          for (final (label, value) in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ),
                Expanded(child: Text(value, style: textTheme.bodyLarge)),
              ],
            ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});

  final SellerEntity seller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      if (seller.state != null) seller.state!,
      if (seller.averageRating != null)
        '★ ${_rating.format(seller.averageRating)} (${seller.reviewCount})',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryColor),
      ),
      child: Row(
        spacing: 12.0,
        children: [
          const Icon(Icons.storefront_outlined, size: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.0,
              children: [
                Text(
                  seller.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details.join(' · '),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                Text(
                  'No Solado Certo desde ${formatMonthYear(seller.memberSince)}',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Shipping extends StatelessWidget {
  const _Shipping({required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notes = product.shippingNotes?.trim() ?? '';

    return _Section(
      title: 'Entrega',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8.0,
        children: [
          if (product.shippingOptions.isEmpty)
            Text(
              'O vendedor ainda não cadastrou opções de envio.',
              style: textTheme.bodyLarge,
            ),
          for (final option in product.shippingOptions)
            _ShippingOptionRow(option: option),
          if (notes.isNotEmpty)
            Text(
              notes,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.tertiaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShippingOptionRow extends StatelessWidget {
  const _ShippingOptionRow({required this.option});

  final ShippingOptionEntity option;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = option.carrier == null
        ? option.name
        : '${option.name} · ${option.carrier}';
    final days = option.deliveryDays == 1
        ? 'Até 1 dia útil'
        : 'Até ${option.deliveryDays} dias úteis';

    return Row(
      spacing: 8.0,
      children: [
        const Icon(Icons.local_shipping_outlined),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: textTheme.bodyLarge),
              Text(
                days,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
        Text(formatCurrency(option.price), style: textTheme.bodySmall),
      ],
    );
  }
}
