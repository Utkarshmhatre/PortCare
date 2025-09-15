import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';
import 'base_repository.dart';

class DocumentRepository extends BaseRepository<Document> {
  @override
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('documents');

  @override
  Document fromMap(Map<String, dynamic> map) => Document.fromMap(map);

  @override
  Map<String, dynamic> toMap(Document document) => document.toMap();

  /// Get documents for a specific user
  Future<List<Document>> getByUserId(String userId, {int limit = 50}) async {
    try {
      final query = await collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get user documents: ${e.toString()}',
      );
    }
  }

  /// Get documents by type
  Future<List<Document>> getByType(
    DocumentType type, {
    String? userId,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection.where(
        'type',
        isEqualTo: type.value,
      );

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get documents by type: ${e.toString()}',
      );
    }
  }

  /// Search documents by name
  Future<List<Document>> searchByName(
    String name, {
    String? userId,
    int limit = 20,
  }) async {
    try {
      if (name.isEmpty) return [];

      Query<Map<String, dynamic>> query = collection
          .orderBy('name')
          .startAt([name])
          .endAt([name + '\uf8ff']);

      if (userId != null) {
        // Note: This requires a composite index in Firestore
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query.limit(limit).get();
      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to search documents by name: ${e.toString()}',
      );
    }
  }

  /// Get encrypted documents
  Future<List<Document>> getEncryptedDocuments({
    String? userId,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection.where(
        'isEncrypted',
        isEqualTo: true,
      );

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get encrypted documents: ${e.toString()}',
      );
    }
  }

  /// Update document metadata
  Future<void> updateMetadata(
    String documentId, {
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (tags != null) updates['tags'] = tags;

      await getDocRef(documentId).update(updates);
    } catch (e) {
      throw RepositoryException(
        'Failed to update document metadata: ${e.toString()}',
      );
    }
  }

  /// Get document statistics for a user
  Future<Map<String, dynamic>> getUserDocumentStats(String userId) async {
    try {
      final userDocs = await getByUserId(userId);

      final stats = <String, int>{};
      for (final type in DocumentType.values) {
        stats[type.value] = userDocs.where((doc) => doc.type == type).length;
      }

      final totalSize = userDocs.fold<double>(
        0.0,
        (sum, doc) => sum + doc.fileSizeBytes.toDouble(),
      );
      final encryptedCount = userDocs.where((doc) => doc.isEncrypted).length;

      return {
        'total': userDocs.length,
        'totalSizeBytes': totalSize.round(),
        'encrypted': encryptedCount,
        'byType': stats,
      };
    } catch (e) {
      throw RepositoryException(
        'Failed to get user document stats: ${e.toString()}',
      );
    }
  }

  /// Get documents by date range
  Future<List<Document>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get documents by date range: ${e.toString()}',
      );
    }
  }

  /// Get documents by tags
  Future<List<Document>> getByTag(
    String tag, {
    String? userId,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection.where(
        'tags',
        arrayContains: tag,
      );

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get documents by tag: ${e.toString()}',
      );
    }
  }

  /// Listen to user documents for real-time updates
  Stream<List<Document>> watchUserDocuments(String userId) {
    return watchWhere(
      field: 'userId',
      isEqualTo: userId,
      orderBy: 'createdAt',
      descending: true,
    );
  }

  /// Get recent documents
  Future<List<Document>> getRecentDocuments({
    String? userId,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection;

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final result = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw RepositoryException(
        'Failed to get recent documents: ${e.toString()}',
      );
    }
  }
}
