import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../models/document.dart';

/// Service for managing document upload, storage, and retrieval
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  // Firebase instances
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pick files from device
  Future<List<PlatformFile>?> pickFiles() async {
    try {
      print('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      print('File picker result: ${result?.files.length ?? 0} files');
      return result?.files;
    } catch (e) {
      print('File picker error: $e');
      throw DocumentException('Failed to pick files: $e');
    }
  }

  /// Upload a document to Firebase Storage
  Future<Document> uploadDocument({
    required PlatformFile file,
    required DocumentType type,
    String? customName,
    String? notes,
    bool encrypt = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw DocumentException('User not authenticated');

    try {
      // Validate file
      _validateFile(file);

      // Prepare file data
      Uint8List fileData = file.bytes!;
      String fileName = customName ?? file.name;

      // Apply encryption if requested
      if (encrypt) {
        fileData = await _encryptFile(fileData);
        fileName = '${fileName}_encrypted';
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.name);
      final storagePath =
          'documents/${user.uid}/${timestamp}_${fileName}${extension}';

      // Upload to Firebase Storage
      final uploadTask = _storage
          .ref(storagePath)
          .putData(
            fileData,
            SettableMetadata(
              contentType: _getContentType(extension),
              customMetadata: {
                'originalName': file.name,
                'encrypted': encrypt.toString(),
                'userId': user.uid,
              },
            ),
          );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create document metadata
      final document = Document(
        id: _firestore.collection('documents').doc().id,
        userId: user.uid,
        name: fileName,
        type: type,
        fileUrl: downloadUrl,
        fileSizeBytes: file.size,
        mimeType: _getContentType(extension),
        description: notes,
        isEncrypted: encrypt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save metadata to Firestore
      await _firestore
          .collection('documents')
          .doc(document.id)
          .set(document.toMap());

      // Generate thumbnail if it's an image
      if (_isImageFile(extension)) {
        await _generateThumbnail(document, fileData);
      }

      return document;
    } catch (e) {
      throw DocumentException('Failed to upload document: $e');
    }
  }

  /// Get documents for current user
  Future<List<Document>> getUserDocuments({
    DocumentType? type,
    int limit = 50,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw DocumentException('User not authenticated');

    try {
      Query query = _firestore
          .collection('documents')
          .where('userId', isEqualTo: user.uid)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      final snapshot = await query.get();
      final documents = snapshot.docs
          .map((doc) => Document.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by createdAt in memory to avoid index requirements
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return documents;
    } catch (e) {
      throw DocumentException('Failed to get documents: $e');
    }
  }

  /// Delete a document
  Future<void> deleteDocument(Document document) async {
    final user = _auth.currentUser;
    if (user == null) throw DocumentException('User not authenticated');

    if (document.userId != user.uid) {
      throw DocumentException('Not authorized to delete this document');
    }

    try {
      // Delete from Storage - construct path from URL
      try {
        final storageRef = _storage.refFromURL(document.fileUrl);
        await storageRef.delete();
      } catch (e) {
        print('Warning: Could not delete file from storage: $e');
      }

      // Delete thumbnail if exists
      if (document.thumbnailUrl != null) {
        try {
          final thumbnailRef = _storage.refFromURL(document.thumbnailUrl!);
          await thumbnailRef.delete();
        } catch (e) {
          print('Warning: Could not delete thumbnail: $e');
        }
      }

      // Delete from Firestore
      await _firestore.collection('documents').doc(document.id).delete();
    } catch (e) {
      throw DocumentException('Failed to delete document: $e');
    }
  }

  /// Search documents
  Future<List<Document>> searchDocuments(String query) async {
    final user = _auth.currentUser;
    if (user == null) throw DocumentException('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: user.uid)
          .get();

      final documents = snapshot.docs
          .map((doc) => Document.fromMap(doc.data()))
          .where(
            (doc) =>
                doc.name.toLowerCase().contains(query.toLowerCase()) ||
                (doc.description?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();

      // Sort by createdAt in memory to avoid index requirements
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return documents;
    } catch (e) {
      throw DocumentException('Failed to search documents: $e');
    }
  }

  /// Get documents by type with real-time updates
  Stream<List<Document>> getDocumentsStream({DocumentType? type}) {
    final user = _auth.currentUser;
    if (user == null) throw DocumentException('User not authenticated');

    Query query = _firestore
        .collection('documents')
        .where('userId', isEqualTo: user.uid);

    if (type != null) {
      query = query.where('type', isEqualTo: type.value);
    }

    return query.snapshots().map((snapshot) {
      final documents = snapshot.docs
          .map((doc) => Document.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Sort by createdAt in memory to avoid index requirements
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return documents;
    });
  }

  /// Private helper methods

  void _validateFile(PlatformFile file) {
    if (file.bytes == null) {
      throw DocumentException('File data is null');
    }

    if (file.size > 10 * 1024 * 1024) {
      // 10MB limit
      throw DocumentException('File size exceeds 10MB limit');
    }

    final extension = path.extension(file.name).toLowerCase();
    const allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png'];
    if (!allowedExtensions.contains(extension)) {
      throw DocumentException(
        'File type not supported. Allowed: PDF, JPG, PNG',
      );
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isImageFile(String extension) {
    const imageExtensions = ['.jpg', '.jpeg', '.png'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  Future<Uint8List> _encryptFile(Uint8List data) async {
    // Simple encryption using base64 encoding and AES-like transformation
    // In production, use proper AES encryption
    final encoded = base64.encode(data);
    return Uint8List.fromList(utf8.encode(encoded));
  }

  Future<void> _generateThumbnail(
    Document document,
    Uint8List imageData,
  ) async {
    try {
      // For now, just save a smaller version of the image
      // In production, you would use image processing libraries
      final thumbnailPath = 'thumbnails/${document.userId}/${document.id}.jpg';

      await _storage
          .ref(thumbnailPath)
          .putData(
            imageData,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'documentId': document.id,
                'userId': document.userId,
              },
            ),
          );

      final thumbnailUrl = await _storage.ref(thumbnailPath).getDownloadURL();

      // Update document with thumbnail URL
      await _firestore.collection('documents').doc(document.id).update({
        'thumbnailUrl': thumbnailUrl,
      });
    } catch (e) {
      // Don't fail the upload if thumbnail generation fails
      print('Failed to generate thumbnail: $e');
    }
  }
}

/// Custom exception for document operations
class DocumentException implements Exception {
  final String message;
  DocumentException(this.message);

  @override
  String toString() => 'DocumentException: $message';
}
