import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';

class PodologicalProfileEntity {
  final FootstrikeType? footstrikeType;
  final String? clinicalCondition;
  final String? obs;
  final List<PainPointEntity> painPoints;
  final DateTime? updatedAt;

  PodologicalProfileEntity({
    this.footstrikeType,
    this.clinicalCondition,
    this.obs,
    this.painPoints = const [],
    this.updatedAt,
  });
}
