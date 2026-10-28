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
import 'package:solado_certo_app/features/custom_orders/presentation/pages/my_custom_orders_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetCustomOrdersUseCase getRequests;
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
            create: (_) =>
                CustomOrdersCubit(getCustomOrdersUseCase: getRequests)..load(),
            child: MyCustomOrdersPage(
              openDetail: (_, request, onChanged) async {
                opened.add(request.id);
                onChanged(
                  buildCustomOrder(
                    id: request.id,
                    status: CustomOrderStatus.cancelled,
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
    getRequests = MockGetCustomOrdersUseCase();
    opened = [];
  });

  testWidgets('lists the requests and keeps them in step with the detail', (
    tester,
  ) async {
    stubPage([
      buildCustomOrder(),
      buildCustomOrder(
        id: 'c2',
        status: CustomOrderStatus.approved,
        quotedPrice: 320,
      ),
    ]);
    await pumpPage(tester);

    expect(find.text('Palmilha sob medida'), findsNWidgets(2));
    expect(
      find.text('Loja Pé Bem · atualizada em 27/10/2026'),
      findsNWidgets(2),
    );
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Aceita'), findsOneWidget);
    expect(find.text(formatCurrency(320)), findsOneWidget);

    await tester.tap(find.text('Aceita'));
    await tester.pumpAndSettle();

    expect(opened, ['c2']);
    expect(find.text('Cancelada'), findsOneWidget);
  });

  testWidgets('explains how to ask when there are none', (tester) async {
    stubPage([]);
    await pumpPage(tester);

    expect(find.text('Nenhuma solicitação sob medida'), findsOneWidget);
  });
}
