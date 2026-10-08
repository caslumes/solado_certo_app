import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockProfileRepository repository;

  const update = PodologicalProfileUpdate(
    footstrikeType: FootstrikeType.neutral,
  );

  ConsentEntity consent(String purpose, String version) => ConsentEntity(
    purpose: purpose,
    termsVersion: version,
    grantedAt: DateTime(2026),
  );

  setUpAll(() => registerFallbackValue(update));

  setUp(() => repository = MockProfileRepository());

  group('SavePodologicalProfileUseCase', () {
    test('grants the current consent before saving the profile', () async {
      when(() => repository.grantConsent(any(), any())).thenAnswer(
        (_) async => consent(
          ConsentPurposes.podologicalProfile,
          ConsentTermsVersions.podologicalProfile,
        ),
      );
      when(
        () => repository.savePodologicalProfile(any()),
      ).thenAnswer((_) async => PodologicalProfileEntity());

      await SavePodologicalProfileUseCase(repository).execute(update);

      verifyInOrder([
        () => repository.grantConsent(
          'podological_profile',
          'podological-profile-v1',
        ),
        () => repository.savePodologicalProfile(update),
      ]);
    });

    test('does not send the profile when consent is not recorded', () async {
      when(
        () => repository.grantConsent(any(), any()),
      ).thenThrow(buildDioException(statusCode: 500));

      await expectLater(
        SavePodologicalProfileUseCase(repository).execute(update),
        throwsA(anything),
      );
      verifyNever(() => repository.savePodologicalProfile(any()));
    });
  });

  test(
    'RevokePodologicalConsentUseCase revokes the podological purpose',
    () async {
      when(() => repository.revokeConsent(any())).thenAnswer((_) async {});

      await RevokePodologicalConsentUseCase(repository).execute();

      verify(() => repository.revokeConsent('podological_profile')).called(1);
    },
  );

  group('HasPodologicalConsentUseCase', () {
    test('is true only for an active consent to the current terms', () async {
      final useCase = HasPodologicalConsentUseCase(repository);

      when(() => repository.getConsents()).thenAnswer(
        (_) async => [
          consent('prescription', ConsentTermsVersions.podologicalProfile),
          consent(ConsentPurposes.podologicalProfile, 'podological-profile-v0'),
        ],
      );
      expect(await useCase.execute(), isFalse);

      when(() => repository.getConsents()).thenAnswer(
        (_) async => [
          consent(
            ConsentPurposes.podologicalProfile,
            ConsentTermsVersions.podologicalProfile,
          ),
        ],
      );
      expect(await useCase.execute(), isTrue);
    });
  });
}
