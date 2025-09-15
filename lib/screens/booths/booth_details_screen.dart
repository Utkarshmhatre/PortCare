import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/booth.dart';
import '../../services/location_service.dart';
import '../appointments/appointment_booking_screen.dart';

class BoothDetailsScreen extends StatefulWidget {
  final Booth booth;

  const BoothDetailsScreen({super.key, required this.booth});

  @override
  State<BoothDetailsScreen> createState() => _BoothDetailsScreenState();
}

class _BoothDetailsScreenState extends State<BoothDetailsScreen> {
  final LocationService _locationService = LocationService();
  double? _distance;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  void _calculateDistance() async {
    try {
      final position = await _locationService
          .getCurrentPositionWithPermission();
      if (position != null && mounted) {
        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          widget.booth.location.latitude,
          widget.booth.location.longitude,
        );
        setState(() {
          _distance = distance;
        });
      }
    } catch (e) {
      // Distance calculation failed, keep as null
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Booth Details',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: _shareBooth,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.mdAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booth Header
              _buildBoothHeader(),

              const SizedBox(height: AppSpacing.lg),

              // Status and Distance
              _buildStatusAndDistance(),

              const SizedBox(height: AppSpacing.lg),

              // Services
              _buildServicesSection(),

              const SizedBox(height: AppSpacing.lg),

              // Operating Hours
              _buildOperatingHours(),

              const SizedBox(height: AppSpacing.lg),

              // Location
              _buildLocationSection(),

              const SizedBox(height: AppSpacing.lg),

              // Equipment
              if (widget.booth.equipment?.isNotEmpty ?? false)
                _buildEquipmentSection(),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoothHeader() {
    return Container(
      padding: AppSpacing.lgAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.booth.name,
                  style: AppTypography.h1Style.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: AppSpacing.xsHorizontal,
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.booth.status).withOpacity(0.1),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  widget.booth.status.displayName,
                  style: AppTypography.captionStyle.copyWith(
                    color: _getStatusColor(widget.booth.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.booth.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.booth.description!,
              style: AppTypography.bodyLargeStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusAndDistance() {
    return Row(
      children: [
        // Status Indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(widget.booth.status),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          widget.booth.status.displayName,
          style: AppTypography.bodyLargeStyle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Distance
        if (_distance != null) ...[
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatDistance(_distance!),
            style: AppTypography.bodyLargeStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Services',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.booth.availableServices.map((service) {
            return Container(
              padding: AppSpacing.smHorizontal,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _formatServiceName(service),
                style: AppTypography.bodySmallStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operating Hours',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.mdAll,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: AppColors.uiStroke, width: 1),
          ),
          child: Column(children: _buildOperatingHoursList()),
        ),
      ],
    );
  }

  List<Widget> _buildOperatingHoursList() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return List.generate(days.length, (index) {
      final day = days[index];
      final dayName = dayNames[index];
      final hours = widget.booth.operatingHours?[day];

      String hoursText;
      if (hours == null || hours['open'] == 'closed') {
        hoursText = 'Closed';
      } else {
        hoursText = '${hours['open']} - ${hours['close']}';
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayName,
              style: AppTypography.bodyLargeStyle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              hoursText,
              style: AppTypography.bodyLargeStyle.copyWith(
                color: hoursText == 'Closed'
                    ? AppColors.danger
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.mdAll,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: AppColors.uiStroke, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.booth.location.address,
                      style: AppTypography.bodyLargeStyle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.booth.location.landmark != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'Landmark: ${widget.booth.location.landmark}',
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (_distance != null) ...[
                    Text(
                      '${_formatDistance(_distance!)} away',
                      style: AppTypography.bodySmallStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  TextButton.icon(
                    onPressed: _openInMaps,
                    icon: Icon(
                      Icons.directions,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Get Directions',
                      style: AppTypography.buttonStyle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment & Facilities',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.mdAll,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: AppColors.uiStroke, width: 1),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.booth.equipment!.map((equipment) {
              return Container(
                padding: AppSpacing.smHorizontal,
                decoration: BoxDecoration(
                  color: AppColors.mutedSurface,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  equipment,
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Book Appointment Button
        if (widget.booth.status == BoothStatus.available)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _bookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: AppSpacing.lgVertical,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              child: Text(
                'Book Appointment',
                style: AppTypography.buttonStyle.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Call Booth Button
        if (widget.booth.contactNumber != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _callBooth,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                padding: AppSpacing.lgVertical,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Call Booth',
                    style: AppTypography.buttonStyle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _bookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AppointmentBookingScreen(preselectedBooth: widget.booth),
      ),
    );
  }

  void _callBooth() {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.booth.contactNumber}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openInMaps() {
    // TODO: Implement maps integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in maps...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareBooth() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing booth details...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Color _getStatusColor(BoothStatus status) {
    switch (status) {
      case BoothStatus.available:
        return AppColors.success;
      case BoothStatus.occupied:
        return AppColors.danger;
      case BoothStatus.maintenance:
        return AppColors.accentYellow;
      case BoothStatus.outOfOrder:
        return AppColors.danger;
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  String _formatServiceName(String service) {
    return service
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
