/// 犬情報のモデル
class DogModel {
  final String? id;
  final String userId;
  final String name;
  final String? breed;
  final DogSize? size;
  final DateTime? birthDate;
  final double? weight; // kg
  final DogGender? gender;
  final String? photoUrl;
  final String? rabiesVaccinePhotoUrl;
  final DateTime? rabiesVaccineDate;
  final String? mixedVaccinePhotoUrl;
  final DateTime? mixedVaccineDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogModel({
    this.id,
    required this.userId,
    required this.name,
    this.breed,
    this.size,
    this.birthDate,
    this.weight,
    this.gender,
    this.photoUrl,
    this.rabiesVaccinePhotoUrl,
    this.rabiesVaccineDate,
    this.mixedVaccinePhotoUrl,
    this.mixedVaccineDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 年齢を計算
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// 年齢を表示用にフォーマット
  String get ageDisplay {
    final calculatedAge = age;
    if (calculatedAge == null) return '不明';
    if (calculatedAge == 0) {
      final months = DateTime.now().difference(birthDate!).inDays ~/ 30;
      return '$monthsヶ月';
    }
    return '$calculatedAge歳';
  }

  /// 体重を表示用にフォーマット
  String get weightDisplay {
    if (weight == null) return '不明';
    return '${weight!.toStringAsFixed(1)}kg';
  }

  /// サイズを表示用にフォーマット
  String get sizeDisplay {
    if (size == null) return '不明';
    return size!.displayName;
  }

  /// JSONからモデルを作成
  factory DogModel.fromJson(Map<String, dynamic> json) {
    return DogModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String?,
      size: json['size'] != null ? DogSizeExtension.fromString(json['size'] as String) : null,
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date'] as String) : null,
      weight: (json['weight'] as num?)?.toDouble(),
      gender: json['gender'] != null ? DogGenderExtension.fromString(json['gender'] as String) : null,
      photoUrl: json['photo_url'] as String?,
      rabiesVaccinePhotoUrl: json['rabies_vaccine_photo_url'] as String?,
      rabiesVaccineDate: json['rabies_vaccine_date'] != null ? DateTime.parse(json['rabies_vaccine_date'] as String) : null,
      mixedVaccinePhotoUrl: json['mixed_vaccine_photo_url'] as String?,
      mixedVaccineDate: json['mixed_vaccine_date'] != null ? DateTime.parse(json['mixed_vaccine_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'breed': breed,
      'size': size?.value,
      'birth_date': birthDate?.toIso8601String().split('T')[0], // YYYY-MM-DD形式
      'weight': weight,
      'gender': gender?.value,
      'photo_url': photoUrl,
      'rabies_vaccine_photo_url': rabiesVaccinePhotoUrl,
      'rabies_vaccine_date': rabiesVaccineDate?.toIso8601String().split('T')[0],
      'mixed_vaccine_photo_url': mixedVaccinePhotoUrl,
      'mixed_vaccine_date': mixedVaccineDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Supabase insert用のJSONに変換（idを除外）
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      if (breed != null) 'breed': breed,
      if (size != null) 'size': size!.value,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T')[0],
      if (weight != null) 'weight': weight,
      if (gender != null) 'gender': gender!.value,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (rabiesVaccinePhotoUrl != null) 'rabies_vaccine_photo_url': rabiesVaccinePhotoUrl,
      if (rabiesVaccineDate != null) 'rabies_vaccine_date': rabiesVaccineDate!.toIso8601String().split('T')[0],
      if (mixedVaccinePhotoUrl != null) 'mixed_vaccine_photo_url': mixedVaccinePhotoUrl,
      if (mixedVaccineDate != null) 'mixed_vaccine_date': mixedVaccineDate!.toIso8601String().split('T')[0],
    };
  }

  /// コピーを作成
  DogModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? breed,
    DogSize? size,
    DateTime? birthDate,
    double? weight,
    DogGender? gender,
    String? photoUrl,
    String? rabiesVaccinePhotoUrl,
    DateTime? rabiesVaccineDate,
    String? mixedVaccinePhotoUrl,
    DateTime? mixedVaccineDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      size: size ?? this.size,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      rabiesVaccinePhotoUrl: rabiesVaccinePhotoUrl ?? this.rabiesVaccinePhotoUrl,
      rabiesVaccineDate: rabiesVaccineDate ?? this.rabiesVaccineDate,
      mixedVaccinePhotoUrl: mixedVaccinePhotoUrl ?? this.mixedVaccinePhotoUrl,
      mixedVaccineDate: mixedVaccineDate ?? this.mixedVaccineDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 犬の性別
enum DogGender {
  male,
  female,
  unknown,
}

extension DogGenderExtension on DogGender {
  String get value {
    switch (this) {
      case DogGender.male:
        return 'male';
      case DogGender.female:
        return 'female';
      case DogGender.unknown:
        return 'unknown';
    }
  }

  String get displayName {
    switch (this) {
      case DogGender.male:
        return 'オス';
      case DogGender.female:
        return 'メス';
      case DogGender.unknown:
        return '不明';
    }
  }

  static DogGender? fromString(String value) {
    switch (value) {
      case 'male':
        return DogGender.male;
      case 'female':
        return DogGender.female;
      case 'unknown':
        return DogGender.unknown;
      default:
        return null;
    }
  }
}

/// 犬のサイズ分類
enum DogSize {
  small,  // 小型犬
  medium, // 中型犬
  large,  // 大型犬
}

extension DogSizeExtension on DogSize {
  String get value {
    switch (this) {
      case DogSize.small:
        return 'small';
      case DogSize.medium:
        return 'medium';
      case DogSize.large:
        return 'large';
    }
  }

  String get displayName {
    switch (this) {
      case DogSize.small:
        return '小型犬';
      case DogSize.medium:
        return '中型犬';
      case DogSize.large:
        return '大型犬';
    }
  }

  static DogSize? fromString(String value) {
    switch (value) {
      case 'small':
        return DogSize.small;
      case 'medium':
        return DogSize.medium;
      case 'large':
        return DogSize.large;
      default:
        return null;
    }
  }
}
