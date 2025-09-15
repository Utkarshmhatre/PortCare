import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/buttons.dart';
import '../../widgets/input_fields.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDate;
  Gender? _selectedGender;
  bool _tosAccepted = false;
  bool _healthDataConsent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleProfileSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_tosAccepted) {
      _showErrorSnackBar('Please accept the Terms of Service');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.createUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      dateOfBirth: _selectedDate,
      gender: _selectedGender?.value,
      consent: UserConsent(
        termsOfService: _tosAccepted,
        healthDataSharing: _healthDataConsent,
      ),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _navigateToHome();
    } else {
      _showErrorSnackBar(
        authProvider.errorMessage ?? 'Failed to create profile',
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.safeAreaPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Header
                Text(
                  'Complete Your Profile',
                  style: AppTypography.displayLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Help us personalize your PortCare experience',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Name Input
                AppInputField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.textTertiary,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Phone Input (Optional)
                AppInputField(
                  controller: _phoneController,
                  labelText: 'Phone Number (Optional)',
                  hintText: '+91 XXXXX XXXXX',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textTertiary,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Date of Birth
                Text(
                  'Date of Birth (Optional)',
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: AppTypography.medium,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.inputFieldPadding),
                    decoration: BoxDecoration(
                      color: AppColors.mutedSurface,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: AppColors.uiStroke, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date of birth',
                          style: AppTypography.bodyStyle.copyWith(
                            color: _selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Gender Selection
                Text(
                  'Gender (Optional)',
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: AppTypography.medium,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.sm,
                  children: Gender.values.map((gender) {
                    final isSelected = _selectedGender == gender;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = isSelected ? null : gender;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.mutedSurface,
                          borderRadius: AppRadius.smRadius,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.uiStroke,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          gender.displayName,
                          style: AppTypography.bodyStyle.copyWith(
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Consent Section
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
                      Text(
                        'Consent & Privacy',
                        style: AppTypography.h2Style.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Terms of Service Consent
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _tosAccepted,
                            onChanged: (value) {
                              setState(() {
                                _tosAccepted = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.uiStroke,
                              width: 1,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tosAccepted = !_tosAccepted;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree to the ',
                                    style: AppTypography.bodyStyle.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: AppTypography.medium,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' and ',
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: AppTypography.medium,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' *',
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Health Data Consent
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _healthDataConsent,
                            onChanged: (value) {
                              setState(() {
                                _healthDataConsent = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.uiStroke,
                              width: 1,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _healthDataConsent = !_healthDataConsent;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'I consent to sharing my health data with healthcare providers for better care (Optional)',
                                  style: AppTypography.bodyStyle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Complete Profile Button
                PrimaryButton(
                  text: 'Complete Profile',
                  onPressed: _handleProfileSetup,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
