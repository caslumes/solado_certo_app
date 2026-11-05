import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/core/presentation/components/reason_dialog.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/enum/account_status.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';

typedef AdminUsersCubit = PagedListCubit<AdminUserEntity, AdminUserFilter>;
typedef AdminUsersState = PagedListState<AdminUserEntity, AdminUserFilter>;

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({
    super.key,
    required this.moderateUseCase,
    this.pickSuspensionEnd = _pickSuspensionEnd,
  });

  final ModerateUserUseCase moderateUseCase;
  final Future<DateTime?> Function(BuildContext context) pickSuspensionEnd;

  static const maxSuspensionDays = 364;

  static Future<DateTime?> _pickSuspensionEnd(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = await showDatePicker(
      context: context,
      helpText: 'Suspender até',
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: maxSuspensionDays)),
    );
    if (day == null) return null;
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }

  static Route<void> route() {
    final getUsers = getIt<GetAdminUsersUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdminUsersCubit(
          loader: (filter, page) async =>
              pageResult(await getUsers.execute(filter, page)),
          filter: const AdminUserFilter(),
        )..load(),
        child: AdminUsersPage(moderateUseCase: getIt<ModerateUserUseCase>()),
      ),
    );
  }

  static const _statusOptions = <(AccountStatus?, String)>[
    (null, 'Todas'),
    (AccountStatus.active, 'Ativas'),
    (AccountStatus.pending, 'Incompletas'),
    (AccountStatus.suspended, 'Suspensas'),
    (AccountStatus.blocked, 'Bloqueadas'),
    (AccountStatus.inactive, 'Excluídas'),
  ];

  String _message(UserModerationAction action) => switch (action) {
    UserModerationAction.block =>
      'A pessoa não consegue mais entrar e as sessões abertas são '
          'encerradas.',
    UserModerationAction.suspend =>
      'A pessoa não consegue entrar até a data escolhida e as sessões '
          'abertas são encerradas.',
    UserModerationAction.reactivate => 'A pessoa volta a poder entrar.',
  };

  Future<void> _moderate(
    BuildContext context,
    AdminUserEntity user,
    UserModerationAction action,
  ) async {
    final cubit = context.read<AdminUsersCubit>();
    DateTime? until;
    if (action == UserModerationAction.suspend) {
      until = await pickSuspensionEnd(context);
      if (until == null || !context.mounted) return;
    }
    final reason = await ReasonDialog.show(
      context,
      title: '${action.label} ${user.name}?',
      message: [
        _message(action),
        if (until != null) 'Suspensão até ${formatDateTime(until)}.',
        'O motivo fica registrado na auditoria.',
      ].join(' '),
      confirmText: action.label,
    );
    if (reason == null || !context.mounted) return;
    final moderation = UserModeration(
      action: action,
      reason: reason,
      until: until,
    );
    final done = await cubit.change(
      () => moderateUseCase.execute(user.id, moderation),
      (item) => item.id == user.id,
    );
    if (done && context.mounted) showAdminNotice(context, action.notice);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminUsersCubit>();

    return AdminScaffold(
      title: 'Usuários',
      body: AdminListView<AdminUserEntity, AdminUserFilter>(
        header: BlocBuilder<AdminUsersCubit, AdminUsersState>(
          buildWhen: (previous, current) => previous.filter != current.filter,
          builder: (context, state) {
            final filter = state.filter;
            return Column(
              children: [
                AdminSearchField(
                  hintText: 'Nome, e-mail ou telefone',
                  initialValue: filter.search,
                  onSubmitted: (search) => cubit.applyFilter(
                    AdminUserFilter(search: search, status: filter.status),
                  ),
                ),
                AdminFilterChips<AccountStatus?>(
                  options: _statusOptions,
                  selected: filter.status,
                  onSelected: (status) => cubit.applyFilter(
                    AdminUserFilter(search: filter.search, status: status),
                  ),
                ),
              ],
            );
          },
        ),
        emptyText: 'Nenhuma conta encontrada.',
        itemBuilder: (context, user) =>
            _UserTile(key: ValueKey(user.id), user: user, onAction: _moderate),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({super.key, required this.user, required this.onAction});

  final AdminUserEntity user;
  final Future<void> Function(
    BuildContext context,
    AdminUserEntity user,
    UserModerationAction action,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final actions = user.isAdmin
        ? const <UserModerationAction>[]
        : UserModerationAction.availableFor(user.status);
    final busy = context.select<AdminUsersCubit, bool>(
      (cubit) => cubit.state.busy,
    );

    return AdminTile(
      title: user.name,
      tags: [
        AdminTag(label: user.status.label, highlight: user.status.isRestricted),
        if (user.isAdmin) const AdminTag(label: 'Administrador'),
      ],
      lines: [user.email, user.phone],
      footnote: switch (user.suspendedUntil) {
        final until? when user.status == AccountStatus.suspended =>
          'Suspensa até ${formatDateTime(until)}',
        _ => 'Cadastro em ${formatDate(user.createdAt)}',
      },
      trailing: actions.isEmpty
          ? null
          : PopupMenuButton<UserModerationAction>(
              tooltip: 'Moderar conta',
              enabled: !busy,
              onSelected: (action) => onAction(context, user, action),
              itemBuilder: (_) => [
                for (final action in actions)
                  PopupMenuItem(value: action, child: Text(action.label)),
              ],
            ),
    );
  }
}
