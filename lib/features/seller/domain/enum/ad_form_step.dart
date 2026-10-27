enum AdFormStep {
  general('Dados gerais', {'title', 'category_id', 'description', 'price'}),
  attributes('Atributos técnicos', {
    'side',
    'size',
    'material',
    'rigidity',
    'usage_indication',
  }),
  purposes('Finalidades e segurança', {'safety_alerts', 'contraindications'}),
  photos('Fotos', {'images'}),
  shipping('Envio', {'shipping_options'}),
  review('Revisar', {});

  const AdFormStep(this.label, this.fields);

  final String label;
  final Set<String> fields;

  static AdFormStep firstWith(Iterable<String> fields) {
    for (final step in values) {
      if (fields.any(step.fields.contains)) return step;
    }
    return review;
  }

  bool get needsSavedAd => index >= photos.index;
}
