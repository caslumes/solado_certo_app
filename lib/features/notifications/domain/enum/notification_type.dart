/// What a notification is about; the backend's `notifications.type`.
enum NotificationType {
  orderPaid(forSeller: true),
  orderCancelled(forSeller: true),
  orderDelivered(forSeller: true),
  orderProcessing(forSeller: false),
  orderShipped(forSeller: false),
  orderRefunded(forSeller: false),

  /// A type this version of the app doesn't know yet; it is still listed.
  other(forSeller: false);

  const NotificationType({required this.forSeller});

  /// Whether the order it points to is one of the user's sales, not purchases.
  final bool forSeller;

  static NotificationType fromApi(String value) => switch (value) {
    'order_paid' => orderPaid,
    'order_cancelled' => orderCancelled,
    'order_delivered' => orderDelivered,
    'order_processing' => orderProcessing,
    'order_shipped' => orderShipped,
    'order_refunded' => orderRefunded,
    _ => other,
  };
}
