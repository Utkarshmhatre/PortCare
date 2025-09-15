import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/health_metrics.dart';
import '../../services/health_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late HealthService _healthService;

  List<HealthMetric> _recentMetrics = [];
  Map<HealthMetricType, double> _latestValues = {};
  List<HealthGoal> _activeGoals = [];
  List<Consultation> _recentConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeHealthData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _healthService = Provider.of<HealthService>(context, listen: false);
  }

  Future<void> _initializeHealthData() async {
    setState(() => _isLoading = true);

    try {
      // Load recent metrics
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      _recentMetrics = await _healthService.getMetrics(
        startDate: startDate,
        endDate: endDate,
      );

      // Load latest values
      _latestValues = await _healthService.getLatestValues();

      // Load active goals
      _activeGoals = await _healthService.getActiveGoals();

      // Load recent consultations
      _recentConsultations = await _healthService.getConsultations();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading health data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Health Dashboard',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: _showAddMetricDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _initializeHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Metrics'),
                        Tab(text: 'Consultations'),
                      ],
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildMetricsTab(),
                        _buildConsultationsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: AppLayout.safeAreaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          Text(
            'Today\'s Summary',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Steps',
                  _latestValues[HealthMetricType.steps]?.toInt().toString() ?? '0',
                  Icons.directions_walk,
                  AppColors.accentGreen,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMetricCard(
                  'Heart Rate',
                  '${_latestValues[HealthMetricType.heartRate]?.toInt() ?? 0} bpm',
                  Icons.favorite,
                  AppColors.danger,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Active Goals
          if (_activeGoals.isNotEmpty) ...[
            Text(
              'Active Goals',
              style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.md),
            ..._activeGoals.map((goal) => _buildGoalCard(goal)),
          ],

          // Recent Activity
          SizedBox(height: AppSpacing.xl),
          Text(
            'Recent Activity',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md),
          ..._recentMetrics.take(5).map((metric) => _buildActivityItem(metric)),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: AppLayout.safeAreaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Metrics',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md),

          // Metrics Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: HealthMetricType.values.length,
            itemBuilder: (context, index) {
              final type = HealthMetricType.values[index];
              return _buildDetailedMetricCard(type);
            },
          ),

          // Charts Section
          SizedBox(height: AppSpacing.xl),
          Text(
            'Trends',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md),
          _buildMetricsChart(),
        ],
      ),
    );
  }

  Widget _buildConsultationsTab() {
    return _recentConsultations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'No consultations yet',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: AppLayout.safeAreaPadding,
            itemCount: _recentConsultations.length,
            itemBuilder: (context, index) {
              return _buildConsultationCard(_recentConsultations[index]);
            },
          );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodySmallStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.h2Style.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricCard(HealthMetricType type) {
    final value = _latestValues[type];
    final metrics = _recentMetrics.where((m) => m.type == type).toList();

    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getMetricIcon(type), color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  type.displayName,
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value != null ? '${value.toStringAsFixed(1)} ${type.unit}' : 'No data',
            style: AppTypography.h1Style.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (metrics.length > 1) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              '${metrics.length} readings',
              style: AppTypography.captionStyle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(HealthGoal goal) {
    final progress = _calculateGoalProgress(goal);

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getMetricIcon(goal.metricType), color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  goal.title ?? goal.metricType.displayName,
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.uiStroke,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% complete',
            style: AppTypography.captionStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(HealthMetric metric) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(
            _getMetricIcon(metric.type),
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.type.displayName,
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${metric.value.toStringAsFixed(1)} ${metric.unit}',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(metric.recordedAt),
            style: AppTypography.captionStyle.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  consultation.doctorName,
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatDate(consultation.consultationDate),
                style: AppTypography.captionStyle.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (consultation.diagnosis != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              'Diagnosis: ${consultation.diagnosis}',
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (consultation.prescriptions.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              'Prescriptions: ${consultation.prescriptions.length}',
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsChart() {
    // This is a simplified chart - in a real app you'd use more sophisticated charting
    final stepMetrics = _recentMetrics
        .where((m) => m.type == HealthMetricType.steps)
        .take(7)
        .toList();

    if (stepMetrics.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Center(
          child: Text(
            'No chart data available',
            style: AppTypography.bodyLargeStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: stepMetrics.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: AppColors.accentBlue,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accentBlue.withOpacity(0.1),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMetricIcon(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.steps:
        return Icons.directions_walk;
      case HealthMetricType.heartRate:
        return Icons.favorite;
      case HealthMetricType.weight:
        return Icons.monitor_weight;
      case HealthMetricType.temperature:
        return Icons.thermostat;
      case HealthMetricType.calories:
        return Icons.local_fire_department;
      default:
        return Icons.health_and_safety;
    }
  }

  double _calculateGoalProgress(HealthGoal goal) {
    final relevantMetrics = _recentMetrics
        .where((m) => m.type == goal.metricType)
        .toList();

    if (relevantMetrics.isEmpty) return 0.0;

    final latestValue = relevantMetrics
        .reduce((a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b)
        .value;

    return (latestValue / goal.targetValue).clamp(0.0, 1.0);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showAddMetricDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Health Metric',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.directions_walk, color: AppColors.primary),
              title: Text('Steps'),
              onTap: () => _showManualEntryDialog(HealthMetricType.steps),
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: AppColors.primary),
              title: Text('Heart Rate'),
              onTap: () => _showManualEntryDialog(HealthMetricType.heartRate),
            ),
            ListTile(
              leading: Icon(Icons.monitor_weight, color: AppColors.primary),
              title: Text('Weight'),
              onTap: () => _showManualEntryDialog(HealthMetricType.weight),
            ),
            ListTile(
              leading: Icon(Icons.thermostat, color: AppColors.primary),
              title: Text('Temperature'),
              onTap: () => _showManualEntryDialog(HealthMetricType.temperature),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyLargeStyle.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(HealthMetricType type) {
    Navigator.of(context).pop(); // Close the type selection dialog

    final controller = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add ${type.displayName}',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Value (${type.unit})',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyLargeStyle.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null) {
                try {
                  await _healthService.addManualMetric(
                    type: type,
                    value: value,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );
                  Navigator.of(context).pop();
                  _initializeHealthData(); // Refresh data
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding metric: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdRadius,
              ),
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
