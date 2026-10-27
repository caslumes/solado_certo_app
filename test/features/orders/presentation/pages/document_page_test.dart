import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/document_page.dart';

import '../../../../support/builders.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAwS2OUAAAAABJRU5ErkJggg==',
);

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    Future<DownloadedFile> Function(String url) load, {
    Future<bool> Function(List<int> bytes, String filename)? openPdf,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentPage(
          url: '/documents/d1',
          title: 'Receita',
          load: load,
          openPdf: openPdf ?? (_, _) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an image in the app', (tester) async {
    await pumpPage(
      tester,
      (_) async => DownloadedFile(bytes: _png, contentType: 'image/png'),
    );

    expect(find.text('RECEITA'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('opens a PDF in the reader of the device', (tester) async {
    final opened = <String>[];
    var result = true;
    await pumpPage(
      tester,
      (_) async =>
          const DownloadedFile(bytes: [1, 2], contentType: 'application/pdf'),
      openPdf: (bytes, filename) async {
        opened.add(filename);
        return result;
      },
    );

    await tester.tap(find.text('ABRIR PDF'));
    await tester.pumpAndSettle();
    expect(opened, ['documento-d1.pdf']);
    expect(find.byType(SnackBar), findsNothing);

    result = false;
    await tester.tap(find.text('ABRIR PDF'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum aplicativo deste aparelho abre PDF.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a load error with retry', (tester) async {
    var calls = 0;
    await pumpPage(tester, (url) async {
      calls++;
      if (calls == 1) throw buildDioException(statusCode: 404);
      return DownloadedFile(bytes: _png, contentType: 'image/png');
    });

    expect(
      find.text('O conteúdo procurado não foi encontrado.'),
      findsOneWidget,
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('waits for the file', (tester) async {
    final file = Completer<DownloadedFile>();
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentPage(
          url: '/documents/d1',
          title: 'Receita',
          load: (_) => file.future,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    file.complete(const DownloadedFile(bytes: [1], contentType: 'text/plain'));
    await tester.pumpAndSettle();
    expect(find.text('Não é possível mostrar este arquivo.'), findsOneWidget);
  });
}
