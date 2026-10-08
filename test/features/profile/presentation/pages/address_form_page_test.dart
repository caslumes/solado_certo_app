import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/address_form_page.dart';

import '../../../../support/builders.dart';

void main() {
  const fields = [
    'Identificação (opcional)',
    'Destinatário',
    'CEP',
    'Rua',
    'Número',
    'Complemento (opcional)',
    'Bairro',
    'Cidade',
    'UF',
  ];

  Finder field(String label) =>
      find.byType(TextFormField).at(fields.indexOf(label));

  Future<bool?> pumpForm(
    WidgetTester tester, {
    required Future<void> Function(NewAddress) onSubmit,
  }) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddressFormPage(
                      initialReceiver: 'Maria Souza',
                      initialIsDefault: true,
                      onSubmit: onSubmit,
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> fillValidAddress(WidgetTester tester) async {
    await tester.enterText(field('Identificação (opcional)'), '  ');
    await tester.enterText(field('CEP'), '13010-111');
    await tester.enterText(field('Rua'), ' Rua Barão de Jaguara ');
    await tester.enterText(field('Número'), '1000');
    await tester.enterText(field('Bairro'), 'Centro');
    await tester.enterText(field('Cidade'), 'Campinas');
    await tester.enterText(field('UF'), 'sp');
  }

  Future<void> tapSave(WidgetTester tester) async {
    final button = find.byType(FilledButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('shows field errors and does not submit an incomplete form', (
    tester,
  ) async {
    var called = false;
    await pumpForm(tester, onSubmit: (_) async => called = true);

    await tester.enterText(field('CEP'), '1301');
    await tester.enterText(field('UF'), 'XX');
    await tapSave(tester);

    expect(find.text('CEP deve ter 8 dígitos'), findsOneWidget);
    expect(find.text('UF inválida'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('submits a normalized address and closes', (tester) async {
    NewAddress? sent;
    await pumpForm(tester, onSubmit: (address) async => sent = address);

    await fillValidAddress(tester);
    await tapSave(tester);

    expect(sent, isNotNull);
    expect(sent!.label, isNull);
    expect(sent!.receiver, 'Maria Souza');
    expect(sent!.zipCode, '13010111');
    expect(sent!.street, 'Rua Barão de Jaguara');
    expect(sent!.state, 'SP');
    expect(sent!.country, 'BR');
    expect(sent!.isDefault, isTrue);
    expect(find.byType(AddressFormPage), findsNothing);
  });

  testWidgets(
    'stays open with the typed data and a SnackBar when saving fails',
    (tester) async {
      await pumpForm(
        tester,
        onSubmit: (_) async => throw buildDioException(statusCode: 500),
      );

      await fillValidAddress(tester);
      await tapSave(tester);

      expect(find.byType(AddressFormPage), findsOneWidget);
      expect(
        find.text('Erro no servidor. Tente novamente mais tarde.'),
        findsOneWidget,
      );
      expect(find.text('Campinas'), findsOneWidget);
    },
  );
}
