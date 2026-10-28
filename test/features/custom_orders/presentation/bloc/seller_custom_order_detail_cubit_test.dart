import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/seller_custom_order_detail_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetSellerCustomOrderUseCase getRequest;
  late MockReviewCustomOrderUseCase review;
  late MockAcceptCustomOrderUseCase accept;
  late MockRejectCustomOrderUseCase reject;
  late MockRequestCustomOrderInfoUseCase requestInfo;
  late MockSendFittingReportUseCase sendReport;

  const file = UploadFile(bytes: [1, 2, 3], filename: 'laudo.pdf');
  final requested = buildCustomOrderDetail(
    actions: const {
      CustomOrderAction.review,
      CustomOrderAction.accept,
      CustomOrderAction.reject,
      CustomOrderAction.requestInfo,
    },
  );
  final underReview = buildCustomOrderDetail(
    status: CustomOrderStatus.underReview,
  );
  final approved = buildCustomOrderDetail(
    status: CustomOrderStatus.approved,
    quotedPrice: 189.9,
    actions: const {},
  );
  final completed = buildCustomOrderDetail(
    status: CustomOrderStatus.completed,
    actions: const {},
  );

  SellerCustomOrderDetailCubit buildCubit() => SellerCustomOrderDetailCubit(
    getCustomOrderUseCase: getRequest,
    reviewUseCase: review,
    acceptUseCase: accept,
    rejectUseCase: reject,
    requestInfoUseCase: requestInfo,
    sendReportUseCase: sendReport,
    requestId: 'c1',
  );

  setUp(() {
    getRequest = MockGetSellerCustomOrderUseCase();
    review = MockReviewCustomOrderUseCase();
    accept = MockAcceptCustomOrderUseCase();
    reject = MockRejectCustomOrderUseCase();
    requestInfo = MockRequestCustomOrderInfoUseCase();
    sendReport = MockSendFittingReportUseCase();
  });

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'loads the request from the seller side',
    setUp: () =>
        when(() => getRequest.execute('c1')).thenAnswer((_) async => requested),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CustomOrderDetailLoading>(),
      isA<CustomOrderDetailLoaded>().having(
        (s) => s.detail,
        'detail',
        requested,
      ),
    ],
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'starts the review',
    setUp: () =>
        when(() => review.execute('c1')).thenAnswer((_) async => underReview),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: requested),
    act: (cubit) async => expect(await cubit.review(), isNull),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having((s) => s.detail, 'detail', underReview)
          .having(
            (s) => s.notice,
            'notice',
            'Análise iniciada. O comprador foi avisado.',
          ),
    ],
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'accepts with the quoted price',
    setUp: () => when(
      () => accept.execute('c1', '189.90'),
    ).thenAnswer((_) async => approved),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: requested),
    act: (cubit) => cubit.accept('189.90'),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>().having(
        (s) => s.detail.request.quotedPrice,
        'price',
        189.9,
      ),
    ],
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'rejects and asks with the text written',
    setUp: () {
      when(
        () => reject.execute('c1', 'Sem material'),
      ).thenAnswer((_) async => requested);
      when(
        () => requestInfo.execute('c1', 'Qual o arco?'),
      ).thenAnswer((_) async => requested);
    },
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: requested),
    act: (cubit) async {
      await cubit.reject('Sem material');
      await cubit.requestInfo('Qual o arco?');
    },
    verify: (_) {
      verify(() => reject.execute('c1', 'Sem material')).called(1);
      verify(() => requestInfo.execute('c1', 'Qual o arco?')).called(1);
    },
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'sends the report with the instructions',
    setUp: () => when(
      () => sendReport.execute(
        'c1',
        file: file,
        adaptationInstructions: 'Use 1 hora no primeiro dia.',
      ),
    ).thenAnswer((_) async => completed),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: underReview),
    act: (cubit) => cubit.sendReport(file, 'Use 1 hora no primeiro dia.'),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having((s) => s.detail, 'detail', completed)
          .having((s) => s.notice, 'notice', 'Laudo enviado ao comprador.'),
    ],
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'reloads when the buyer changed the request first',
    setUp: () {
      when(() => accept.execute('c1', '189.90')).thenThrow(
        buildDioException(
          statusCode: 409,
          data: {
            'error':
                "invalid status transition: a request that is cancelled can't "
                'be changed by accept',
          },
        ),
      );
      when(() => getRequest.execute('c1')).thenAnswer(
        (_) async => buildCustomOrderDetail(
          status: CustomOrderStatus.cancelled,
          actions: const {},
        ),
      );
    },
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: requested),
    act: (cubit) async =>
        expect(await cubit.accept('189.90'), isA<OrderStatusChangedFailure>()),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having(
            (s) => s.detail.request.status,
            'status',
            CustomOrderStatus.cancelled,
          )
          .having(
            (s) => s.failure,
            'failure',
            isA<OrderStatusChangedFailure>(),
          ),
    ],
  );

  blocTest<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
    'keeps the request when the report is refused',
    setUp: () =>
        when(
          () => sendReport.execute(
            'c1',
            file: file,
            adaptationInstructions: any(named: 'adaptationInstructions'),
          ),
        ).thenThrow(
          buildDioException(
            statusCode: 415,
            data: {'error': 'the report must be a PDF, JPEG or PNG file'},
          ),
        ),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: underReview),
    act: (cubit) => cubit.sendReport(file, 'Instruções'),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having((s) => s.detail, 'detail', underReview)
          .having(
            (s) => s.failure,
            'failure',
            isA<FittingReportFileTypeFailure>(),
          ),
    ],
    verify: (_) => verifyNever(() => getRequest.execute(any())),
  );
}
