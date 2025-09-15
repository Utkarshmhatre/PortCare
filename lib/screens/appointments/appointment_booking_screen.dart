import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/doctor.dart';
import '../../models/booth.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../../repositories/booth_repository.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Booth? preselectedBooth;
  final Doctor? preselectedDoctor;

  const AppointmentBookingScreen({
    super.key,
    this.preselectedBooth,
    this.preselectedDoctor,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final DoctorRepository _doctorRepository = DoctorRepository();
  final BoothRepository _boothRepository = BoothRepository();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Doctor? _selectedDoctor;
  Booth? _selectedBooth;

  List<Doctor> _doctors = [];
  List<Booth> _booths = [];
  bool _isLoading = false;
  bool _isBooking = false;

  final List<TimeOfDay> _availableSlots = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 9, minute: 30),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 10, minute: 30),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 11, minute: 30),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 14, minute: 30),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 15, minute: 30),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 16, minute: 30),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBooth = widget.preselectedBooth;
    _selectedDoctor = widget.preselectedDoctor;
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final doctorsFuture = _doctorRepository.getAll();
      final boothsFuture = _boothRepository.getAvailableBooths(limit: 50);

      final results = await Future.wait([doctorsFuture, boothsFuture]);

      setState(() {
        _doctors = results[0] as List<Doctor>;
        _booths = results[1] as List<Booth>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  bool _canBookAppointment() {
    return _selectedDate != null &&
        _selectedTime != null &&
        _selectedDoctor != null &&
        _selectedBooth != null;
  }

  Future<void> _bookAppointment() async {
    if (!_canBookAppointment() || _isBooking) return;

    setState(() => _isBooking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _appointmentRepository.bookAppointment(
        patientId: user.uid,
        doctorId: _selectedDoctor!.id,
        boothId: _selectedBooth!.id,
        scheduledDateTime: appointmentDateTime,
        durationMinutes: 30,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(
            'Book Appointment',
            style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.safeAreaPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Date Selection
              Text(
                'Select Date',
                style: AppTypography.h2Style.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: AppSpacing.mdAll,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: AppColors.uiStroke, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Choose a date',
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: _selectedDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Time Selection
              Text(
                'Select Time',
                style: AppTypography.h2Style.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: AppSpacing.mdAll,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: AppColors.uiStroke, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Choose a time',
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: _selectedTime != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Doctor Selection
              Text(
                'Select Doctor',
                style: AppTypography.h2Style.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: AppSpacing.mdHorizontal,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: AppColors.uiStroke, width: 1),
                ),
                child: DropdownButton<Doctor>(
                  value: _selectedDoctor,
                  hint: Text(
                    'Choose a doctor',
                    style: AppTypography.bodyLargeStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _doctors.map((doctor) {
                    return DropdownMenuItem<Doctor>(
                      value: doctor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            doctor.name,
                            style: AppTypography.bodyLargeStyle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            doctor.specialization.displayName,
                            style: AppTypography.bodySmallStyle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctor = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Booth Selection
              Text(
                'Select Booth',
                style: AppTypography.h2Style.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: AppSpacing.mdHorizontal,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: AppColors.uiStroke, width: 1),
                ),
                child: DropdownButton<Booth>(
                  value: _selectedBooth,
                  hint: Text(
                    'Choose a booth',
                    style: AppTypography.bodyLargeStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _booths.map((booth) {
                    return DropdownMenuItem<Booth>(
                      value: booth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booth.name,
                            style: AppTypography.bodyLargeStyle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            booth.status.displayName,
                            style: AppTypography.bodySmallStyle.copyWith(
                              color: booth.status == BoothStatus.available
                                  ? AppColors.accentGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBooth = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Notes
              Text(
                'Additional Notes (Optional)',
                style: AppTypography.h2Style.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter any additional notes...',
                  hintStyle: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: const BorderSide(
                      color: AppColors.uiStroke,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: const BorderSide(
                      color: AppColors.uiStroke,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: const BorderSide(
                      color: AppColors.borderFocus,
                      width: 1,
                    ),
                  ),
                  contentPadding: AppSpacing.mdAll,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Book Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: _canBookAppointment() && !_isBooking
                      ? _bookAppointment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.mutedSurface,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  child: _isBooking
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surface,
                            ),
                          ),
                        )
                      : Text(
                          'Book Appointment',
                          style: AppTypography.buttonStyle.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
