import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import 'base_repository.dart';

class AppointmentRepository extends BaseRepository<Appointment> {
  @override
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('appointments');

  @override
  Appointment fromMap(Map<String, dynamic> map) => Appointment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Appointment appointment) => appointment.toMap();

  /// Get appointments for a specific patient
  Future<List<Appointment>> getByPatientId(
    String patientId, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('patientId', isEqualTo: patientId)
          .orderBy('scheduledDateTime', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get patient appointments: ${e.toString()}',
      );
    }
  }

  /// Get appointments for a specific doctor
  Future<List<Appointment>> getByDoctorId(
    String doctorId, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('scheduledDateTime', descending: false)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get doctor appointments: ${e.toString()}',
      );
    }
  }

  /// Get upcoming appointments for a patient
  Future<List<Appointment>> getUpcomingByPatientId(String patientId) async {
    try {
      final now = DateTime.now();
      final query = await collection
          .where('patientId', isEqualTo: patientId)
          .where('scheduledDateTime', isGreaterThan: now.toIso8601String())
          .where(
            'status',
            whereIn: [
              AppointmentStatus.scheduled.value,
              AppointmentStatus.confirmed.value,
            ],
          )
          .orderBy('scheduledDateTime', descending: false)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get upcoming appointments: ${e.toString()}',
      );
    }
  }

  /// Get appointments for a specific date range
  Future<List<Appointment>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? patientId,
    String? doctorId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection
          .where(
            'scheduledDateTime',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where(
            'scheduledDateTime',
            isLessThanOrEqualTo: endDate.toIso8601String(),
          );

      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      }

      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      final result = await query.orderBy('scheduledDateTime').get();
      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get appointments by date range: ${e.toString()}',
      );
    }
  }

  /// Book a new appointment
  Future<String> bookAppointment({
    required String patientId,
    required String doctorId,
    required DateTime scheduledDateTime,
    int durationMinutes = 30,
    String? boothId,
    String? notes,
  }) async {
    try {
      // Check for conflicts
      final conflicts = await _checkForConflicts(
        doctorId: doctorId,
        scheduledDateTime: scheduledDateTime,
        durationMinutes: durationMinutes,
      );

      if (conflicts.isNotEmpty) {
        throw RepositoryException(
          'Doctor is not available at the requested time',
        );
      }

      final appointmentId = collection.doc().id;
      final now = DateTime.now();

      final appointment = Appointment(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        boothId: boothId,
        scheduledDateTime: scheduledDateTime,
        durationMinutes: durationMinutes,
        status: AppointmentStatus.scheduled,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await create(appointmentId, appointment);
      return appointmentId;
    } catch (e) {
      throw RepositoryException('Failed to book appointment: ${e.toString()}');
    }
  }

  /// Update appointment status
  Future<void> updateStatus(
    String appointmentId,
    AppointmentStatus newStatus, {
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (reason != null && newStatus == AppointmentStatus.cancelled) {
        updates['cancellationReason'] = reason;
      }

      await getDocRef(appointmentId).update(updates);
    } catch (e) {
      throw RepositoryException(
        'Failed to update appointment status: ${e.toString()}',
      );
    }
  }

  /// Reschedule appointment
  Future<void> reschedule({
    required String appointmentId,
    required DateTime newDateTime,
    int? newDurationMinutes,
  }) async {
    try {
      final appointment = await getById(appointmentId);
      if (appointment == null) {
        throw RepositoryException('Appointment not found');
      }

      // Check for conflicts at new time
      final conflicts = await _checkForConflicts(
        doctorId: appointment.doctorId,
        scheduledDateTime: newDateTime,
        durationMinutes: newDurationMinutes ?? appointment.durationMinutes,
        excludeAppointmentId: appointmentId,
      );

      if (conflicts.isNotEmpty) {
        throw RepositoryException(
          'Doctor is not available at the new requested time',
        );
      }

      await getDocRef(appointmentId).update({
        'scheduledDateTime': newDateTime.toIso8601String(),
        if (newDurationMinutes != null) 'durationMinutes': newDurationMinutes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to reschedule appointment: ${e.toString()}',
      );
    }
  }

  /// Get appointment statistics for a patient
  Future<Map<String, int>> getPatientStats(String patientId) async {
    try {
      final appointments = await getByPatientId(patientId);

      final stats = <String, int>{};
      for (final status in AppointmentStatus.values) {
        stats[status.value] = appointments
            .where((apt) => apt.status == status)
            .length;
      }

      return stats;
    } catch (e) {
      throw RepositoryException('Failed to get patient stats: ${e.toString()}');
    }
  }

  /// Listen to appointment changes for real-time updates
  Stream<List<Appointment>> watchByPatientId(String patientId) {
    return watchWhere(
      field: 'patientId',
      isEqualTo: patientId,
      orderBy: 'scheduledDateTime',
      descending: true,
    );
  }

  /// Private method to check for scheduling conflicts
  Future<List<Appointment>> _checkForConflicts({
    required String doctorId,
    required DateTime scheduledDateTime,
    required int durationMinutes,
    String? excludeAppointmentId,
  }) async {
    final startTime = scheduledDateTime;
    final endTime = scheduledDateTime.add(Duration(minutes: durationMinutes));

    // Get appointments for the doctor on the same day
    final dayStart = DateTime(startTime.year, startTime.month, startTime.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayAppointments = await getByDateRange(
      startDate: dayStart,
      endDate: dayEnd,
      doctorId: doctorId,
    );

    // Filter out cancelled appointments and the appointment being rescheduled
    final activeAppointments = dayAppointments
        .where(
          (apt) =>
              apt.status != AppointmentStatus.cancelled &&
              apt.status != AppointmentStatus.noShow &&
              apt.id != excludeAppointmentId,
        )
        .toList();

    // Check for time conflicts
    final conflicts = activeAppointments.where((apt) {
      final aptStart = apt.scheduledDateTime;
      final aptEnd = aptStart.add(Duration(minutes: apt.durationMinutes));

      // Check if times overlap
      return (startTime.isBefore(aptEnd) && endTime.isAfter(aptStart));
    }).toList();

    return conflicts;
  }
}
