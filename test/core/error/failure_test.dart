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

  group('409 bodies', () {
    test('out of stock lists the items', () {
      final failure = Failure.from(
        buildDioException(
          statusCode: 409,
          data: {
            'error': 'out of stock',
            'items': [
              {'advertisement_id': '601', 'requested': 3, 'available': 1},
            ],
          },
        ),
      );

      expect(failure, isA<OutOfStockFailure>());
      final items = (failure as OutOfStockFailure).items;
      expect(items.single.advertisementId, '601');
      expect(items.single.requested, 3);
      expect(items.single.available, 1);
      expect(failure.message, 'Só há 1 unidade disponível.');
    });

    test('out of stock messages', () {
      StockShortage shortage(int available) => StockShortage(
        advertisementId: '601',
        requested: 5,
        available: available,
      );

      expect(
        OutOfStockFailure([shortage(0)]).message,
        'Este produto está esgotado.',
      );
      expect(
        OutOfStockFailure([shortage(3)]).message,
        'Só há 3 unidades disponíveis.',
      );
      expect(
        OutOfStockFailure([shortage(0), shortage(1)]).message,
        'Alguns produtos não têm estoque suficiente.',
      );
    });

    test('buying your own ad', () {
      expect(
        Failure.from(
          buildDioException(
            statusCode: 409,
            data: {'error': 'cannot buy your own advertisement'},
          ),
        ),
        isA<OwnAdvertisementFailure>(),
      );
    });

    test('any other 409 is a conflict', () {
      expect(
        Failure.from(
          buildDioException(statusCode: 409, data: {'error': 'something else'}),
        ),
        isA<ConflictFailure>(),
      );
    });
  });

  test('a 422 without a field list has no fields', () {
    expect(
      Failure.from(buildDioException(statusCode: 422)),
      isA<MissingFieldsFailure>().having((f) => f.fields, 'fields', isEmpty),
    );
  });

  group('checkout bodies', () {
    Failure from(int statusCode, Map<String, dynamic> body) =>
        Failure.from(buildDioException(statusCode: statusCode, data: body));

    test('409 prices and cart changed', () {
      expect(
        from(409, {'error': 'prices changed'}),
        isA<PricesChangedFailure>(),
      );
      expect(from(409, {'error': 'cart changed'}), isA<CartChangedFailure>());
    });

    test('422 shipping option required lists the items', () {
      expect(
        from(422, {
          'error': 'shipping option required',
          'advertisement_ids': ['601', '602'],
        }),
        isA<ShippingRequiredFailure>().having(
          (f) => f.advertisementIds,
          'advertisementIds',
          ['601', '602'],
        ),
      );
    });

    test('422 empty cart', () {
      expect(from(422, {'error': 'cart is empty'}), isA<EmptyCartFailure>());
    });

    test('404 address not found', () {
      expect(
        from(404, {'error': 'address not found'}),
        isA<AddressNotFoundFailure>(),
      );
      expect(from(404, {'error': 'order not found'}), isA<NotFoundFailure>());
    });
  });

  test('409 invalid status transition on an order', () {
    expect(
      Failure.from(
        buildDioException(
          statusCode: 409,
          data: {'error': 'invalid status transition'},
        ),
      ),
      isA<OrderStatusChangedFailure>(),
    );
  });

  test('maps payment errors by their code', () {
    Failure fromBody(int status, String error) => Failure.from(
      buildDioException(statusCode: status, data: {'error': error}),
    );

    expect(
      fromBody(409, 'order payment window expired'),
      isA<PaymentExpiredFailure>(),
    );
    expect(
      fromBody(409, 'another payment of this order is in progress'),
      isA<PaymentInProgressFailure>(),
    );
    expect(
      fromBody(409, 'tax id already registered'),
      isA<TaxIdInUseFailure>(),
    );
    expect(
      fromBody(
        409,
        'invalid status transition: only an order awaiting payment can be '
        'paid, this one is paid',
      ),
      isA<OrderStatusChangedFailure>(),
    );
    expect(fromBody(422, 'tax id required'), isA<TaxIdRequiredFailure>());
    expect(
      fromBody(
        422,
        'invalid tracking code: a Correios tracking code has the format '
        'AA123456789BR',
      ),
      isA<InvalidTrackingCodeFailure>(),
    );
    expect(
      fromBody(409, 'tracking code already registered'),
      isA<TrackingCodeInUseFailure>(),
    );
    expect(
      fromBody(409, 'item already reviewed'),
      isA<AlreadyReviewedFailure>(),
    );
    expect(
      fromBody(409, 'only a delivered order can be reviewed'),
      isA<ReviewNotAllowedFailure>(),
    );
    expect(
      fromBody(503, 'payment gateway unavailable'),
      isA<GatewayUnavailableFailure>(),
    );
    expect(fromBody(503, 'other'), isA<ServerFailure>());
  });
}
