enum CustomOrderAction {
  review,
  accept,
  reject,
  requestInfo,
  report,
  complement,
  cancel,
  checkout,
  sendPhoto;

  static CustomOrderAction? fromApi(String value) => switch (value) {
    'review' => review,
    'accept' => accept,
    'reject' => reject,
    'request_info' => requestInfo,
    'report' => report,
    'complement' => complement,
    'cancel' => cancel,
    'checkout' => checkout,
    'send_photo' => sendPhoto,
    _ => null,
  };
}
