import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeResponse = ({int statusCode, Object? body});

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final FakeResponse Function(RequestOptions request) respond;
  final List<RequestOptions> requests = [];

  Iterable<RequestOptions> requestsTo(String path) =>
      requests.where((request) => request.path == path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = respond(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
