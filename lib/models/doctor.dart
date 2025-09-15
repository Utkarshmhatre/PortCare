enum DoctorSpecialization {
  generalPractice('general_practice', 'General Practice'),
  cardiology('cardiology', 'Cardiology'),
  dermatology('dermatology', 'Dermatology'),
  neurology('neurology', 'Neurology'),
  orthopedics('orthopedics', 'Orthopedics'),
  pediatrics('pediatrics', 'Pediatrics'),
  psychiatry('psychiatry', 'Psychiatry'),
  gynecology('gynecology', 'Gynecology'),
  ophthalmology('ophthalmology', 'Ophthalmology'),
  dentistry('dentistry', 'Dentistry');

  const DoctorSpecialization(this.value, this.displayName);

  final String value;
  final String displayName;

  static DoctorSpecialization? fromString(String? value) {
    if (value == null) return null;
    for (DoctorSpecialization spec in DoctorSpecialization.values) {
      if (spec.value == value) return spec;
    }
    return null;
  }
}

class Doctor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DoctorSpecialization specialization;
  final String licenseNumber;
  final int experienceYears;
  final String? profilePhotoUrl;
  final String? bio;
  final List<String> qualifications;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialization,
    required this.licenseNumber,
    required this.experienceYears,
    this.profilePhotoUrl,
    this.bio,
    this.qualifications = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      specialization:
          DoctorSpecialization.fromString(map['specialization'] as String?) ??
          DoctorSpecialization.generalPractice,
      licenseNumber: map['licenseNumber'] as String,
      experienceYears: map['experienceYears'] as int,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      bio: map['bio'] as String?,
      qualifications: List<String>.from(map['qualifications'] as List? ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization.value,
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'profilePhotoUrl': profilePhotoUrl,
      'bio': bio,
      'qualifications': qualifications,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DoctorSpecialization? specialization,
    String? licenseNumber,
    int? experienceYears,
    String? profilePhotoUrl,
    String? bio,
    List<String>? qualifications,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experienceYears: experienceYears ?? this.experienceYears,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      qualifications: qualifications ?? this.qualifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Doctor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Doctor(id: $id, name: $name, specialization: ${specialization.displayName}, rating: $rating)';
  }
}
