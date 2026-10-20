import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_recommended_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/recommendations_cubit.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/cart/presentation/pages/cart_page.dart';
import 'package:solado_certo_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/notifications/domain/usecases/notification_use_cases.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/my_orders_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.isSignedIn,
    this.notificationsInterval = const Duration(seconds: 60),
  });

  final bool isSignedIn;

  final Duration notificationsInterval;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _catalogIndex = 0;
  static const _cartIndex = 1;
  static const _ordersIndex = 2;

  int _selectedIndex = _catalogIndex;

  late final _recommendationsCubit = RecommendationsCubit(
    getRecommendedItemsUseCase: getIt<GetRecommendedItemsUseCase>(),
  );
  late final _ordersBloc = OrdersBloc(
    getOrdersUseCase: getIt<GetOrdersUseCase>(),
  );
  late final _notificationsBloc = NotificationsBloc(
    getNotificationsUseCase: getIt<GetNotificationsUseCase>(),
    markNotificationReadUseCase: getIt<MarkNotificationReadUseCase>(),
    markAllNotificationsReadUseCase: getIt<MarkAllNotificationsReadUseCase>(),
  );

  Timer? _notificationsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isSignedIn) {
      _recommendationsCubit.load();
      context.read<CartBloc>().add(LoadCartEvent());
      _watchNotifications();
    }
  }

  /// Checks now and then every [HomeShell.notificationsInterval].
  void _watchNotifications() {
    _notificationsTimer?.cancel();
    _notificationsBloc.add(LoadNotificationsEvent(quiet: true));
    _notificationsTimer = Timer.periodic(
      widget.notificationsInterval,
      (_) => _notificationsBloc.add(LoadNotificationsEvent(quiet: true)),
    );
  }

  void _stopWatchingNotifications() {
    _notificationsTimer?.cancel();
    _notificationsTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isSignedIn) return;
    if (state == AppLifecycleState.resumed) {
      _watchNotifications();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _stopWatchingNotifications();
    }
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSignedIn == oldWidget.isSignedIn) return;
    if (widget.isSignedIn) {
      _recommendationsCubit.load();
      context.read<CartBloc>().add(LoadCartEvent());
      _watchNotifications();
    } else {
      _recommendationsCubit.hide();
      context.read<CartBloc>().add(ClearCartEvent());
      _ordersBloc.add(ClearOrdersEvent());
      _stopWatchingNotifications();
      _notificationsBloc.add(ClearNotificationsEvent());
      setState(() => _selectedIndex = _catalogIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingNotifications();
    _recommendationsCubit.close();
    _ordersBloc.close();
    _notificationsBloc.close();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index != _catalogIndex && !widget.isSignedIn) {
      Navigator.of(context).pushNamed(AuthRoutes.signIn);
      return;
    }
    // Stock, prices and order statuses may have changed since last time.
    if (index == _cartIndex) context.read<CartBloc>().add(LoadCartEvent());
    if (index == _ordersIndex) _ordersBloc.add(LoadOrdersEvent());
    setState(() => _selectedIndex = index);
  }

  void _openCheckout() {
    final state = context.read<CartBloc>().state;
    if (state is! CartLoaded) return;
    Navigator.of(context).push(
      CheckoutPage.route(
        cart: state.cart,
        onViewOrders: () => _onDestinationSelected(_ordersIndex),
        onKeepShopping: () => setState(() => _selectedIndex = _catalogIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CatalogOptionsCubit(
            getCatalogFilterOptionsUseCase:
                getIt<GetCatalogFilterOptionsUseCase>(),
          )..load(),
        ),
        BlocProvider.value(value: _recommendationsCubit),
        BlocProvider.value(value: _ordersBloc),
        BlocProvider.value(value: _notificationsBloc),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(isSignedIn: widget.isSignedIn),
            CartPage(onCheckout: _openCheckout),
            const MyOrdersPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryColor,
          indicatorShape: const RoundedRectangleBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryColor
                  : AppColors.tertiaryColor,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(
                Icons.storefront_outlined,
                color: AppColors.tertiaryColor,
              ),
              selectedIcon: Icon(Icons.storefront, color: Colors.white),
              label: 'Catálogo',
            ),
            const NavigationDestination(
              icon: _CartIcon(
                icon: Icons.shopping_cart_outlined,
                color: AppColors.tertiaryColor,
              ),
              selectedIcon: _CartIcon(
                icon: Icons.shopping_cart,
                color: Colors.white,
              ),
              label: 'Carrinho',
            ),
            const NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.tertiaryColor,
              ),
              selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
              label: 'Pedidos',
            ),
          ],
        ),
      ),
    );
  }
}

/// The cart icon with the number of units in the cart.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartBloc, int>(
      (bloc) => switch (bloc.state) {
        CartLoaded(:final cart) => cart.unitCount,
        _ => 0,
      },
    );

    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon, color: color),
    );
  }
}
