/// Entity for body weight records (with dual unit support)
class BodyWeightEntity {
  final int? id;
  final double weightKg;
  final double weightLb;
  final String? memo;
  final int recordedAt; // UNIX timestamp (start of day)
  final int createdAt;
  final int updatedAt;

  const BodyWeightEntity({
    this.id,
    required this.weightKg,
    required this.weightLb,
    this.memo,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get weight in specified unit
  double getWeight(String unit) {
    return unit == 'kg' ? weightKg : weightLb;
  }

  /// Create from database map
  factory BodyWeightEntity.fromMap(Map<String, dynamic> map) {
    return BodyWeightEntity(
      id: map['id'] as int?,
      weightKg: (map['weight_kg'] as num).toDouble(),
      weightLb: (map['weight_lb'] as num).toDouble(),
      memo: map['memo'] as String?,
      recordedAt: map['recorded_at'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight_kg': weightKg,
      'weight_lb': weightLb,
      'memo': memo,
      'recorded_at': recordedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  BodyWeightEntity copyWith({
    int? id,
    double? weightKg,
    double? weightLb,
    String? memo,
    int? recordedAt,
    int? createdAt,
    int? updatedAt,
  }) {
    return BodyWeightEntity(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      weightLb: weightLb ?? this.weightLb,
      memo: memo ?? this.memo,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
