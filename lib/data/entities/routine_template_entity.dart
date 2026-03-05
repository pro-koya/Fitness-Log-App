/// Routine template entity for saved workout routines
class RoutineTemplateEntity {
  final int? id;
  final String name;
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const RoutineTemplateEntity({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory RoutineTemplateEntity.fromMap(Map<String, dynamic> map) {
    return RoutineTemplateEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  RoutineTemplateEntity copyWith({
    int? id,
    String? name,
    int? createdAt,
    int? updatedAt,
  }) {
    return RoutineTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RoutineTemplateEntity(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RoutineTemplateEntity &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
