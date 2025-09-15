import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booth.dart';
import 'base_repository.dart';

class BoothRepository extends BaseRepository<Booth> {
  @override
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('booths');

  @override
  Booth fromMap(Map<String, dynamic> map) => Booth.fromMap(map);

  @override
  Map<String, dynamic> toMap(Booth booth) => booth.toMap();

  /// Get available booths
  Future<List<Booth>> getAvailableBooths({int limit = 50}) async {
    try {
      final query = await collection
          .where('status', isEqualTo: BoothStatus.available.value)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get available booths: ${e.toString()}',
      );
    }
  }

  /// Get booths by status
  Future<List<Booth>> getByStatus(BoothStatus status, {int limit = 50}) async {
    try {
      final query = await collection
          .where('status', isEqualTo: status.value)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get booths by status: ${e.toString()}',
      );
    }
  }

  /// Get booths by service type (instead of BoothType)
  Future<List<Booth>> getByService(String serviceName, {int limit = 50}) async {
    try {
      final query = await collection
          .where('availableServices', arrayContains: serviceName)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get booths by service: ${e.toString()}',
      );
    }
  }

  /// Get available booths by service
  Future<List<Booth>> getAvailableByService(
    String serviceName, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('availableServices', arrayContains: serviceName)
          .where('status', isEqualTo: BoothStatus.available.value)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get available booths by service: ${e.toString()}',
      );
    }
  }

  /// Reserve a booth
  Future<void> reserveBooth(
    String boothId, {
    String? reservedBy,
    String? notes,
  }) async {
    try {
      final booth = await getById(boothId);
      if (booth == null) {
        throw RepositoryException('Booth not found');
      }

      if (booth.status != BoothStatus.available) {
        throw RepositoryException('Booth is not available for reservation');
      }

      await getDocRef(boothId).update({
        'status': BoothStatus.occupied.value,
        'currentUserId': reservedBy,
        'reservationNotes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException('Failed to reserve booth: ${e.toString()}');
    }
  }

  /// Release a booth (make it available)
  Future<void> releaseBooth(String boothId) async {
    try {
      await getDocRef(boothId).update({
        'status': BoothStatus.available.value,
        'currentUserId': null,
        'reservationNotes': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException('Failed to release booth: ${e.toString()}');
    }
  }

  /// Mark booth as occupied
  Future<void> occupyBooth(String boothId, {String? occupiedBy}) async {
    try {
      await getDocRef(boothId).update({
        'status': BoothStatus.occupied.value,
        'currentUserId': occupiedBy,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException('Failed to occupy booth: ${e.toString()}');
    }
  }

  /// Mark booth as out of service
  Future<void> markOutOfService(String boothId, {String? reason}) async {
    try {
      await getDocRef(boothId).update({
        'status': BoothStatus.outOfOrder.value,
        'outOfServiceReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to mark booth out of service: ${e.toString()}',
      );
    }
  }

  /// Update booth equipment
  Future<void> updateServices(String boothId, List<String> services) async {
    try {
      await getDocRef(boothId).update({
        'availableServices': services,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw RepositoryException(
        'Failed to update booth services: ${e.toString()}',
      );
    }
  }

  /// Get booth utilization stats
  Future<Map<String, dynamic>> getUtilizationStats() async {
    try {
      final allBooths = await getAll();

      final stats = <String, int>{};
      for (final status in BoothStatus.values) {
        stats[status.value] = allBooths
            .where((booth) => booth.status == status)
            .length;
      }

      final total = allBooths.length;
      final available = stats[BoothStatus.available.value] ?? 0;
      final occupied = stats[BoothStatus.occupied.value] ?? 0;
      final maintenance = stats[BoothStatus.maintenance.value] ?? 0;
      final outOfOrder = stats[BoothStatus.outOfOrder.value] ?? 0;

      return {
        'total': total,
        'available': available,
        'occupied': occupied,
        'maintenance': maintenance,
        'outOfOrder': outOfOrder,
        'utilizationRate': total > 0 ? occupied / total : 0.0,
        'availabilityRate': total > 0 ? available / total : 0.0,
      };
    } catch (e) {
      throw RepositoryException(
        'Failed to get utilization stats: ${e.toString()}',
      );
    }
  }

  /// Get booths by location address
  Future<List<Booth>> getByLocationAddress(
    String address, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('location.address', isEqualTo: address)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get booths by location: ${e.toString()}',
      );
    }
  }

  /// Get available booths by location address
  Future<List<Booth>> getAvailableByLocationAddress(
    String address, {
    int limit = 50,
  }) async {
    try {
      final query = await collection
          .where('location.address', isEqualTo: address)
          .where('status', isEqualTo: BoothStatus.available.value)
          .orderBy('name')
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get available booths by location: ${e.toString()}',
      );
    }
  }

  /// Search booths by name
  Future<List<Booth>> searchByName(String name, {int limit = 20}) async {
    try {
      if (name.isEmpty) return [];

      final query = await collection
          .orderBy('name')
          .startAt([name])
          .endAt([name + '\uf8ff'])
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to search booths by name: ${e.toString()}',
      );
    }
  }

  /// Listen to booth status changes for real-time updates
  Stream<List<Booth>> watchByStatus(BoothStatus status) {
    return watchWhere(
      field: 'status',
      isEqualTo: status.value,
      orderBy: 'name',
    );
  }

  /// Listen to all booths for real-time updates
  Stream<List<Booth>> watchAllBooths() {
    return watchWhere(
      field: 'createdAt',
      isEqualTo: null,
      orderBy: 'name',
    ).handleError((error) {
      // If the above query fails, fall back to a simpler watch
      return collection
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => fromMap(doc.data())).toList(),
          );
    });
  }
}
