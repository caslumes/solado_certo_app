class PodologicalProfileEntity {
  final String? footstrikeType;
  final String? clinicalCondition;
  final String? obs;
  final DateTime? updatedAt;

  PodologicalProfileEntity({
    this.footstrikeType,
    this.clinicalCondition,
    this.obs,
    this.updatedAt,
  });

  factory PodologicalProfileEntity.fromJson(Map<String, dynamic> json) {
    return PodologicalProfileEntity(
      footstrikeType: json['footstrike_type'],
      clinicalCondition: json['clinical_condition'],
      obs: json['obs'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'footstrike_type': footstrikeType,
      'clinical_condition': clinicalCondition,
      'obs': obs,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
