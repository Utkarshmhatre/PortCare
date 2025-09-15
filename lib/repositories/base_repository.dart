import 'package:cloud_firestore/cloud_firestore.dart';

/// Base repository class providing common Firestore operations
/// All repository classes should extend this for consistent error handling and data access patterns
abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for this repository
  CollectionReference<Map<String, dynamic>> get collection;

  /// Convert from Firestore document to model
  T fromMap(Map<String, dynamic> map);

  /// Convert from model to Firestore document
  Map<String, dynamic> toMap(T item);

  /// Get document reference by ID
  DocumentReference<Map<String, dynamic>> getDocRef(String id) {
    return collection.doc(id);
  }

  /// Get a single document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await getDocRef(id).get();
      if (doc.exists) {
        return fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw RepositoryException('Failed to get document: ${e.toString()}');
    }
  }

  /// Get multiple documents by IDs
  Future<List<T>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Firestore 'in' queries are limited to 10 items
      if (ids.length <= 10) {
        final query = await collection
            .where(FieldPath.documentId, whereIn: ids)
            .get();
        return query.docs
            .where((doc) => doc.exists)
            .map((doc) => fromMap(doc.data()))
            .toList();
      } else {
        // Split into chunks of 10
        final List<T> results = [];
        for (int i = 0; i < ids.length; i += 10) {
          final chunk = ids.sublist(
            i,
            i + 10 > ids.length ? ids.length : i + 10,
          );
          final chunkResults = await getByIds(chunk);
          results.addAll(chunkResults);
        }
        return results;
      }
    } catch (e) {
      throw RepositoryException('Failed to get documents: ${e.toString()}');
    }
  }

  /// Get all documents (use with caution)
  Future<List<T>> getAll() async {
    try {
      final query = await collection.get();
      return query.docs
          .where((doc) => doc.exists)
          .map((doc) => fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to get all documents: ${e.toString()}');
    }
  }

  /// Create a new document
  Future<void> create(String id, T item) async {
    try {
      await getDocRef(id).set(toMap(item));
    } catch (e) {
      throw RepositoryException('Failed to create document: ${e.toString()}');
    }
  }

  /// Update an existing document
  Future<void> update(String id, T item) async {
    try {
      await getDocRef(id).update(toMap(item));
    } catch (e) {
      throw RepositoryException('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete(String id) async {
    try {
      await getDocRef(id).delete();
    } catch (e) {
      throw RepositoryException('Failed to delete document: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists(String id) async {
    try {
      final doc = await getDocRef(id).get();
      return doc.exists;
    } catch (e) {
      throw RepositoryException(
        'Failed to check document existence: ${e.toString()}',
      );
    }
  }

  /// Listen to document changes
  Stream<T?> watchById(String id) {
    return getDocRef(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  /// Listen to collection changes with query
  Stream<List<T>> watchWhere({
    Object? field,
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = collection;

    if (field != null) {
      query = query.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      );
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => fromMap(doc.data()))
          .toList();
    });
  }

  /// Batch operations
  WriteBatch get batch => _firestore.batch();

  /// Execute batch operations
  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to commit batch: ${e.toString()}');
    }
  }

  /// Transaction operations
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      throw RepositoryException('Failed to run transaction: ${e.toString()}');
    }
  }
}

/// Custom exception for repository operations
class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}
