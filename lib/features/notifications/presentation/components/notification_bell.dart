import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:solado_certo_app/features/notifications/presentation/pages/notifications_page.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<NotificationsBloc, int>(
      (bloc) => bloc.state.unreadCount,
    );

    return IconButton(
      tooltip: count == 0 ? 'Notificações' : 'Notificações ($count não lidas)',
      onPressed: () {
        final bloc = context.read<NotificationsBloc>()
          ..add(LoadNotificationsEvent());
        Navigator.of(context).push(NotificationsPage.route(bloc));
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(
          count > 0 ? Icons.notifications : Icons.notifications_none,
          size: 32,
        ),
      ),
    );
  }
}
