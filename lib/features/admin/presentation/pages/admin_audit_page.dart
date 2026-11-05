import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/enum/audit_action.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';

typedef AuditLogsCubit = PagedListCubit<AuditLogEntity, AuditLogFilter>;
typedef AuditLogsState = PagedListState<AuditLogEntity, AuditLogFilter>;

class AdminAuditPage extends StatelessWidget {
  const AdminAuditPage({super.key});

  static Route<void> route() {
    final getLogs = getIt<GetAuditLogsUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AuditLogsCubit(
          loader: (filter, page) async =>
              pageResult(await getLogs.execute(filter, page)),
          filter: const AuditLogFilter(),
        )..load(),
        child: const AdminAuditPage(),
      ),
    );
  }

  static const _contextLabels = {
    'reason': 'Motivo',
    'resolution': 'Decisão',
    'previous_status': 'Situação anterior',
    'status': 'Nova situação',
    'until': 'Até',
    'from': 'De',
    'to': 'Para',
  };

  static String _contextValue(Object? value) => switch (value) {
    final String text => switch (DateTime.tryParse(text)) {
      final date? when text.contains('T') => formatDateTime(date),
      _ => text,
    },
    final Map<dynamic, dynamic> map =>
      map.entries
          .map((entry) => '${entry.key}: ${_contextValue(entry.value)}')
          .join(', '),
    final List<dynamic> list => list.map(_contextValue).join(', '),
    _ => '$value',
  };

  static List<String> contextLines(Map<String, dynamic> context) => [
    for (final MapEntry(:key, :value) in context.entries)
      if (value != null)
        '${_contextLabels[key] ?? key}: ${_contextValue(value)}',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuditLogsCubit>();

    return AdminScaffold(
      title: 'Auditoria',
      body: AdminListView<AuditLogEntity, AuditLogFilter>(
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BlocBuilder<AuditLogsCubit, AuditLogsState>(
            buildWhen: (previous, current) => previous.filter != current.filter,
            builder: (context, state) => AdminFilterChips<AuditArea>(
              options: [
                for (final area in AuditArea.values) (area, area.label),
              ],
              selected: state.filter.area,
              onSelected: (area) =>
                  cubit.applyFilter(AuditLogFilter(area: area)),
            ),
          ),
        ),
        emptyText: 'Nenhum registro encontrado.',
        itemBuilder: (context, log) => AdminTile(
          key: ValueKey(log.id),
          title: log.actionLabel,
          lines: [
            'Por: ${log.userName ?? 'Sistema'}',
            '${log.entity} ${log.entityId}',
            ...contextLines(log.context),
          ],
          footnote: formatDateTime(log.createdAt),
        ),
      ),
    );
  }
}
