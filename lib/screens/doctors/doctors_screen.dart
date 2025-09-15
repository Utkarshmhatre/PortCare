import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/doctor.dart';
import '../../repositories/doctor_repository.dart';
import '../appointments/appointment_booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final DoctorRepository _doctorRepository = DoctorRepository();

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DoctorSpecialization? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    try {
      final doctors = await _doctorRepository.getAll();
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
      }
    }
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doctor.specialization.displayName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        final matchesSpecialization =
            _selectedSpecialization == null ||
            doctor.specialization == _selectedSpecialization;

        return matchesSearch && matchesSpecialization;
      }).toList();
    });
  }

  void _bookAppointment(Doctor doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AppointmentBookingScreen(preselectedDoctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Doctors',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadDoctors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Search and Filter Section
                  Container(
                    color: AppColors.surface,
                    padding: AppSpacing.mdAll,
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search doctors...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdRadius,
                            ),
                            contentPadding: AppSpacing.mdVertical,
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterDoctors();
                          },
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Specialization Filter
                        DropdownButtonFormField<DoctorSpecialization?>(
                          value: _selectedSpecialization,
                          decoration: InputDecoration(
                            labelText: 'Filter by specialization',
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdRadius,
                            ),
                            contentPadding: AppSpacing.mdAll,
                          ),
                          items: [
                            DropdownMenuItem<DoctorSpecialization?>(
                              value: null,
                              child: Text('All Specializations'),
                            ),
                            ...DoctorSpecialization.values.map((
                              specialization,
                            ) {
                              return DropdownMenuItem(
                                value: specialization,
                                child: Text(specialization.displayName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedSpecialization = value);
                            _filterDoctors();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Doctors List
                  Expanded(
                    child: _filteredDoctors.isEmpty
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
                                  _doctors.isEmpty
                                      ? 'No doctors available'
                                      : 'No doctors match your search',
                                  style: AppTypography.bodyLargeStyle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: AppSpacing.mdAll,
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              return _buildDoctorCard(_filteredDoctors[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: Padding(
        padding: AppSpacing.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Doctor Avatar/Photo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getSpecializationColor(
                      doctor.specialization,
                    ).withOpacity(0.1),
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: doctor.profilePhotoUrl != null
                      ? ClipRRect(
                          borderRadius: AppRadius.mdRadius,
                          child: Image.network(
                            doctor.profilePhotoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: _getSpecializationColor(
                                  doctor.specialization,
                                ),
                                size: 30,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: _getSpecializationColor(doctor.specialization),
                          size: 30,
                        ),
                ),
                SizedBox(width: AppSpacing.md),

                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: AppTypography.h2Style.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        doctor.specialization.displayName,
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: _getSpecializationColor(doctor.specialization),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (doctor.phone != null) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          doctor.phone!,
                          style: AppTypography.bodySmallStyle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Rating
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: AppTypography.bodySmallStyle.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${doctor.experienceYears} years',
                      style: AppTypography.captionStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                doctor.bio!,
                style: AppTypography.bodySmallStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              children: [
                // Availability Status
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: doctor.isActive
                        ? AppColors.accentGreen.withOpacity(0.1)
                        : AppColors.danger.withOpacity(0.1),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    doctor.isActive ? 'Available' : 'Inactive',
                    style: AppTypography.captionStyle.copyWith(
                      color: doctor.isActive
                          ? AppColors.accentGreen
                          : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Spacer(),

                // Book Appointment Button
                ElevatedButton(
                  onPressed: doctor.isActive
                      ? () => _bookAppointment(doctor)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.mutedSurface,
                    disabledForegroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: Text(
                    'Book Appointment',
                    style: AppTypography.bodySmallStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSpecializationColor(DoctorSpecialization specialization) {
    switch (specialization) {
      case DoctorSpecialization.cardiology:
        return AppColors.danger;
      case DoctorSpecialization.dermatology:
        return AppColors.accentGreen;
      case DoctorSpecialization.neurology:
        return AppColors.accentBlue;
      case DoctorSpecialization.orthopedics:
        return AppColors.primary;
      case DoctorSpecialization.pediatrics:
        return Colors.purple;
      case DoctorSpecialization.psychiatry:
        return Colors.teal;
      case DoctorSpecialization.gynecology:
        return Colors.pink;
      case DoctorSpecialization.ophthalmology:
        return Colors.indigo;
      case DoctorSpecialization.dentistry:
        return Colors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }
}
