import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

class ConsentModel {
  const ConsentModel({
    required this.purpose,
    required this.termsVersion,
    required this.grantedAt,
  });

  final String purpose;
  final String termsVersion;
  final DateTime grantedAt;

  factory ConsentModel.fromJson(Map<String, dynamic> json) => ConsentModel(
    purpose: json['purpose'] as String,
    termsVersion: json['terms_version'] as String,
    grantedAt: DateTime.parse(json['granted_at'] as String),
  );

  ConsentEntity toEntity() => ConsentEntity(
    purpose: purpose,
    termsVersion: termsVersion,
    grantedAt: grantedAt,
  );
}
