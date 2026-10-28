import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/fitting_report_page.dart';

void main() {
  const report = UploadFile(bytes: [1, 2, 3], filename: 'laudo.pdf');

  late List<(UploadFile, String)> sent;
  late Failure? answer;
  late bool popped;

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped =
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => FittingReportPage(
                        pickFile: (_) async => report,
                        submit: (file, instructions) async {
                          sent.add((file, instructions));
                          return answer;
                        },
                      ),
                    ),
                  ) ??
                  false;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    sent = [];
    answer = null;
    popped = false;
  });

  testWidgets('needs the file and the instructions', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('ENVIAR LAUDO'));
    await tester.pump();

    expect(find.text('Escolha o arquivo do laudo.'), findsOneWidget);
    expect(find.text('Campo obrigatório'), findsOneWidget);
    expect(sent, isEmpty);
  });

  testWidgets('sends the chosen file with the instructions', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Escolher arquivo'));
    await tester.pumpAndSettle();
    expect(find.text('laudo.pdf'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      ' Use 1 hora no primeiro dia. ',
    );
    await tester.tap(find.text('ENVIAR LAUDO'));
    await tester.pumpAndSettle();

    expect(sent, [(report, 'Use 1 hora no primeiro dia.')]);
    expect(popped, isTrue);
    expect(find.byType(FittingReportPage), findsNothing);
  });

  testWidgets('stays open when the report is refused', (tester) async {
    answer = FittingReportFileTypeFailure();
    await pumpPage(tester);
    await tester.tap(find.text('Escolher arquivo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Instruções');
    await tester.tap(find.text('ENVIAR LAUDO'));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    expect(find.byType(FittingReportPage), findsOneWidget);
    expect(find.text('Trocar'), findsOneWidget);
  });
}
