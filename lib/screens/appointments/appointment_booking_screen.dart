import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/booth.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Booth? preselectedBooth;

  const AppointmentBookingScreen({super.key, this.preselectedBooth});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDoctor;
  String? _selectedBooth;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _doctors = [
    'Dr. Smith',
    'Dr. Johnson',
    'Dr. Williams',
    'Dr. Brown',
  ];
  final List<String> _booths = ['Booth A1', 'Booth B2', 'Booth C3', 'Booth D4'];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedBooth != null) {
      _selectedBooth = widget.preselectedBooth!.name;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
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

  bool _canBookAppointment() {
    return _selectedDate != null &&
        _selectedTime != null &&
        _selectedDoctor != null &&
        _selectedBooth != null;
  }

  void _bookAppointment() {
    if (!_canBookAppointment()) return;

    // TODO: Implement actual booking logic with Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment booked successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                child: DropdownButton<String>(
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
                    return DropdownMenuItem<String>(
                      value: doctor,
                      child: Text(
                        doctor,
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
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
                child: DropdownButton<String>(
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
                    return DropdownMenuItem<String>(
                      value: booth,
                      child: Text(
                        booth,
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
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
                  onPressed: _canBookAppointment() ? _bookAppointment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.mutedSurface,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  child: Text(
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
