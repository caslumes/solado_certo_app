import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';

class PodologicalProfileModel {
  const PodologicalProfileModel({
    this.footstrikeType,
    this.clinicalCondition,
    this.obs,
    this.updatedAt,
  });

  final String? footstrikeType;
  final String? clinicalCondition;
  final String? obs;
  final DateTime? updatedAt;

  factory PodologicalProfileModel.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updated_at'] as String?;
    return PodologicalProfileModel(
      footstrikeType: json['footstrike_type'] as String?,
      clinicalCondition: json['clinical_condition'] as String?,
      obs: json['obs'] as String?,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
    );
  }

  PodologicalProfileEntity toEntity() => PodologicalProfileEntity(
    footstrikeType: footstrikeType,
    clinicalCondition: clinicalCondition,
    obs: obs,
    updatedAt: updatedAt,
  );
}
