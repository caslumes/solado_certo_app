import 'package:solado_certo_app/features/profile/data/models/pain_point_model.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';

Map<String, dynamic> podologicalProfileUpdateToJson(
  PodologicalProfileUpdate update,
) => {
  'footstrike_type': update.footstrikeType.toApi(),
  'pain_point_ids': update.painPointIds,
  'clinical_condition': update.clinicalCondition,
  'obs': update.obs,
};

class PodologicalProfileModel {
  const PodologicalProfileModel({
    this.footstrikeType,
    this.clinicalCondition,
    this.obs,
    this.painPoints = const [],
    this.updatedAt,
  });

  final String? footstrikeType;
  final String? clinicalCondition;
  final String? obs;
  final List<PainPointModel> painPoints;
  final DateTime? updatedAt;

  factory PodologicalProfileModel.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updated_at'] as String?;
    return PodologicalProfileModel(
      footstrikeType: json['footstrike_type'] as String?,
      clinicalCondition: json['clinical_condition'] as String?,
      obs: json['obs'] as String?,
      painPoints: ((json['pain_points'] as List?) ?? const [])
          .map((e) => PainPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
    );
  }

  PodologicalProfileEntity toEntity() => PodologicalProfileEntity(
    footstrikeType: FootstrikeType.fromApi(footstrikeType),
    clinicalCondition: clinicalCondition,
    obs: obs,
    painPoints: painPoints.map((e) => e.toEntity()).toList(),
    updatedAt: updatedAt,
  );
}
