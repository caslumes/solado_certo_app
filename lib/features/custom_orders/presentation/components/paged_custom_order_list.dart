import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_orders_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_status_chip.dart';

class PagedCustomOrderList extends StatefulWidget {
  const PagedCustomOrderList({
    super.key,
    required this.onOpen,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showBuyer = false,
  });

  final ValueChanged<CustomOrderEntity> onOpen;
  final String emptyTitle;
  final String emptyMessage;

  final bool showBuyer;

  @override
  State<PagedCustomOrderList> createState() => _PagedCustomOrderListState();
}

class _PagedCustomOrderListState extends State<PagedCustomOrderList> {
  static const _loadMoreExtent = 400.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _loadMoreExtent) {
      context.read<CustomOrdersCubit>().loadMore();
    }
  }

  void _checkFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _onScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomOrdersCubit, CustomOrdersState>(
      listenWhen: (previous, current) =>
          current.failure != null ||
          (current.status == CustomOrdersStatus.loaded &&
              current.requests.length != previous.requests.length),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return _checkFill();
        if (failure is UnauthorizedFailure) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.read<AuthBloc>().add(SignOutEvent());
          return;
        }
        if (state.status != CustomOrdersStatus.loaded) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      },
      builder: (context, state) => switch (state.status) {
        CustomOrdersStatus.loaded when state.requests.isEmpty => _NoRequests(
          title: widget.emptyTitle,
          message: widget.emptyMessage,
        ),
        CustomOrdersStatus.loaded => RefreshIndicator(
          onRefresh: context.read<CustomOrdersCubit>().load,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.requests.length + (state.loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == state.requests.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final request = state.requests[index];
              return CustomOrderTile(
                key: ValueKey(request.id),
                request: request,
                showBuyer: widget.showBuyer,
                onTap: () => widget.onOpen(request),
              );
            },
          ),
        ),
        CustomOrdersStatus.failure => _LoadError(failure: state.failure!),
        CustomOrdersStatus.loading || CustomOrdersStatus.initial =>
          const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class CustomOrderTile extends StatelessWidget {
  const CustomOrderTile({
    super.key,
    required this.request,
    required this.onTap,
    this.showBuyer = false,
  });

  final CustomOrderEntity request;
  final VoidCallback onTap;
  final bool showBuyer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final who = showBuyer ? request.buyerName : request.sellerName;
    final price = request.quotedPrice;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.0,
          children: [
            SizedBox.square(
              dimension: 64,
              child: ProductImage(url: request.coverUrl),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  Text(
                    request.advertisementTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  Text(
                    '$who · atualizada em ${formatDate(request.updatedAt)}',
                    style: textTheme.bodySmall,
                  ),
                  CustomOrderStatusChip(status: request.status),
                ],
              ),
            ),
            if (price != null)
              Text(formatCurrency(price), style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _NoRequests extends StatelessWidget {
  const _NoRequests({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: context.read<CustomOrdersCubit>().load,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          const Icon(
            Icons.straighten,
            size: 48,
            color: AppColors.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            message,
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
              onPressed: context.read<CustomOrdersCubit>().load,
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
