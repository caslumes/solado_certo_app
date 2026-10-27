import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_order_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.routeFor = defaultRouteFor});

  final Route<void>? Function(NotificationEntity notification) routeFor;

  static Route<void>? defaultRouteFor(NotificationEntity notification) {
    final orderId = notification.orderId;
    if (orderId == null) return null;
    return notification.type.forSeller
        ? SellerOrderDetailPage.route(orderId)
        : OrderDetailPage.route(orderId);
  }

  static Route<void> route(NotificationsBloc bloc) {
    return MaterialPageRoute(
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const NotificationsPage()),
    );
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
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
      context.read<NotificationsBloc>().add(LoadMoreNotificationsEvent());
    }
  }

  void _checkFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _onScroll();
    });
  }

  void _open(NotificationEntity notification) {
    context.read<NotificationsBloc>().add(
      MarkNotificationReadEvent(id: notification.id),
    );
    final route = widget.routeFor(notification);
    if (route != null) Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (previous, current) =>
          current.failure != null ||
          (current.status == NotificationsStatus.loaded &&
              current.notifications.length != previous.notifications.length),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return _checkFill();
        if (failure is UnauthorizedFailure) {
          context.read<AuthBloc>().add(SignOutEvent());
          return;
        }
        if (state.status != NotificationsStatus.loaded) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Notificações'.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            if (state.unreadCount > 0)
              IconButton(
                tooltip: 'Marcar todas como lidas',
                onPressed: () => context.read<NotificationsBloc>().add(
                  MarkAllNotificationsReadEvent(),
                ),
                icon: const Icon(Icons.done_all),
              ),
          ],
        ),
        body: switch (state.status) {
          NotificationsStatus.loaded when state.notifications.isEmpty =>
            const _NoNotifications(),
          NotificationsStatus.loaded => _NotificationList(
            state: state,
            controller: _scrollController,
            onOpen: _open,
          ),
          NotificationsStatus.failure => _LoadError(failure: state.failure!),
          NotificationsStatus.loading || NotificationsStatus.initial =>
            const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

Future<void> _refresh(BuildContext context) async {
  final bloc = context.read<NotificationsBloc>();
  bloc.add(LoadNotificationsEvent());
  await bloc.stream.firstWhere((s) => s.status != NotificationsStatus.loading);
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.state,
    required this.controller,
    required this.onOpen,
  });

  final NotificationsState state;
  final ScrollController controller;
  final ValueChanged<NotificationEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.notifications.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = state.notifications[index];
          return NotificationTile(
            key: ValueKey(notification.id),
            notification: notification,
            onTap: () => onOpen(notification),
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  static IconData _icon(NotificationType type) => switch (type) {
    NotificationType.orderPaid => Icons.payments_outlined,
    NotificationType.orderCancelled => Icons.cancel_outlined,
    NotificationType.orderDelivered => Icons.inventory_2_outlined,
    NotificationType.orderProcessing => Icons.pending_actions_outlined,
    NotificationType.orderShipped => Icons.local_shipping_outlined,
    NotificationType.orderRefunded => Icons.currency_exchange,
    NotificationType.deliveryDeadline => Icons.event_available_outlined,
    NotificationType.other => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.read;

    return Semantics(
      label: unread ? 'Não lida' : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread ? AppColors.primaryColor.withValues(alpha: 0.06) : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12.0,
            children: [
              Icon(
                _icon(notification.type),
                color: unread
                    ? AppColors.primaryColor
                    : AppColors.tertiaryColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4.0,
                  children: [
                    Text(
                      notification.title,
                      style: unread
                          ? textTheme.bodySmall
                          : textTheme.bodySmall?.copyWith(
                              color: AppColors.tertiaryColor,
                            ),
                    ),
                    Text(notification.body, style: textTheme.bodyLarge),
                    Text(
                      formatDateTime(notification.createdAt),
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 12,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoNotifications extends StatelessWidget {
  const _NoNotifications();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          const Icon(
            Icons.notifications_none,
            size: 48,
            color: AppColors.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Avisamos aqui quando seus pedidos mudarem.',
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
              onPressed: () => context.read<NotificationsBloc>().add(
                LoadNotificationsEvent(),
              ),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
