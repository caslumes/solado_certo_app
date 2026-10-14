import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/network/api_urls.dart';

void main() {
  const base = 'http://10.0.2.2:8080';

  test('resolves an uploaded file path against the API address', () {
    expect(
      resolveApiUrl('/files/public/ads/a.png', baseUrl: base),
      'http://10.0.2.2:8080/files/public/ads/a.png',
    );
  });

  test('keeps an absolute URL unchanged', () {
    expect(
      resolveApiUrl('https://placehold.co/600x400.png', baseUrl: base),
      'https://placehold.co/600x400.png',
    );
  });
}
