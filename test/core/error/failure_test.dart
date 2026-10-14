import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/error/failure.dart';

import '../../support/builders.dart';

void main() {
  test('maps connection problems and timeouts to NetworkFailure', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(
        Failure.from(buildDioException(type: type)),
        isA<NetworkFailure>(),
      );
    }
  });

  test('maps response status codes', () {
    expect(
      Failure.from(buildDioException(statusCode: 401)),
      isA<UnauthorizedFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 400)),
      isA<InvalidInputFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 404)),
      isA<NotFoundFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 409)),
      isA<ConflictFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 403)),
      isA<ForbiddenFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 413)),
      isA<FileTooLargeFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 415)),
      isA<UnsupportedFileTypeFailure>(),
    );
    expect(
      Failure.from(buildDioException(statusCode: 503)),
      isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
    );
  });

  test('keeps existing failures and wraps anything else', () {
    final failure = NetworkFailure();
    expect(Failure.from(failure), same(failure));
    expect(Failure.from(const FormatException()), isA<UnexpectedFailure>());
    expect(
      Failure.from(buildDioException(type: DioExceptionType.cancel)),
      isA<UnexpectedFailure>(),
    );
  });

  test('reads the missing fields from a 422 body', () {
    final requestOptions = RequestOptions(path: '/seller/ads/1/publish');
    final failure = Failure.from(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'error': 'missing required fields',
            'fields': ['price', 'images'],
          },
        ),
      ),
    );

    expect(
      failure,
      isA<MissingFieldsFailure>().having((f) => f.fields, 'fields', [
        'price',
        'images',
      ]),
    );
  });

  test('a 422 without a field list has no fields', () {
    expect(
      Failure.from(buildDioException(statusCode: 422)),
      isA<MissingFieldsFailure>().having((f) => f.fields, 'fields', isEmpty),
    );
  });
}
