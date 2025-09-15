import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of operations that can be queued for offline sync
enum SyncOperationType {
  create('create'),
  update('update'),
  delete('delete');

  const SyncOperationType(this.value);
  final String value;

  static SyncOperationType? fromString(String value) {
    for (SyncOperationType type in SyncOperationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Represents a queued operation for offline sync
class QueuedOperation {
  final String id;
  final String collection;
  final String documentId;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? userId;

  const QueuedOperation({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.operationType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.userId,
  });

  factory QueuedOperation.fromMap(Map<String, dynamic> map) {
    return QueuedOperation(
      id: map['id'] as String,
      collection: map['collection'] as String,
      documentId: map['documentId'] as String,
      operationType: SyncOperationType.fromString(
        map['operationType'] as String,
      )!,
      data: map['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      userId: map['userId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'documentId': documentId,
      'operationType': operationType.value,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'userId': userId,
    };
  }

  QueuedOperation copyWith({int? retryCount}) {
    return QueuedOperation(
      id: id,
      collection: collection,
      documentId: documentId,
      operationType: operationType,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      userId: userId,
    );
  }
}

/// Service for managing offline data synchronization
class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;
  OfflineSyncManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  late Box<QueuedOperation> _queueBox;
  late Box<Map<String, dynamic>> _conflictBox;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  String? _currentUserId;
  bool _isInitialized = false;
  bool _isOnline = false;

  // Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  int get queueLength => _queueBox.length;

  /// Initialize the offline sync manager
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;

    // Initialize Hive boxes
    _queueBox = await Hive.openBox<QueuedOperation>('sync_queue_$userId');
    _conflictBox = await Hive.openBox<Map<String, dynamic>>(
      'sync_conflicts_$userId',
    );

    // Setup connectivity monitoring
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;

    // Start periodic sync if online
    if (_isOnline) {
      _startPeriodicSync();
    }

    _isInitialized = true;
  }

  /// Queue an operation for offline sync
  Future<void> queueOperation({
    required String collection,
    required String documentId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
  }) async {
    if (!isInitialized) return;

    final operation = QueuedOperation(
      id: '${operationType.value}_${collection}_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
      collection: collection,
      documentId: documentId,
      operationType: operationType,
      data: data,
      timestamp: DateTime.now(),
      userId: _currentUserId,
    );

    await _queueBox.put(operation.id, operation);

    // Try to sync immediately if online
    if (_isOnline) {
      await _processQueue();
    }
  }

  /// Queue a Firestore document operation
  Future<void> queueDocumentOperation({
    required DocumentReference docRef,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
  }) async {
    final pathSegments = docRef.path.split('/');
    final collection = pathSegments[pathSegments.length - 2];
    final documentId = pathSegments.last;

    await queueOperation(
      collection: collection,
      documentId: documentId,
      operationType: operationType,
      data: data,
    );
  }

  /// Process the sync queue
  Future<void> _processQueue() async {
    if (!isInitialized || !_isOnline) return;

    final operations = _queueBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Process in order

    final successfulOps = <String>[];
    final failedOps = <QueuedOperation>[];

    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        successfulOps.add(operation.id);
      } catch (e) {
        final updatedOp = operation.copyWith(
          retryCount: operation.retryCount + 1,
        );

        if (updatedOp.retryCount >= maxRetries) {
          // Move to conflicts if max retries exceeded
          await _handleConflict(updatedOp, e.toString());
          successfulOps.add(operation.id); // Remove from queue
        } else {
          // Update retry count
          await _queueBox.put(operation.id, updatedOp);
          failedOps.add(updatedOp);
        }
      }
    }

    // Remove successful operations
    for (final opId in successfulOps) {
      await _queueBox.delete(opId);
    }

    // Schedule retry for failed operations
    if (failedOps.isNotEmpty) {
      Timer(retryDelay, () => _processQueue());
    }
  }

