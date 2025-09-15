import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository<AppUser> {
  @override
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('users');

  @override
  AppUser fromMap(Map<String, dynamic> map) => AppUser.fromMap(map);

  @override
  Map<String, dynamic> toMap(AppUser user) => user.toMap();

  /// Get user by email
  Future<AppUser?> getByEmail(String email) async {
    try {
      final query = await collection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      throw RepositoryException('Failed to get user by email: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile(
    String userId, {
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    UserConsent? consent,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) updates['dob'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (consent != null) updates['consent'] = consent.toMap();

      await getDocRef(userId).update(updates);
    } catch (e) {
      throw RepositoryException(
        'Failed to update user profile: ${e.toString()}',
      );
    }
  }

  /// Check if user has completed profile setup
  Future<bool> hasCompleteProfile(String userId) async {
    try {
      final user = await getById(userId);
      if (user == null) return false;

      return user.name.isNotEmpty && user.consent.termsOfService;
    } catch (e) {
      throw RepositoryException(
        'Failed to check profile completion: ${e.toString()}',
      );
    }
  }

  /// Search users by name (for admin purposes)
  Future<List<AppUser>> searchByName(String name, {int limit = 10}) async {
    try {
      // Note: This is a simple implementation. For production, consider using
      // Algolia or similar service for full-text search
      final query = await collection
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: '${name}z')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException('Failed to search users: ${e.toString()}');
    }
  }

  /// Get users with specific consent settings
  Future<List<AppUser>> getUsersWithHealthDataConsent() async {
    try {
      final query = await collection
          .where('consent.healthData', isEqualTo: true)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get users with health data consent: ${e.toString()}',
      );
    }
  }

  /// Deactivate user account (soft delete)
  Future<void> deactivateAccount(String userId) async {
    try {
      await getDocRef(userId).update({
        'isActive': false,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to deactivate account: ${e.toString()}',
      );
    }
  }
}
