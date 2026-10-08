import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_profile.dart';

import '../../../../support/builders.dart';

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  late MockOnboardingBloc bloc;

  const fields = ['Nome', 'Email', 'Telefone'];

  Finder field(String label) =>
      find.byType(TextFormField).at(fields.indexOf(label));

  Future<void> pumpStep(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<OnboardingBloc>.value(
        value: bloc,
        child: const OnboardingProfile(),
      ),
    ),
  );

  Future<void> tapAdvance(WidgetTester tester) async {
    final button = find.text('AVANÇAR');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  setUpAll(() => registerFallbackValue(ReloadAddressesEvent()));

  setUp(() {
    bloc = MockOnboardingBloc();
    when(() => bloc.state).thenReturn(
      OnboardingInProgress(
        onboardingDraft: buildDraft(step: OnboardingStep.profileConfig),
      ),
    );
  });

  testWidgets('prefills the profile and keeps the e-mail read-only', (
    tester,
  ) async {
    await pumpStep(tester);

    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('maria@example.com'), findsOneWidget);
    final email = tester.widget<TextField>(
      find.descendant(of: field('Email'), matching: find.byType(TextField)),
    );
    expect(email.readOnly, isTrue);
  });

  testWidgets('does not submit an invalid phone', (tester) async {
    await pumpStep(tester);

    await tester.enterText(field('Telefone'), '123');
    await tapAdvance(tester);

    expect(find.text('Informe DDD e número'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('submits the trimmed name and phone', (tester) async {
    await pumpStep(tester);

    await tester.enterText(field('Nome'), '  Maria Lima ');
    await tester.enterText(field('Telefone'), ' (19) 98888-7777 ');
    await tapAdvance(tester);

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as SubmitProfileStepEvent;
    expect(event.name, 'Maria Lima');
    expect(event.phone, '(19) 98888-7777');
  });
}
