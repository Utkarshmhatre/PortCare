import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import 'base_repository.dart';

class DoctorRepository extends BaseRepository<Doctor> {
  @override
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('doctors');

  @override
  Doctor fromMap(Map<String, dynamic> map) => Doctor.fromMap(map);

  @override
  Map<String, dynamic> toMap(Doctor doctor) => doctor.toMap();

  /// Search doctors by name
  Future<List<Doctor>> searchByName(String name, {int limit = 20}) async {
    try {
      if (name.isEmpty) return [];

      // Simple text search by name (for more advanced search, consider using Algolia or similar)
      final query = await collection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([name.toLowerCase()])
          .endAt([name.toLowerCase() + '\uf8ff'])
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to search doctors by name: ${e.toString()}',
      );
    }
  }

  /// Get doctors by specialization
  Future<List<Doctor>> getBySpecialization(
    DoctorSpecialization specialization, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('specialization', isEqualTo: specialization.value)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get doctors by specialization: ${e.toString()}',
      );
    }
  }

  /// Get doctors by multiple specializations
  Future<List<Doctor>> getBySpecializations(
    List<DoctorSpecialization> specializations, {
    int limit = 50,
  }) async {
    try {
      if (specializations.isEmpty) return [];

      final specializationValues = specializations.map((s) => s.value).toList();
      final query = await collection
          .where('specialization', whereIn: specializationValues)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get doctors by specializations: ${e.toString()}',
      );
    }
  }

  /// Get available doctors (simplified - just returns active doctors)
  Future<List<Doctor>> getAvailableDoctors({
    DoctorSpecialization? specialization,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection.where(
        'isActive',
        isEqualTo: true,
      );

      if (specialization != null) {
        query = query.where('specialization', isEqualTo: specialization.value);
      }

      final result = await query
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get available doctors: ${e.toString()}',
      );
    }
  }

  /// Get top-rated doctors
  Future<List<Doctor>> getTopRated({int limit = 10}) async {
    try {
      final query = await collection
          .where('isActive', isEqualTo: true)
          .where('rating', isGreaterThanOrEqualTo: 4.0)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get top-rated doctors: ${e.toString()}',
      );
    }
  }

  /// Get doctors with experience filter
  Future<List<Doctor>> getByExperience({
    required int minYears,
    int? maxYears,
    DoctorSpecialization? specialization,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection
          .where('isActive', isEqualTo: true)
          .where('experienceYears', isGreaterThanOrEqualTo: minYears);

      if (maxYears != null) {
        query = query.where('experienceYears', isLessThanOrEqualTo: maxYears);
      }

      if (specialization != null) {
        query = query.where('specialization', isEqualTo: specialization.value);
      }

      final result = await query
          .orderBy('experienceYears', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get doctors by experience: ${e.toString()}',
      );
    }
  }

  /// Update doctor rating
  Future<void> updateRating(String doctorId, double newRating) async {
    try {
      final doctor = await getById(doctorId);
      if (doctor == null) {
        throw RepositoryException('Doctor not found');
      }

      final totalRatings = doctor.reviewCount + 1;
      final totalScore = (doctor.rating * doctor.reviewCount) + newRating;
      final newAverageRating = totalScore / totalRatings;

      await getDocRef(doctorId).update({
        'rating': double.parse(newAverageRating.toStringAsFixed(2)),
        'reviewCount': totalRatings,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to update doctor rating: ${e.toString()}',
      );
    }
  }

  /// Toggle doctor active status
  Future<void> toggleActiveStatus(String doctorId) async {
    try {
      final doctor = await getById(doctorId);
      if (doctor == null) {
        throw RepositoryException('Doctor not found');
      }

      await getDocRef(doctorId).update({
        'isActive': !doctor.isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to toggle doctor active status: ${e.toString()}',
      );
    }
  }

  /// Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    try {
      final doctor = await getById(doctorId);
      if (doctor == null) {
        throw RepositoryException('Doctor not found');
      }

      return {
        'rating': doctor.rating,
        'reviewCount': doctor.reviewCount,
        'experienceYears': doctor.experienceYears,
        'specialization': doctor.specialization.value,
        'isActive': doctor.isActive,
      };
    } catch (e) {
      throw RepositoryException('Failed to get doctor stats: ${e.toString()}');
    }
  }

  /// Listen to active doctors for real-time updates
  Stream<List<Doctor>> watchActiveDoctors({int limit = 50}) {
    return watchWhere(
      field: 'isActive',
      isEqualTo: true,
      orderBy: 'rating',
      descending: true,
      limit: limit,
    );
  }
}
