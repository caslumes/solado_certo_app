enum AccountStatus {
  active('active', 'Ativa'),
  pending('pending', 'Cadastro incompleto'),
  inactive('inactive', 'Excluída'),
  blocked('blocked', 'Bloqueada'),
  suspended('suspended', 'Suspensa');

  const AccountStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isRestricted => this == blocked || this == suspended;

  static AccountStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw ArgumentError.value(value, 'status'),
  );
}

enum UserModerationAction {
  block('block', 'Bloquear', 'Conta bloqueada.'),
  suspend('suspend', 'Suspender', 'Conta suspensa.'),
  reactivate('reactivate', 'Reativar', 'Conta reativada.');

  const UserModerationAction(this.apiValue, this.label, this.notice);

  final String apiValue;
  final String label;
  final String notice;

  static List<UserModerationAction> availableFor(AccountStatus status) =>
      switch (status) {
        AccountStatus.active || AccountStatus.pending => [block, suspend],
        AccountStatus.suspended => [block, reactivate],
        AccountStatus.blocked => [reactivate],
        AccountStatus.inactive => [],
      };
}
