abstract final class ConsentPurposes {
  static const podologicalProfile = 'podological_profile';
}

abstract final class ConsentTermsVersions {
  static const podologicalProfile = 'podological-profile-v1';
}

class ConsentEntity {
  final String purpose;
  final String termsVersion;
  final DateTime grantedAt;

  const ConsentEntity({
    required this.purpose,
    required this.termsVersion,
    required this.grantedAt,
  });
}
