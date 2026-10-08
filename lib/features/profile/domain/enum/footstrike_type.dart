enum FootstrikeType {
  neutral('Neutra'),
  pronated('Pronada (pé gira para dentro)'),
  supinated('Supinada (pé gira para fora)'),
  unknown('Não sei');

  const FootstrikeType(this.label);

  final String label;

  static FootstrikeType? fromApi(String? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }

  String toApi() => name;
}
