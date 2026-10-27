enum AdStatus {
  draft('Rascunho'),
  published('Publicado'),
  paused('Pausado'),
  removed('Removido');

  const AdStatus(this.label);

  final String label;

  static AdStatus fromApi(String value) =>
      values.firstWhere((status) => status.name == value);
}

enum AdStatusAction {
  publish(AdStatus.draft, 'Publicar', 'Anúncio publicado.'),
  pause(AdStatus.published, 'Pausar', 'Anúncio pausado.'),
  reactivate(AdStatus.paused, 'Reativar', 'Anúncio reativado.');

  const AdStatusAction(this.from, this.label, this.notice);

  final AdStatus from;
  final String label;
  final String notice;

  static AdStatusAction? availableFor(AdStatus status) {
    for (final action in values) {
      if (action.from == status) return action;
    }
    return null;
  }
}
