import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_custom_order_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_custom_order_consent_use_case.dart';

import '../../../../support/mocks.dart';

void main() {
  late MockProfileRepository repository;

  ConsentEntity consent(String purpose, String version) => ConsentEntity(
    purpose: purpose,
    termsVersion: version,
    grantedAt: DateTime(2026),
  );

  setUp(() => repository = MockProfileRepository());

  test('only the current custom order terms count as consent', () async {
    final useCase = HasCustomOrderConsentUseCase(repository);

    when(
      repository.getConsents,
    ).thenAnswer((_) async => [consent('prescription', 'prescription-v1')]);
    expect(await useCase.execute(), isFalse);

    when(
      repository.getConsents,
    ).thenAnswer((_) async => [consent('custom_order', 'custom-order-v0')]);
    expect(await useCase.execute(), isFalse);

    when(
      repository.getConsents,
    ).thenAnswer((_) async => [consent('custom_order', 'custom-order-v1')]);
    expect(await useCase.execute(), isTrue);
  });

  test('grants the current custom order terms', () async {
    when(() => repository.grantConsent(any(), any())).thenAnswer(
      (_) async => consent(
        ConsentPurposes.customOrder,
        ConsentTermsVersions.customOrder,
      ),
    );

    await GrantCustomOrderConsentUseCase(repository).execute();

    verify(
      () => repository.grantConsent('custom_order', 'custom-order-v1'),
    ).called(1);
  });
}
