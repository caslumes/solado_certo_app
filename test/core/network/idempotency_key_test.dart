import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/network/idempotency_key.dart';

void main() {
  test('creates random version 4 UUIDs', () {
    final keys = {for (var i = 0; i < 100; i++) newIdempotencyKey()};

    expect(keys, hasLength(100));
    for (final key in keys) {
      expect(
        key,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });
}
