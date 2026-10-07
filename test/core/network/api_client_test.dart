import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/network/api_client.dart';
import 'package:solado_certo_app/core/storage/storage_keys.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/fake_secure_storage.dart';

void main() {
  const refreshPath = '/auth/refresh-token';
  const profilePath = '/me/profile';

  late FakeSecureStorage storage;
  late ApiClient client;
  late FakeHttpAdapter adapter;

  void useServer(
    FutureOr<FakeResponse> Function(RequestOptions request) respond,
  ) {
    adapter = FakeHttpAdapter(respond);
    client.dio.httpClientAdapter = adapter;
  }

  setUp(() {
    storage = FakeSecureStorage({
      StorageKeys.accessToken: 'old-access',
      StorageKeys.refreshToken: 'old-refresh',
    });
    client = ApiClient(storage);
  });

  test('attaches the stored access token', () async {
    useServer((_) => (statusCode: 200, body: {'ok': true}));

    await client.get(profilePath);

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer old-access',
    );
  });

  test('sends no Authorization header without an access token', () async {
    storage.values.clear();
    useServer((_) => (statusCode: 200, body: {'ok': true}));

    await client.get(profilePath);

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('refreshes once, rotates both tokens and retries the request', () async {
    useServer((request) {
      if (request.path == refreshPath) {
        return (
          statusCode: 200,
          body: {'access_token': 'new-access', 'refresh_token': 'new-refresh'},
        );
      }
      final authorized =
          request.headers['Authorization'] == 'Bearer new-access';
      return authorized
          ? (statusCode: 200, body: {'name': 'Maria'})
          : (statusCode: 401, body: {'error': 'expired'});
    });

    final response = await client.get(profilePath);

    expect(response, {'name': 'Maria'});
    expect(adapter.requestsTo(refreshPath), hasLength(1));
    expect(adapter.requestsTo(refreshPath).single.data, {
      'refresh_token': 'old-refresh',
    });
    expect(adapter.requestsTo(profilePath), hasLength(2));
    expect(storage.values, {
      StorageKeys.accessToken: 'new-access',
      StorageKeys.refreshToken: 'new-refresh',
    });
  });

  test('clears tokens and surfaces the 401 when refresh is rejected', () async {
    useServer(
      (request) => request.path == refreshPath
          ? (statusCode: 401, body: {'error': 'revoked'})
          : (statusCode: 401, body: {'error': 'expired'}),
    );

    await expectLater(
      client.get(profilePath),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(adapter.requestsTo(refreshPath), hasLength(1));
    expect(storage.values, isEmpty);
  });

  test('does not refresh again when the retried request is rejected', () async {
    useServer(
      (request) => request.path == refreshPath
          ? (
              statusCode: 200,
              body: {
                'access_token': 'new-access',
                'refresh_token': 'new-refresh',
              },
            )
          : (statusCode: 401, body: {'error': 'expired'}),
    );

    await expectLater(client.get(profilePath), throwsA(isA<DioException>()));
    expect(adapter.requestsTo(refreshPath), hasLength(1));
    expect(adapter.requestsTo(profilePath), hasLength(2));
  });

  test('does not refresh on 401 from auth endpoints', () async {
    useServer((_) => (statusCode: 401, body: {'error': 'invalid'}));

    await expectLater(
      client.post('/auth/login', data: {'email': 'x', 'password': 'y'}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requestsTo(refreshPath), isEmpty);
  });

  test('does not refresh without a stored refresh token', () async {
    storage.values.remove(StorageKeys.refreshToken);
    useServer((_) => (statusCode: 401, body: {'error': 'expired'}));

    await expectLater(client.get(profilePath), throwsA(isA<DioException>()));
    expect(adapter.requestsTo(refreshPath), isEmpty);
  });

  test('shares one refresh between concurrent 401 responses', () async {
    var currentRefreshToken = 'old-refresh';
    var issued = 0;
    useServer((request) async {
      if (request.path == refreshPath) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (request.data['refresh_token'] != currentRefreshToken) {
          return (statusCode: 401, body: {'error': 'revoked'});
        }
        issued++;
        currentRefreshToken = 'refresh-$issued';
        return (
          statusCode: 200,
          body: {
            'access_token': 'access-$issued',
            'refresh_token': currentRefreshToken,
          },
        );
      }
      final authorized =
          request.headers['Authorization'] == 'Bearer access-$issued';
      return issued > 0 && authorized
          ? (statusCode: 200, body: {'ok': true})
          : (statusCode: 401, body: {'error': 'expired'});
    });

    final responses = await Future.wait(
      List.generate(5, (_) => client.get(profilePath)),
    );

    expect(responses, everyElement({'ok': true}));
    expect(adapter.requestsTo(refreshPath), hasLength(1));
    expect(storage.values, {
      StorageKeys.accessToken: 'access-1',
      StorageKeys.refreshToken: 'refresh-1',
    });
  });

  test('starts a new refresh after the previous one finished', () async {
    var issued = 0;
    useServer((request) {
      if (request.path == refreshPath) {
        issued++;
        return (
          statusCode: 200,
          body: {
            'access_token': 'access-$issued',
            'refresh_token': 'refresh-$issued',
          },
        );
      }
      return request.extra['retried_after_refresh'] == true
          ? (statusCode: 200, body: {'ok': true})
          : (statusCode: 401, body: {'error': 'expired'});
    });

    await client.get(profilePath);
    await client.get(profilePath);

    expect(adapter.requestsTo(refreshPath), hasLength(2));
    expect(adapter.requestsTo(refreshPath).last.data, {
      'refresh_token': 'refresh-1',
    });
  });
}
