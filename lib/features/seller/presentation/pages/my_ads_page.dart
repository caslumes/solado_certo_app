import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_field.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_my_ads_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/remove_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/my_ads_bloc.dart';
import 'package:solado_certo_app/features/seller/presentation/components/seller_ad_tile.dart';
import 'package:solado_certo_app/features/seller/presentation/pages/ad_form_page.dart';

const _tabs = [
  (AdStatus.published, 'Publicados', 'Nenhum anúncio publicado.'),
  (AdStatus.draft, 'Rascunhos', 'Nenhum rascunho.'),
  (AdStatus.paused, 'Pausados', 'Nenhum anúncio pausado.'),
];

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key, this.openForm});

  final Future<void> Function(BuildContext context, String? adId)? openForm;

  static Future<void> _openForm(BuildContext context, String? adId) =>
      Navigator.of(context).push(AdFormPage.route(adId: adId));

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => MyAdsBloc(
          getMyAdsUseCase: getIt<GetMyAdsUseCase>(),
          changeAdStatusUseCase: getIt<ChangeAdStatusUseCase>(),
          removeAdUseCase: getIt<RemoveAdUseCase>(),
        )..add(LoadMyAdsEvent()),
        child: const MyAdsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: _tabs.length,
      child: BlocConsumer<MyAdsBloc, MyAdsState>(
        listenWhen: (previous, current) =>
            current is MyAdsLoaded &&
            (current.failure != null || current.notice != null),
        listener: (context, state) {
          state as MyAdsLoaded;
          final failure = state.failure;
          if (failure is UnauthorizedFailure) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<AuthBloc>().add(SignOutEvent());
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  failure == null ? state.notice! : _failureMessage(failure),
                ),
              ),
            );
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              'Meus anúncios'.toUpperCase(),
              style: textTheme.bodyMedium,
            ),
            bottom: TabBar(
              tabs: [
                for (final (status, label, _) in _tabs)
                  Tab(
                    text: state is MyAdsLoaded
                        ? '$label (${state.withStatus(status).length})'
                        : label,
                  ),
              ],
            ),
          ),
          body: switch (state) {
            MyAdsLoaded() => TabBarView(
              children: [
                for (final (status, _, emptyText) in _tabs)
                  _AdList(
                    state: state,
                    ads: state.withStatus(status),
                    emptyText: emptyText,
                    onEdit: (adId) => _edit(context, adId),
                  ),
              ],
            ),
            MyAdsLoadFailure(:final failure) => _LoadError(failure: failure),
            MyAdsLoading() => const Center(child: CircularProgressIndicator()),
          },
          floatingActionButton: state is MyAdsLoaded
              ? FloatingActionButton.extended(
                  onPressed: () => _edit(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo anúncio'),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, String? adId) async {
    final bloc = context.read<MyAdsBloc>();
    await (openForm ?? _openForm)(context, adId);
    if (!bloc.isClosed) bloc.add(LoadMyAdsEvent());
  }

  static String _failureMessage(Failure failure) => switch (failure) {
    MissingFieldsFailure(:final fields) when fields.isNotEmpty =>
      '${failure.message} Falta: ${fields.map(adFieldLabel).join(', ')}.',
    _ => failure.message,
  };
}

class _AdList extends StatelessWidget {
  const _AdList({
    required this.state,
    required this.ads,
    required this.emptyText,
    required this.onEdit,
  });

  final MyAdsLoaded state;
  final List<SellerAdEntity> ads;
  final String emptyText;
  final ValueChanged<String> onEdit;

  Future<void> _confirmRemove(BuildContext context, SellerAdEntity ad) async {
    final bloc = context.read<MyAdsBloc>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover anúncio?', style: textTheme.bodyMedium),
        content: Text(
          '"${ad.title}" sai do catálogo e da sua lista. '
          'Esta ação não pode ser desfeita.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: textTheme.bodySmall),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remover',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(RemoveAdEvent(adId: ad.id));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyAdsBloc>();

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(LoadMyAdsEvent());
        await bloc.stream.firstWhere((state) => state is! MyAdsLoading);
      },
      child: ads.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            )
          : ListView.separated(
              itemCount: ads.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return SellerAdTile(
                  key: ValueKey(ad.id),
                  ad: ad,
                  isBusy: state.busyAdId == ad.id,
                  isEnabled: state.busyAdId == null,
                  onEdit: () => onEdit(ad.id),
                  onChangeStatus: (action) => bloc.add(
                    ChangeAdStatusEvent(adId: ad.id, action: action),
                  ),
                  onRemove: () => _confirmRemove(context, ad),
                );
              },
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
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
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
              onPressed: () => context.read<MyAdsBloc>().add(LoadMyAdsEvent()),
              text: 'Tentar novamente',
              textStyle: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
