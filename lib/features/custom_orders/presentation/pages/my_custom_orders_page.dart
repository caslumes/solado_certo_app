import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_orders_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/paged_custom_order_list.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_detail_page.dart';

class MyCustomOrdersPage extends StatelessWidget {
  const MyCustomOrdersPage({super.key, this.openDetail = _openDetail});

  final Future<void> Function(
    BuildContext context,
    CustomOrderEntity request,
    ValueChanged<CustomOrderEntity> onChanged,
  )
  openDetail;

  static Future<void> _openDetail(
    BuildContext context,
    CustomOrderEntity request,
    ValueChanged<CustomOrderEntity> onChanged,
  ) => Navigator.of(
    context,
  ).push(CustomOrderDetailPage.route(request.id, onChanged: onChanged));

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CustomOrdersCubit(
          getCustomOrdersUseCase: getIt<GetCustomOrdersUseCase>(),
        )..load(),
        child: const MyCustomOrdersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          'Sob medida'.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      body: PagedCustomOrderList(
        onOpen: (request) => openDetail(
          context,
          request,
          context.read<CustomOrdersCubit>().changed,
        ),
        emptyTitle: 'Nenhuma solicitação sob medida',
        emptyMessage:
            'Nos anúncios marcados como "Sob medida", toque em "Solicitar sob '
            'medida" e informe as medidas dos seus pés.',
      ),
    );
  }
}
