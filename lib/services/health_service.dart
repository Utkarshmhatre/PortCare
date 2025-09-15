import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/health_metrics.dart';

/// Service for managing health data collection, storage, and synchronization
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Health _health = Health();
  final Connectivity _connectivity = Connectivity();

  // Local storage
  late Box<HealthMetric> _healthMetricsBox;
  late Box<Consultation> _consultationsBox;
  late Box<HealthGoal> _healthGoalsBox;

  // Streams
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Controllers
  final StreamController<HealthMetric> _healthDataController =
      StreamController<HealthMetric>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // State
  bool _isInitialized = false;
  bool _isCollectingData = false;
  String? _currentUserId;
  Timer? _syncTimer;

  // Getters
  Stream<HealthMetric> get healthDataStream => _healthDataController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isInitialized => _isInitialized;
  bool get isCollectingData => _isCollectingData;

  /// Initialize the health service
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;

    // Initialize Hive boxes
    await Hive.initFlutter();
    Hive.registerAdapter(HealthMetricAdapter());
    Hive.registerAdapter(ConsultationAdapter());
    Hive.registerAdapter(HealthGoalAdapter());

    _healthMetricsBox = await Hive.openBox<HealthMetric>(
      'health_metrics_$userId',
    );
    _consultationsBox = await Hive.openBox<Consultation>(
      'consultations_$userId',
    );
    _healthGoalsBox = await Hive.openBox<HealthGoal>('health_goals_$userId');

    // Setup connectivity monitoring
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync
    _syncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _syncDataToFirestore(),
    );

    _isInitialized = true;
  }

  /// Request necessary permissions for health data
  Future<bool> requestPermissions() async {
    try {
      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        _errorController.add('Activity recognition permission denied');
        return false;
      }

      // Request health permissions
      final healthTypes = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];

      final permissions = healthTypes
          .map((type) => HealthDataAccess.READ)
          .toList();
      final hasPermissions = await _health.requestAuthorization(
        healthTypes,
        permissions: permissions,
      );

      if (!hasPermissions) {
        _errorController.add('Health data permissions denied');
        return false;
      }

      return true;
    } catch (e) {
      _errorController.add('Error requesting permissions: $e');
      return false;
    }
  }

  /// Start collecting health data from sensors
  Future<void> startDataCollection() async {
    if (!isInitialized || _isCollectingData) return;

    try {
      // Start step counting
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) => _errorController.add('Step counter error: $error'),
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (error) =>
            _errorController.add('Pedestrian status error: $error'),
      );

      // Start collecting data from Health API
      await _startHealthDataCollection();

      _isCollectingData = true;
    } catch (e) {
      _errorController.add('Error starting data collection: $e');
    }
  }

  /// Stop collecting health data
  Future<void> stopDataCollection() async {
    if (!_isCollectingData) return;

    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();

    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    _isCollectingData = false;
  }

  /// Add manual health metric entry
  Future<void> addManualMetric({
    required HealthMetricType type,
    required double value,
    String? notes,
    String? appointmentId,
  }) async {
    if (!isInitialized || _currentUserId == null) return;

    try {
      final metric = HealthMetric(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        type: type,
        value: value,
        unit: type.unit,
        recordedAt: DateTime.now(),
        source: HealthDataSource.manual,
        appointmentId: appointmentId,
        notes: notes,
      );

      // Store locally
      await _healthMetricsBox.put(metric.id, metric);

      // Emit to stream
      _healthDataController.add(metric);

      // Sync to Firestore if online
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult != ConnectivityResult.none) {
        await _syncMetricToFirestore(metric);
      }
    } catch (e) {
      _errorController.add('Error adding manual metric: $e');
    }
  }

  /// Get health metrics for a date range
  Future<List<HealthMetric>> getMetrics({
    required DateTime startDate,
    required DateTime endDate,
    HealthMetricType? type,
  }) async {
    if (!isInitialized) return [];

    try {
      final metrics = _healthMetricsBox.values.where((metric) {
        final inRange =
            metric.recordedAt.isAfter(startDate) &&
            metric.recordedAt.isBefore(endDate);
        final typeMatch = type == null || metric.type == type;
        return inRange && typeMatch;
      }).toList();

      // Sort by date (newest first)
      metrics.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return metrics;
    } catch (e) {
      _errorController.add('Error getting metrics: $e');
      return [];
    }
  }

  /// Get latest values for all metric types
  Future<Map<HealthMetricType, double>> getLatestValues() async {
    if (!isInitialized) return {};

    final latestValues = <HealthMetricType, double>{};

    for (final type in HealthMetricType.values) {
      final metrics = await getMetrics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        type: type,
      );

      if (metrics.isNotEmpty) {
        latestValues[type] = metrics.first.value;
      }
    }

    return latestValues;
  }

  /// Add consultation record
  Future<void> addConsultation(Consultation consultation) async {
    if (!isInitialized) return;

    try {
      await _consultationsBox.put(consultation.id, consultation);

      // Sync to Firestore
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult != ConnectivityResult.none) {
        await _syncConsultationToFirestore(consultation);
      }
    } catch (e) {
      _errorController.add('Error adding consultation: $e');
    }
  }

  /// Get consultations
  Future<List<Consultation>> getConsultations() async {
    if (!isInitialized) return [];

    try {
      final consultations = _consultationsBox.values.toList();
      consultations.sort(
        (a, b) => b.consultationDate.compareTo(a.consultationDate),
      );
      return consultations;
    } catch (e) {
      _errorController.add('Error getting consultations: $e');
      return [];
    }
  }

  /// Add health goal
  Future<void> addHealthGoal(HealthGoal goal) async {
    if (!isInitialized) return;

    try {
      await _healthGoalsBox.put(goal.id, goal);

      // Sync to Firestore
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult != ConnectivityResult.none) {
        await _syncGoalToFirestore(goal);
      }
    } catch (e) {
      _errorController.add('Error adding health goal: $e');
    }
  }

  /// Get active health goals
  Future<List<HealthGoal>> getActiveGoals() async {
    if (!isInitialized) return [];

    try {
      return _healthGoalsBox.values.where((goal) => goal.isActive).toList();
    } catch (e) {
      _errorController.add('Error getting active goals: $e');
      return [];
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopDataCollection();
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();

    await _healthDataController.close();
    await _errorController.close();

    await _healthMetricsBox.close();
    await _consultationsBox.close();
    await _healthGoalsBox.close();

    _isInitialized = false;
  }

  // Private methods

  void _onStepCount(StepCount event) {
    final metric = HealthMetric(
      id: 'steps_${event.timeStamp.millisecondsSinceEpoch}',
      userId: _currentUserId!,
      type: HealthMetricType.steps,
      value: event.steps.toDouble(),
      unit: HealthMetricType.steps.unit,
      recordedAt: event.timeStamp,
      source: HealthDataSource.phone,
    );

    _storeMetric(metric);
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    // Handle pedestrian status changes if needed
    // print('Pedestrian status: ${event.status}');
  }

  Future<void> _startHealthDataCollection() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Collect data from Health API
      final healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.HEART_RATE,
          HealthDataType.WEIGHT,
          HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
          HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
          HealthDataType.BODY_TEMPERATURE,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_WALKING_RUNNING,
        ],
      );

      for (final data in healthData) {
        final metric = _convertHealthDataToMetric(data);
        if (metric != null) {
          _storeMetric(metric);
        }
      }
    } catch (e) {
      _errorController.add('Error collecting health data: $e');
    }
  }

  HealthMetric? _convertHealthDataToMetric(HealthDataPoint data) {
    HealthMetricType? type;
    String unit = '';

    switch (data.type) {
      case HealthDataType.STEPS:
        type = HealthMetricType.steps;
        unit = 'steps';
        break;
      case HealthDataType.HEART_RATE:
        type = HealthMetricType.heartRate;
        unit = 'bpm';
        break;
      case HealthDataType.WEIGHT:
        type = HealthMetricType.weight;
        unit = 'kg';
        break;
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        type = HealthMetricType.bloodPressureSystolic;
        unit = 'mmHg';
        break;
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        type = HealthMetricType.bloodPressureDiastolic;
        unit = 'mmHg';
        break;
      case HealthDataType.BODY_TEMPERATURE:
        type = HealthMetricType.temperature;
        unit = '°C';
        break;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        type = HealthMetricType.calories;
        unit = 'kcal';
        break;
      case HealthDataType.DISTANCE_WALKING_RUNNING:
        type = HealthMetricType.distance;
        unit = 'km';
        break;
      default:
        return null;
    }

    // Convert numeric value
    double numericValue;
    if (data.value is NumericHealthValue) {
      numericValue = (data.value as NumericHealthValue).numericValue.toDouble();
    } else {
      return null; // Skip non-numeric values
    }

    return HealthMetric(
      id: '${type.value}_${data.dateTo.millisecondsSinceEpoch}',
      userId: _currentUserId!,
      type: type,
      value: numericValue,
      unit: unit,
      recordedAt: data.dateTo,
      source: HealthDataSource.wearable,
      metadata: {'sourceId': data.sourceId, 'sourceName': data.sourceName},
    );
  }

  Future<void> _storeMetric(HealthMetric metric) async {
    try {
      await _healthMetricsBox.put(metric.id, metric);
      _healthDataController.add(metric);
    } catch (e) {
      _errorController.add('Error storing metric: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (result != ConnectivityResult.none) {
      // Sync data when connection is restored
      _syncDataToFirestore();
    }
  }

  Future<void> _syncDataToFirestore() async {
    if (!isInitialized || _currentUserId == null) return;

    try {
      // Sync metrics
      final unsyncedMetrics = _healthMetricsBox.values
          .where((m) => true)
          .toList(); // All local metrics
      for (final metric in unsyncedMetrics) {
        await _syncMetricToFirestore(metric);
      }

      // Sync consultations
      final unsyncedConsultations = _consultationsBox.values.toList();
      for (final consultation in unsyncedConsultations) {
        await _syncConsultationToFirestore(consultation);
      }

      // Sync goals
      final unsyncedGoals = _healthGoalsBox.values.toList();
      for (final goal in unsyncedGoals) {
        await _syncGoalToFirestore(goal);
      }
    } catch (e) {
      _errorController.add('Error syncing data: $e');
    }
  }

  Future<void> _syncMetricToFirestore(HealthMetric metric) async {
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('healthMetrics')
        .doc(metric.id)
        .set(metric.toMap(), SetOptions(merge: true));
  }

  Future<void> _syncConsultationToFirestore(Consultation consultation) async {
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('consultations')
        .doc(consultation.id)
        .set(consultation.toMap(), SetOptions(merge: true));
  }

  Future<void> _syncGoalToFirestore(HealthGoal goal) async {
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('healthGoals')
        .doc(goal.id)
        .set(goal.toMap(), SetOptions(merge: true));
  }
}

// Hive Adapters
class HealthMetricAdapter extends TypeAdapter<HealthMetric> {
  @override
  final int typeId = 0;

  @override
  HealthMetric read(BinaryReader reader) {
    final map = json.decode(reader.readString());
    return HealthMetric.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, HealthMetric obj) {
    writer.writeString(json.encode(obj.toMap()));
  }
}

class ConsultationAdapter extends TypeAdapter<Consultation> {
  @override
  final int typeId = 1;

  @override
  Consultation read(BinaryReader reader) {
    final map = json.decode(reader.readString());
    return Consultation.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Consultation obj) {
    writer.writeString(json.encode(obj.toMap()));
  }
}

class HealthGoalAdapter extends TypeAdapter<HealthGoal> {
  @override
  final int typeId = 2;

  @override
  HealthGoal read(BinaryReader reader) {
    final map = json.decode(reader.readString());
    return HealthGoal.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, HealthGoal obj) {
    writer.writeString(json.encode(obj.toMap()));
  }
}
