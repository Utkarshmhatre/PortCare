import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pedometer/pedometer.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_metrics.dart';

/// Background service for continuous health data collection
class BackgroundHealthService {
  static const String _stepTrackingTask = 'stepTrackingTask';
  static const String _healthSyncTask = 'healthSyncTask';
  static const String _stepCountKey = 'last_step_count';
  static const String _lastSyncKey = 'last_sync_time';

  static final BackgroundHealthService _instance =
      BackgroundHealthService._internal();
  factory BackgroundHealthService() => _instance;
  BackgroundHealthService._internal();

  String? _currentUserId;
  bool _isInitialized = false;
  StreamSubscription<StepCount>? _stepSubscription;

  /// Initialize the background service
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;

    // Initialize WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false for production
    );

    // Register background tasks
    await _registerBackgroundTasks();

    _isInitialized = true;
  }

  /// Start background step tracking
  Future<void> startBackgroundTracking() async {
    if (!_isInitialized || _currentUserId == null) return;

    // Request permissions
    final hasPermission = await _requestBackgroundPermissions();
    if (!hasPermission) {
      debugPrint('Background permissions not granted');
      return;
    }

    // Start foreground step tracking for immediate data
    await _startForegroundStepTracking();

    // Schedule background tasks
    await Workmanager().registerPeriodicTask(
      _stepTrackingTask,
      _stepTrackingTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresBatteryNotLow: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {'userId': _currentUserId!},
      tag: 'health_tracking',
    );

    // Schedule data sync task
    await Workmanager().registerPeriodicTask(
      _healthSyncTask,
      _healthSyncTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {'userId': _currentUserId!},
      tag: 'health_sync',
    );
  }

  /// Stop background tracking
  Future<void> stopBackgroundTracking() async {
    await _stepSubscription?.cancel();
    _stepSubscription = null;

    await Workmanager().cancelByTag('health_tracking');
    await Workmanager().cancelByTag('health_sync');
  }

  /// Request necessary permissions for background operation
  Future<bool> _requestBackgroundPermissions() async {
    try {
      // Activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) return false;

      // Health permissions
      final health = Health();
      final healthTypes = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];

      final permissions = healthTypes
          .map((type) => HealthDataAccess.READ)
          .toList();
      final hasHealthPermissions = await health.requestAuthorization(
        healthTypes,
        permissions: permissions,
      );

      return hasHealthPermissions;
    } catch (e) {
      debugPrint('Error requesting background permissions: $e');
      return false;
    }
  }

  /// Start foreground step tracking for immediate data collection
  Future<void> _startForegroundStepTracking() async {
    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) => debugPrint('Step counter error: $error'),
      );
    } catch (e) {
      debugPrint('Error starting foreground step tracking: $e');
    }
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStepCount = prefs.getInt(_stepCountKey) ?? 0;
      final stepsSinceLast = event.steps - lastStepCount;

      if (stepsSinceLast > 0) {
        // Store step data locally
        await _storeStepDataLocally(event.steps, stepsSinceLast);

        // Update last step count
        await prefs.setInt(_stepCountKey, event.steps);
      }
    } catch (e) {
      debugPrint('Error handling step count: $e');
    }
  }

  /// Store step data locally for later sync
  Future<void> _storeStepDataLocally(int totalSteps, int stepsSinceLast) async {
    if (_currentUserId == null) return;

    try {
      final metric = HealthMetric(
        id: 'steps_bg_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId!,
        type: HealthMetricType.steps,
        value: stepsSinceLast.toDouble(),
        unit: 'steps',
        recordedAt: DateTime.now(),
        source: HealthDataSource.phone,
        metadata: {'totalSteps': totalSteps, 'background': true},
      );

      // Store in SharedPreferences for background tasks
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getStringList('pending_health_data') ?? [];

      pendingData.add(metric.id);
      await prefs.setString('health_metric_${metric.id}', metric.toString());
      await prefs.setStringList('pending_health_data', pendingData);
    } catch (e) {
      debugPrint('Error storing step data locally: $e');
    }
  }

  /// Register background tasks
  Future<void> _registerBackgroundTasks() async {
    await Workmanager().registerOneOffTask(
      'initialize_health_service',
      'initializeHealthService',
      inputData: {'userId': _currentUserId!},
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopBackgroundTracking();
    _isInitialized = false;
  }
}

/// Callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final userId = inputData?['userId'] as String?;
      if (userId == null) return false;

      switch (task) {
        case 'stepTrackingTask':
          return await _performStepTracking(userId);
        case 'healthSyncTask':
          return await _performHealthSync(userId);
        case 'initializeHealthService':
          return await _initializeHealthService(userId);
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Perform background step tracking
Future<bool> _performStepTracking(String userId) async {
  try {
    final health = Health();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Get step data from Health API
    final healthData = await health.getHealthDataFromTypes(
      startTime: yesterday,
      endTime: now,
      types: [HealthDataType.STEPS],
    );

    // Process and store step data
    for (final data in healthData) {
      if (data.type == HealthDataType.STEPS &&
          data.value is NumericHealthValue) {
        final steps = (data.value as NumericHealthValue).numericValue.toInt();

        final metric = HealthMetric(
          id: 'steps_bg_${data.dateTo.millisecondsSinceEpoch}',
          userId: userId,
          type: HealthMetricType.steps,
          value: steps.toDouble(),
          unit: 'steps',
          recordedAt: data.dateTo,
          source: HealthDataSource.phone,
          metadata: {'background': true, 'sourceId': data.sourceId},
        );

        // Store locally for later sync
        await _storeMetricForSync(metric);
      }
    }

    return true;
  } catch (e) {
    debugPrint('Error in background step tracking: $e');
    return false;
  }
}

/// Perform health data synchronization
Future<bool> _performHealthSync(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getStringList('pending_health_data') ?? [];

    if (pendingData.isEmpty) return true;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final metricId in pendingData) {
      final metricData = prefs.getString('health_metric_$metricId');
      if (metricData != null) {
        // Parse metric data and add to batch
        // Note: In a real implementation, you'd need proper serialization
        final metric = _parseMetricFromString(metricData);
        if (metric != null) {
          final docRef = firestore
              .collection('users')
              .doc(userId)
              .collection('healthMetrics')
              .doc(metric.id);

          batch.set(docRef, metric.toMap(), SetOptions(merge: true));
        }
      }
    }

    // Commit batch
    await batch.commit();

    // Clear processed data
    await prefs.remove('pending_health_data');
    for (final metricId in pendingData) {
      await prefs.remove('health_metric_$metricId');
    }

    // Update last sync time
    await prefs.setInt(
      BackgroundHealthService._lastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return true;
  } catch (e) {
    debugPrint('Error in background health sync: $e');
    return false;
  }
}

/// Initialize health service in background
Future<bool> _initializeHealthService(String userId) async {
  try {
    // Initialize any background service components
    debugPrint('Background health service initialized for user: $userId');
    return true;
  } catch (e) {
    debugPrint('Error initializing background health service: $e');
    return false;
  }
}

/// Store metric for later synchronization
Future<void> _storeMetricForSync(HealthMetric metric) async {
  final prefs = await SharedPreferences.getInstance();
  final pendingData = prefs.getStringList('pending_health_data') ?? [];

  pendingData.add(metric.id);
  await prefs.setString('health_metric_${metric.id}', metric.toString());
  await prefs.setStringList('pending_health_data', pendingData);
}

/// Parse metric from string (simplified implementation)
HealthMetric? _parseMetricFromString(String data) {
  // This is a simplified implementation
  // In a real app, you'd use proper JSON serialization
  try {
    // For now, return null - implement proper parsing based on your needs
    return null;
  } catch (e) {
    debugPrint('Error parsing metric: $e');
    return null;
  }
}
