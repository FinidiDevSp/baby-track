class Baby {
  final int? id;
  final String name;
  final DateTime birthDate;
  final String gender; // 'M' for male, 'F' for female
  final String? photoPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Baby({
    this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.photoPath,
    required this.createdAt,
    this.updatedAt,
  });

  Baby copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Baby(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.millisecondsSinceEpoch,
      'gender': gender,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'] as int?,
      name: json['name'] as String,
      birthDate: DateTime.fromMillisecondsSinceEpoch(json['birth_date'] as int),
      gender: json['gender'] as String,
      photoPath: json['photo_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
    );
  }

  @override
  String toString() {
    return 'Baby{id: $id, name: $name, birthDate: $birthDate, gender: $gender, photoPath: $photoPath}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Baby &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          birthDate == other.birthDate &&
          gender == other.gender &&
          photoPath == other.photoPath;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ birthDate.hashCode ^ photoPath.hashCode;
}
