/// Exercise master entity for standard and custom exercises
class ExerciseMasterEntity {
  final int? id;
  final String name; // Exercise name (e.g., Bench Press)
  final String? bodyPart; // Body part (e.g., chest, back, legs)
  final int isCustom; // 0: standard exercise, 1: user-added exercise
  final String recordType; // 'reps' or 'time'
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const ExerciseMasterEntity({
    this.id,
    required this.name,
    this.bodyPart,
    required this.isCustom,
    this.recordType = 'reps',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory ExerciseMasterEntity.fromMap(Map<String, dynamic> map) {
    return ExerciseMasterEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      bodyPart: map['body_part'] as String?,
      isCustom: map['is_custom'] as int,
      recordType: (map['record_type'] as String?) ?? 'reps',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'body_part': bodyPart,
      'is_custom': isCustom,
      'record_type': recordType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  ExerciseMasterEntity copyWith({
    int? id,
    String? name,
    String? bodyPart,
    int? isCustom,
    String? recordType,
    int? createdAt,
    int? updatedAt,
  }) {
    return ExerciseMasterEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyPart: bodyPart ?? this.bodyPart,
      isCustom: isCustom ?? this.isCustom,
      recordType: recordType ?? this.recordType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExerciseMasterEntity(id: $id, name: $name, bodyPart: $bodyPart, isCustom: $isCustom, recordType: $recordType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseMasterEntity &&
        other.id == id &&
        other.name == name &&
        other.bodyPart == bodyPart &&
        other.isCustom == isCustom &&
        other.recordType == recordType &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        bodyPart.hashCode ^
        isCustom.hashCode ^
        recordType.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
