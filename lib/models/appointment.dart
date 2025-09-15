enum AppointmentStatus {
  scheduled('scheduled', 'Scheduled'),
  confirmed('confirmed', 'Confirmed'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  noShow('no_show', 'No Show');

  const AppointmentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static AppointmentStatus? fromString(String? value) {
    if (value == null) return null;
    for (AppointmentStatus status in AppointmentStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String? boothId;
  final DateTime scheduledDateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.boothId,
    required this.scheduledDateTime,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      doctorId: map['doctorId'] as String,
      boothId: map['boothId'] as String?,
      scheduledDateTime: DateTime.parse(map['scheduledDateTime'] as String),
      durationMinutes: map['durationMinutes'] as int? ?? 30,
      status:
          AppointmentStatus.fromString(map['status'] as String?) ??
          AppointmentStatus.scheduled,
      notes: map['notes'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'boothId': boothId,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.value,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? boothId,
    DateTime? scheduledDateTime,
    int? durationMinutes,
    AppointmentStatus? status,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      boothId: boothId ?? this.boothId,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Appointment(id: $id, patientId: $patientId, doctorId: $doctorId, scheduledDateTime: $scheduledDateTime, status: ${status.displayName})';
  }
}
