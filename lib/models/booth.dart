enum BoothStatus {
  available('available', 'Available'),
  occupied('occupied', 'Occupied'),
  maintenance('maintenance', 'Under Maintenance'),
  outOfOrder('out_of_order', 'Out of Order');

  const BoothStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static BoothStatus? fromString(String? value) {
    if (value == null) return null;
    for (BoothStatus status in BoothStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

class BoothLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;

  const BoothLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
  });

  factory BoothLocation.fromMap(Map<String, dynamic> map) {
    return BoothLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String,
      landmark: map['landmark'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'landmark': landmark,
    };
  }
}

class Booth {
  final String id;
  final String name;
  final String code; // QR code identifier
  final String? description;
  final BoothLocation location;
  final BoothStatus status;
  final List<String> availableServices;
  final List<String>? equipment;
  final Map<String, Map<String, String>>? operatingHours;
  final String? contactNumber;
  final String? currentUserId;
  final DateTime? lastUsedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booth({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.location,
    this.status = BoothStatus.available,
    this.availableServices = const [],
    this.equipment,
    this.operatingHours,
    this.contactNumber,
    this.currentUserId,
    this.lastUsedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booth.fromMap(Map<String, dynamic> map) {
    return Booth(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      location: BoothLocation.fromMap(map['location'] as Map<String, dynamic>),
      status:
          BoothStatus.fromString(map['status'] as String?) ??
          BoothStatus.available,
      availableServices: List<String>.from(
        map['availableServices'] as List? ?? [],
      ),
      equipment: map['equipment'] != null
          ? List<String>.from(map['equipment'] as List)
          : null,
      operatingHours: map['operatingHours'] != null
          ? Map<String, Map<String, String>>.from(
              (map['operatingHours'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  Map<String, String>.from(value as Map),
                ),
              ),
            )
          : null,
      contactNumber: map['contactNumber'] as String?,
      currentUserId: map['currentUserId'] as String?,
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'location': location.toMap(),
      'status': status.value,
      'availableServices': availableServices,
      'equipment': equipment,
      'operatingHours': operatingHours,
      'contactNumber': contactNumber,
      'currentUserId': currentUserId,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Booth copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    BoothLocation? location,
    BoothStatus? status,
    List<String>? availableServices,
    List<String>? equipment,
    Map<String, Map<String, String>>? operatingHours,
    String? contactNumber,
    String? currentUserId,
    DateTime? lastUsedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booth(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      availableServices: availableServices ?? this.availableServices,
      equipment: equipment ?? this.equipment,
      operatingHours: operatingHours ?? this.operatingHours,
      contactNumber: contactNumber ?? this.contactNumber,
      currentUserId: currentUserId ?? this.currentUserId,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAvailable => status == BoothStatus.available && isActive;
  bool get isOccupied => status == BoothStatus.occupied;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booth && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booth(id: $id, name: $name, code: $code, status: ${status.displayName})';
  }
}
