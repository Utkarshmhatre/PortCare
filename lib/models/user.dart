class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime profileCreatedAt;
  final UserConsent consent;
  final String role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    required this.profileCreatedAt,
    required this.consent,
    this.role = 'patient',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      dateOfBirth: map['dob'] != null
          ? DateTime.parse(map['dob'] as String)
          : null,
      gender: map['gender'] as String?,
      profileCreatedAt: DateTime.parse(map['profileCreatedAt'] as String),
      consent: UserConsent.fromMap(map['consent'] as Map<String, dynamic>),
      role: map['role'] as String? ?? 'patient',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profileCreatedAt': profileCreatedAt.toIso8601String(),
      'consent': consent.toMap(),
      'role': role,
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? profileCreatedAt,
    UserConsent? consent,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileCreatedAt: profileCreatedAt ?? this.profileCreatedAt,
      consent: consent ?? this.consent,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, role: $role)';
  }
}

class UserConsent {
  final bool termsOfService;
  final bool healthDataSharing;

  const UserConsent({
    required this.termsOfService,
    required this.healthDataSharing,
  });

  factory UserConsent.fromMap(Map<String, dynamic> map) {
    return UserConsent(
      termsOfService: map['tos'] as bool? ?? false,
      healthDataSharing: map['healthData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'tos': termsOfService, 'healthData': healthDataSharing};
  }

  UserConsent copyWith({bool? termsOfService, bool? healthDataSharing}) {
    return UserConsent(
      termsOfService: termsOfService ?? this.termsOfService,
      healthDataSharing: healthDataSharing ?? this.healthDataSharing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserConsent &&
        other.termsOfService == termsOfService &&
        other.healthDataSharing == healthDataSharing;
  }

  @override
  int get hashCode => termsOfService.hashCode ^ healthDataSharing.hashCode;
}

enum AuthStatus { initial, authenticated, unauthenticated, loading }

enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  const Gender(this.value, this.displayName);

  final String value;
  final String displayName;

  static Gender? fromString(String? value) {
    if (value == null) return null;
    for (Gender gender in Gender.values) {
      if (gender.value == value) return gender;
    }
    return null;
  }
}
