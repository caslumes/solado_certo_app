import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/core/presentation/components/reason_dialog.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

typedef AdminAdsCubit = PagedListCubit<AdminAdEntity, AdminAdFilter>;
typedef AdminAdsState = PagedListState<AdminAdEntity, AdminAdFilter>;

class AdminAdsPage extends StatelessWidget {
  const AdminAdsPage({super.key, required this.takeDownAdUseCase});

  final TakeDownAdUseCase takeDownAdUseCase;

  static Route<void> route() {
    final getAds = getIt<GetAdminAdsUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdminAdsCubit(
          loader: (filter, page) async =>
              pageResult(await getAds.execute(filter, page)),
          filter: const AdminAdFilter(),
        )..load(),
        child: AdminAdsPage(takeDownAdUseCase: getIt<TakeDownAdUseCase>()),
      ),
    );
  }

  static const _statusOptions = <(AdStatus?, String)>[
    (null, 'Todos'),
    (AdStatus.published, 'Publicados'),
    (AdStatus.paused, 'Pausados'),
    (AdStatus.draft, 'Rascunhos'),
    (AdStatus.archived, 'Arquivados'),
    (AdStatus.removed, 'Removidos'),
  ];

  Future<void> _remove(BuildContext context, AdminAdEntity ad) async {
    final cubit = context.read<AdminAdsCubit>();
    final reason = await ReasonDialog.show(
      context,
      title: 'Remover "${ad.title}"?',
      message:
          'O anúncio sai do catálogo e o vendedor é avisado com o motivo, '
          'que também fica registrado na auditoria.',
      confirmText: 'Remover',
    );
    if (reason == null || !context.mounted) return;
    final done = await cubit.change(
      () => takeDownAdUseCase.execute(ad.id, reason),
      (item) => item.id == ad.id,
    );
    if (done && context.mounted) showAdminNotice(context, 'Anúncio removido.');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminAdsCubit>();

    return AdminScaffold(
      title: 'Anúncios',
      body: AdminListView<AdminAdEntity, AdminAdFilter>(
        header: BlocBuilder<AdminAdsCubit, AdminAdsState>(
          buildWhen: (previous, current) => previous.filter != current.filter,
          builder: (context, state) {
            final filter = state.filter;
            return Column(
              children: [
                AdminSearchField(
                  hintText: 'Título do anúncio',
                  initialValue: filter.search,
                  onSubmitted: (search) => cubit.applyFilter(
                    AdminAdFilter(search: search, status: filter.status),
                  ),
                ),
                AdminFilterChips<AdStatus?>(
                  options: _statusOptions,
                  selected: filter.status,
                  onSelected: (status) => cubit.applyFilter(
                    AdminAdFilter(search: filter.search, status: status),
                  ),
                ),
              ],
            );
          },
        ),
        emptyText: 'Nenhum anúncio encontrado.',
        itemBuilder: (context, ad) {
          final busy = context.select<AdminAdsCubit, bool>(
            (cubit) => cubit.state.busy,
          );
          return AdminTile(
            key: ValueKey(ad.id),
            title: ad.title,
            tags: [
              AdminTag(
                label: ad.status.label,
                highlight: ad.status == AdStatus.removed,
              ),
            ],
            lines: [
              'Vendedor: ${ad.sellerName}',
              '${formatCurrency(ad.price)} · ${ad.stock} em estoque',
            ],
            footnote: switch (ad.removedAt) {
              final removedAt? => 'Removido em ${formatDateTime(removedAt)}',
              null => 'Criado em ${formatDate(ad.createdAt)}',
            },
            trailing: ad.status == AdStatus.removed
                ? null
                : IconButton(
                    tooltip: 'Remover anúncio',
                    onPressed: busy ? null : () => _remove(context, ad),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
          );
        },
      ),
    );
  }
}
