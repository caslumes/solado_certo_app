import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/product_detail_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

import '../../../../support/builders.dart';

class MockProductDetailCubit extends MockCubit<ProductDetailState>
    implements ProductDetailCubit {}

void main() {
  late MockProductDetailCubit cubit;

  /// Uses a tall view so the whole page is built without scrolling.
  Future<void> pumpPage(WidgetTester tester, ProductDetailState state) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ProductDetailCubit>.value(
          value: cubit,
          child: const ProductDetailPage(),
        ),
      ),
    );
  }

  setUpAll(initializeFormatting);

  setUp(() {
    cubit = MockProductDetailCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  testWidgets('shows the product, its attributes, seller and shipping', (
    tester,
  ) async {
    await pumpPage(tester, ProductDetailLoaded(product: buildProductDetail()));

    expect(find.text('Órtese corretora para joanete'), findsOneWidget);
    expect(find.text(formatCurrency(129.5)), findsOneWidget);
    expect(find.text('Em estoque (15 unidades)'), findsOneWidget);
    expect(find.text('Correção'), findsOneWidget);
    expect(find.text('Joanete'), findsOneWidget);
    expect(find.text('Pé esquerdo'), findsOneWidget);
    expect(find.text('Rígido'), findsOneWidget);
    expect(find.text('Loja Pé Bem'), findsOneWidget);
    expect(find.text('No Solado Certo desde outubro de 2026'), findsOneWidget);
    expect(find.text('PAC · Correios'), findsOneWidget);
    expect(find.text('Até 7 dias úteis'), findsOneWidget);
  });

  testWidgets('shows the safety section without a warning when complete', (
    tester,
  ) async {
    await pumpPage(tester, ProductDetailLoaded(product: buildProductDetail()));

    expect(find.text('Segurança de uso'), findsOneWidget);
    expect(find.text('Uso noturno'), findsOneWidget);
    expect(
      find.text('Uso apenas com orientação profissional.'),
      findsOneWidget,
    );
    expect(find.text('Pós-operatório recente.'), findsOneWidget);
    expect(
      find.text('Exige prescrição de um profissional de saúde.'),
      findsOneWidget,
    );
    expect(find.text('Informações de segurança incompletas'), findsNothing);
  });

  testWidgets('warns when the safety information is incomplete', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ProductDetailLoaded(
        product: buildProductDetail(
          contraindications: null,
          safetyInfoComplete: false,
        ),
      ),
    );

    expect(find.text('Informações de segurança incompletas'), findsOneWidget);
    expect(find.text('Não informado'), findsOneWidget);
  });

  testWidgets('shows a sold out product and keeps the cart disabled', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ProductDetailLoaded(product: buildProductDetail(stock: 0)),
    );

    expect(find.text('Esgotado'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('ADICIONAR AO CARRINHO'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('says when the product no longer exists', (tester) async {
    await pumpPage(
      tester,
      ProductDetailLoadFailure(failure: NotFoundFailure()),
    );

    expect(find.text('Produto não encontrado'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsNothing);
    expect(find.text('ADICIONAR AO CARRINHO'), findsNothing);
  });

  testWidgets('retries after other failures', (tester) async {
    final failure = NetworkFailure();
    await pumpPage(tester, ProductDetailLoadFailure(failure: failure));

    expect(find.text(failure.message), findsOneWidget);
    await tester.tap(find.text('TENTAR NOVAMENTE'));

    verify(() => cubit.load()).called(1);
  });
}
