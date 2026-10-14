/// The steps of the ad form (UC-003), each with the backend fields it shows,
/// so a field reported as missing can take the seller to its step.
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

  /// The step of the first field in [fields] (the backend lists them in form
  /// order), or [review] when none is known.
  static AdFormStep firstWith(Iterable<String> fields) {
    for (final step in values) {
      if (fields.any(step.fields.contains)) return step;
    }
    return review;
  }

  /// Photos are uploaded to an existing ad, so a new ad is saved as a draft
  /// before the seller reaches this step.
  bool get needsSavedAd => index >= photos.index;
}
