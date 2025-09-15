import 'package:cloud_firestore/cloud_firestore.dart';

/// Health metric types supported by the system
enum HealthMetricType {
  heartRate('heart_rate', 'Heart Rate', 'bpm'),
  steps('steps', 'Steps', 'steps'),
  weight('weight', 'Weight', 'kg'),
  bloodPressureSystolic('bp_systolic', 'Blood Pressure (Systolic)', 'mmHg'),
  bloodPressureDiastolic('bp_diastolic', 'Blood Pressure (Diastolic)', 'mmHg'),
  temperature('temperature', 'Temperature', '°C'),
  calories('calories', 'Calories', 'kcal'),
  distance('distance', 'Distance', 'km'),
  activeMinutes('active_minutes', 'Active Minutes', 'min');

  const HealthMetricType(this.value, this.displayName, this.unit);

  final String value;
  final String displayName;
  final String unit;

  static HealthMetricType? fromString(String value) {
    for (HealthMetricType type in HealthMetricType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Source of health data
enum HealthDataSource {
  phone('phone', 'Phone Sensor'),
  wearable('wearable', 'Wearable Device'),
  booth('booth', 'Medical Booth'),
  manual('manual', 'Manual Entry');

  const HealthDataSource(this.value, this.displayName);

  final String value;
  final String displayName;

  static HealthDataSource? fromString(String value) {
    for (HealthDataSource source in HealthDataSource.values) {
      if (source.value == value) return source;
    }
    return null;
  }
}

/// Individual health metric data point
class HealthMetric {
  final String id;
  final String userId;
  final HealthMetricType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final HealthDataSource source;
  final String? appointmentId;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const HealthMetric({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
    this.appointmentId,
    this.notes,
    this.metadata,
  });

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: HealthMetricType.fromString(map['type'] as String)!,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      source: HealthDataSource.fromString(map['source'] as String)!,
      appointmentId: map['appointmentId'] as String?,
      notes: map['notes'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'value': value,
      'unit': unit,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'source': source.value,
      'appointmentId': appointmentId,
      'notes': notes,
      'metadata': metadata,
    };
  }

  HealthMetric copyWith({
    String? id,
    String? userId,
    HealthMetricType? type,
    double? value,
    String? unit,
    DateTime? recordedAt,
    HealthDataSource? source,
    String? appointmentId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
      appointmentId: appointmentId ?? this.appointmentId,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthMetric && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HealthMetric(id: $id, type: ${type.displayName}, value: $value $unit, source: ${source.displayName})';
  }
}

/// Consultation record with prescriptions
class Consultation {
  final String id;
  final String userId;
  final String appointmentId;
  final String doctorName;
  final DateTime consultationDate;
  final List<Prescription> prescriptions;
  final String? diagnosis;
  final String? notes;
  final DateTime? followUpDate;
  final Map<String, dynamic>? metadata;

  const Consultation({
    required this.id,
    required this.userId,
    required this.appointmentId,
    required this.doctorName,
    required this.consultationDate,
    required this.prescriptions,
    this.diagnosis,
    this.notes,
    this.followUpDate,
    this.metadata,
  });

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'] as String,
      userId: map['userId'] as String,
      appointmentId: map['appointmentId'] as String,
      doctorName: map['doctorName'] as String,
      consultationDate: (map['consultationDate'] as Timestamp).toDate(),
      prescriptions:
          (map['prescriptions'] as List<dynamic>?)
              ?.map((p) => Prescription.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      followUpDate: map['followUpDate'] != null
          ? (map['followUpDate'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'appointmentId': appointmentId,
      'doctorName': doctorName,
      'consultationDate': Timestamp.fromDate(consultationDate),
      'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
      'diagnosis': diagnosis,
      'notes': notes,
      'followUpDate': followUpDate != null
          ? Timestamp.fromDate(followUpDate!)
          : null,
      'metadata': metadata,
    };
  }

  Consultation copyWith({
    String? id,
    String? userId,
    String? appointmentId,
    String? doctorName,
    DateTime? consultationDate,
    List<Prescription>? prescriptions,
    String? diagnosis,
    String? notes,
    DateTime? followUpDate,
    Map<String, dynamic>? metadata,
  }) {
    return Consultation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorName: doctorName ?? this.doctorName,
      consultationDate: consultationDate ?? this.consultationDate,
      prescriptions: prescriptions ?? this.prescriptions,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      followUpDate: followUpDate ?? this.followUpDate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Consultation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Consultation(id: $id, doctor: $doctorName, date: $consultationDate)';
  }
}

/// Prescription information
class Prescription {
  final String medication;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String? instructions;
  final DateTime prescribedAt;

  const Prescription({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    required this.prescribedAt,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      medication: map['medication'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      duration: map['duration'] as int,
      instructions: map['instructions'] as String?,
      prescribedAt: (map['prescribedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medication': medication,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'prescribedAt': Timestamp.fromDate(prescribedAt),
    };
  }

  @override
  String toString() {
    return '$medication $dosage - $frequency for $duration days';
  }
}

/// Health goal for tracking progress
class HealthGoal {
  final String id;
  final String userId;
  final HealthMetricType metricType;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;

  const HealthGoal({
    required this.id,
    required this.userId,
    required this.metricType,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.title,
    this.description,
    this.metadata,
  });

  factory HealthGoal.fromMap(Map<String, dynamic> map) {
    return HealthGoal(
      id: map['id'] as String,
      userId: map['userId'] as String,
      metricType: HealthMetricType.fromString(map['metricType'] as String)!,
      targetValue: (map['targetValue'] as num).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      title: map['title'] as String?,
      description: map['description'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'metricType': metricType.value,
      'targetValue': targetValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'title': title,
      'description': description,
      'metadata': metadata,
    };
  }

  HealthGoal copyWith({
    String? id,
    String? userId,
    HealthMetricType? metricType,
    double? targetValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      metricType: metricType ?? this.metricType,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      title: title ?? this.title,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HealthGoal(id: $id, type: ${metricType.displayName}, target: $targetValue)';
  }
}

/// Health metrics summary for dashboard
class HealthMetricsSummary {
  final int totalMetrics;
  final DateTime lastUpdated;
  final Map<HealthMetricType, double> latestValues;
  final Map<HealthMetricType, double> weeklyAverages;
  final List<HealthGoal> activeGoals;

  const HealthMetricsSummary({
    required this.totalMetrics,
    required this.lastUpdated,
    required this.latestValues,
    required this.weeklyAverages,
    required this.activeGoals,
  });

  factory HealthMetricsSummary.fromMap(Map<String, dynamic> map) {
    return HealthMetricsSummary(
      totalMetrics: map['totalMetrics'] as int,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      latestValues: (map['latestValues'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          HealthMetricType.fromString(key)!,
          (value as num).toDouble(),
        ),
      ),
      weeklyAverages: (map['weeklyAverages'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          HealthMetricType.fromString(key)!,
          (value as num).toDouble(),
        ),
      ),
      activeGoals:
          (map['activeGoals'] as List<dynamic>?)
              ?.map((g) => HealthGoal.fromMap(g as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMetrics': totalMetrics,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'latestValues': latestValues.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'weeklyAverages': weeklyAverages.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'activeGoals': activeGoals.map((g) => g.toMap()).toList(),
    };
  }
}
