import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';

class PodologicalProfileUpdate {
  final FootstrikeType footstrikeType;
  final List<String> painPointIds;
  final String? clinicalCondition;
  final String? obs;

  const PodologicalProfileUpdate({
    required this.footstrikeType,
    this.painPointIds = const [],
    this.clinicalCondition,
    this.obs,
  });
}
