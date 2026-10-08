import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/podological_consent_terms_page.dart';

import '../../../../support/builders.dart';

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  late MockOnboardingBloc bloc;

  const painPoints = [
    PainPointEntity(id: 'p1', name: 'Calcanhar'),
    PainPointEntity(id: 'p2', name: 'Dedos'),
  ];

  final saveButton = find.widgetWithText(FilledButton, 'SALVAR E AVANÇAR');

  void stubState({bool hasConsent = false, PodologicalProfileEntity? profile}) {
    final draft = buildDraft(step: OnboardingStep.podologicalProfile);
    when(() => bloc.state).thenReturn(
      OnboardingInProgress(
        onboardingDraft: OnboardingDraft(
          onboarding: draft.onboarding,
          profile: draft.profile,
          addresses: draft.addresses,
          podologicalProfile: profile ?? PodologicalProfileEntity(),
          painPoints: painPoints,
          hasPodologicalConsent: hasConsent,
        ),
      ),
    );
  }

  Future<void> pumpStep(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<OnboardingBloc>.value(
        value: bloc,
        child: const OnboardingPodologicalProfile(),
      ),
    ),
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton).onPressed != null;

  setUpAll(() => registerFallbackValue(SkipOnboardingStepEvent()));

  setUp(() {
    bloc = MockOnboardingBloc();
    stubState();
  });

  testWidgets('keeps saving disabled until consent is checked', (tester) async {
    await pumpStep(tester);
    await tap(tester, find.text(FootstrikeType.neutral.label));

    expect(saveEnabled(tester), isFalse);

    await tap(tester, find.text(podologicalConsentText));

    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('asks for the footstrike type before saving', (tester) async {
    await pumpStep(tester);

    await tap(tester, find.text(podologicalConsentText));
    await tap(tester, saveButton);

    expect(find.text('Selecione o tipo de pisada'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('submits the selected answers after consent', (tester) async {
    await pumpStep(tester);

    await tap(tester, find.text(FootstrikeType.supinated.label));
    await tap(tester, find.text('Dedos'));
    await tester.enterText(find.byType(TextFormField).first, '  ');
    await tap(tester, find.text(podologicalConsentText));
    await tap(tester, saveButton);

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as SubmitPodologicalProfileStepEvent;
    expect(event.update.footstrikeType, FootstrikeType.supinated);
    expect(event.update.painPointIds, ['p2']);
    expect(event.update.clinicalCondition, isNull);
  });

  testWidgets('prefills a saved profile and an existing consent', (
    tester,
  ) async {
    stubState(
      hasConsent: true,
      profile: PodologicalProfileEntity(
        footstrikeType: FootstrikeType.pronated,
        clinicalCondition: 'Fascite plantar',
        painPoints: const [PainPointEntity(id: 'p1', name: 'Calcanhar')],
      ),
    );
    await pumpStep(tester);

    expect(saveEnabled(tester), isTrue);
    expect(find.text('Fascite plantar'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, FootstrikeType.pronated.label),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Calcanhar'))
          .selected,
      isTrue,
    );
  });

  testWidgets('can skip the step without consenting', (tester) async {
    await pumpStep(tester);

    await tap(tester, find.text('PULAR ESTA ETAPA'));

    verify(() => bloc.add(any(that: isA<SkipOnboardingStepEvent>()))).called(1);
  });

  testWidgets('opens the consent terms', (tester) async {
    await pumpStep(tester);

    await tap(tester, find.text('Ler termos'));

    expect(find.byType(PodologicalConsentTermsPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('podological-profile-v1'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('podological-profile-v1'), findsOneWidget);
  });
}
