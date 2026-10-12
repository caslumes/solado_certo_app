import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

EventTransformer<E> debounce<E>(Duration duration) =>
    (events, mapper) => _debounced(events, duration).asyncExpand(mapper);

Stream<E> _debounced<E>(Stream<E> source, Duration duration) {
  Timer? timer;
  StreamSubscription<E>? subscription;
  late final StreamController<E> controller;
  controller = StreamController<E>(
    onListen: () {
      subscription = source.listen(
        (event) {
          timer?.cancel();
          timer = Timer(duration, () => controller.add(event));
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onCancel: () {
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
