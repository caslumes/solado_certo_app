enum NotificationType {
  orderPaid(forSeller: true),
  orderCancelled(forSeller: true),
  orderDelivered(forSeller: true),
  orderProcessing(forSeller: false),
  orderShipped(forSeller: false),
  orderRefunded(forSeller: false),
  deliveryDeadline(forSeller: false),
  prescriptionSent(forSeller: true),
  prescriptionRejected(forSeller: false),
  customOrderRequested(forSeller: true),
  customOrderUpdated(forSeller: false),

  other(forSeller: false);

  const NotificationType({required this.forSeller});

  final bool forSeller;

  static NotificationType fromApi(String value) => switch (value) {
    'order_paid' => orderPaid,
    'order_cancelled' => orderCancelled,
    'order_delivered' => orderDelivered,
    'order_processing' => orderProcessing,
    'order_shipped' => orderShipped,
    'order_refunded' => orderRefunded,
    'delivery_deadline' => deliveryDeadline,
    'prescription_sent' => prescriptionSent,
    'prescription_rejected' => prescriptionRejected,
    'custom_order_requested' => customOrderRequested,
    'custom_order_updated' => customOrderUpdated,
    _ => other,
  };
}
