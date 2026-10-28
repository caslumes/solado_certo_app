import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_orders_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/seller_custom_orders_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetSellerCustomOrdersUseCase getRequests;
  late List<String> opened;

  void stubPage(List<CustomOrderEntity> items) =>
      when(() => getRequests.execute(1)).thenAnswer(
        (_) async => CustomOrdersPageEntity(
          items: items,
          currentPage: 1,
          hasNext: false,
        ),
      );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => CustomOrdersCubit.seller(
              getSellerCustomOrdersUseCase: getRequests,
            )..load(),
            child: SellerCustomOrdersPage(
              openDetail: (_, request, onChanged) async {
                opened.add(request.id);
                onChanged(
                  buildCustomOrder(
                    id: request.id,
                    status: CustomOrderStatus.underReview,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getRequests = MockGetSellerCustomOrdersUseCase();
    opened = [];
  });

  testWidgets('lists the requests with the buyer and opens them', (
    tester,
  ) async {
    stubPage([buildCustomOrder()]);
    await pumpPage(tester);

    expect(find.text('Maria Souza · atualizada em 27/10/2026'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);

    await tester.tap(find.text('Palmilha sob medida'));
    await tester.pumpAndSettle();

    expect(opened, ['c1']);
    expect(find.text('Em análise'), findsOneWidget);
  });

  testWidgets('explains how to receive requests', (tester) async {
    stubPage([]);
    await pumpPage(tester);

    expect(find.textContaining('Marque "Feito sob medida"'), findsOneWidget);
  });
}
