/// The values of the ad form, sent whole on every save: an empty text clears
/// the field and an empty list clears the list.
class AdDraft {
  final String title;
  final String? categoryId;
  final String description;

  /// API format (`"89.90"`), or empty when not filled.
  final String price;
  final int stock;
  final bool prescriptionRequired;
  final bool customMadeAllowed;
  final String? side;
  final String size;
  final String material;
  final String? rigidity;
  final String usageIndication;
  final String safetyAlerts;
  final String contraindications;
  final String shippingNotes;
  final List<String> purposes;
  final List<String> conditionIds;
  final List<ShippingOptionDraft> shippingOptions;

  const AdDraft({
    this.title = '',
    this.categoryId,
    this.description = '',
    this.price = '',
    this.stock = 0,
    this.prescriptionRequired = false,
    this.customMadeAllowed = false,
    this.side,
    this.size = '',
    this.material = '',
    this.rigidity,
    this.usageIndication = '',
    this.safetyAlerts = '',
    this.contraindications = '',
    this.shippingNotes = '',
    this.purposes = const [],
    this.conditionIds = const [],
    this.shippingOptions = const [],
  });
}

/// A shipping option in the form. Without [id] it is new; options left out
/// of a save are deactivated by the backend.
class ShippingOptionDraft {
  final String? id;
  final String name;
  final String carrier;

  /// API format (`"19.90"`).
  final String price;
  final int deliveryDays;

  const ShippingOptionDraft({
    this.id,
    required this.name,
    this.carrier = '',
    required this.price,
    required this.deliveryDays,
  });
}