  /// Execute a queued operation
  Future<void> _executeOperation(QueuedOperation operation) async {
    final docRef = _firestore
        .collection(operation.collection)
        .doc(operation.documentId);

    switch (operation.operationType) {
      case SyncOperationType.create:
        await docRef.set(operation.data, SetOptions(merge: true));
        break;
      case SyncOperationType.update:
        await docRef.update(operation.data);
        break;
      case SyncOperationType.delete:
        await docRef.delete();
        break;
    }
  }

  /// Handle sync conflicts
  Future<void> _handleConflict(QueuedOperation operation, String error) async {
    final conflictData = {
      'operation': operation.toMap(),
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
      'resolved': false,
    };

    await _conflictBox.put(operation.id, conflictData);
  }

  /// Resolve a conflict
  Future<void> resolveConflict(
    String conflictId,
    Map<String, dynamic> resolutionData,
  ) async {
    final conflict = _conflictBox.get(conflictId);
    if (conflict == null) return;

    try {
      final operation = QueuedOperation.fromMap(
        conflict['operation'] as Map<String, dynamic>,
      );
      final updatedOperation = QueuedOperation(
        id: operation.id,
        collection: operation.collection,
        documentId: operation.documentId,
        operationType: operation.operationType,
        data: resolutionData,
        timestamp: operation.timestamp,
        retryCount: operation.retryCount,
        userId: operation.userId,
      );
      await _executeOperation(updatedOperation);

      // Mark as resolved
      conflict['resolved'] = true;
      conflict['resolutionData'] = resolutionData;
      conflict['resolvedAt'] = DateTime.now().toIso8601String();

      await _conflictBox.put(conflictId, conflict);
    } catch (e) {
      // Keep conflict for manual resolution
      conflict['resolutionError'] = e.toString();
      await _conflictBox.put(conflictId, conflict);
    }
  }

  /// Get unresolved conflicts
  Future<List<Map<String, dynamic>>> getUnresolvedConflicts() async {
    if (!isInitialized) return [];

    return _conflictBox.values
        .where((conflict) => !(conflict['resolved'] as bool? ?? false))
        .toList();
  }

  /// Clear resolved conflicts
  Future<void> clearResolvedConflicts() async {
    if (!isInitialized) return;

    final resolvedIds = _conflictBox.keys.where((key) {
      final conflict = _conflictBox.get(key);
      return conflict != null && (conflict['resolved'] as bool? ?? false);
    }).toList();

    for (final id in resolvedIds) {
      await _conflictBox.delete(id);
    }
  }

  /// Force sync all queued operations
  Future<void> forceSync() async {
    if (!isInitialized) return;

    if (_isOnline) {
      await _processQueue();
    } else {
      throw Exception('No internet connection available');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (!isInitialized) return {};

    final operations = _queueBox.values.toList();
    final conflicts = await getUnresolvedConflicts();

    return {
      'isOnline': _isOnline,
      'queuedOperations': operations.length,
      'pendingOperations': operations.where((op) => op.retryCount == 0).length,
      'retryingOperations': operations.where((op) => op.retryCount > 0).length,
      'unresolvedConflicts': conflicts.length,
      'lastSyncAttempt': await _getLastSyncTime(),
    };
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      // Came back online, start sync
      _startPeriodicSync();
      _processQueue();
    } else if (wasOnline && !_isOnline) {
      // Went offline, stop sync
      _stopPeriodicSync();
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (_) => _processQueue());
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Get last sync time
  Future<DateTime?> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_time');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Clear all queued operations (use with caution)
  Future<void> clearQueue() async {
    if (!isInitialized) return;
    await _queueBox.clear();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    await _queueBox.close();
    await _conflictBox.close();
    _isInitialized = false;
  }
}

// Hive Adapters
class QueuedOperationAdapter extends TypeAdapter<QueuedOperation> {
  @override
  final int typeId = 3;

  @override
  QueuedOperation read(BinaryReader reader) {
    final map = json.decode(reader.readString());
    return QueuedOperation.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, QueuedOperation obj) {
    writer.writeString(json.encode(obj.toMap()));
  }
}
