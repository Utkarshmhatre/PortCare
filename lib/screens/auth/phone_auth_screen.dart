import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/input_fields.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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

  Future<void> _handlePhoneAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = _phoneController.text.trim();

    authProvider.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
        });
        _navigateToVerification(verificationId, phoneNumber);
      },
      onError: (String error) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(error);
      },
    );
  }

  void _navigateToVerification(String verificationId, String phoneNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhoneVerificationScreen(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.safeAreaPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      size: 40,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Phone Verification',
                        style: AppTypography.displayLargeStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        'Enter your phone number to receive a verification code',
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Phone Input
                AppInputField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+91 XXXXX XXXXX',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textTertiary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(
                      r'^\+91\d{10}$',
                    ).hasMatch(value.replaceAll(' ', ''))) {
                      return 'Please enter a valid phone number (+91XXXXXXXXXX)';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handlePhoneAuth(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Info Box
                Container(
                  padding: AppSpacing.mdAll,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.accentBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'We\'ll send you a 6-digit verification code via SMS',
                          style: AppTypography.bodySmallStyle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Send Code Button
                PrimaryButton(
                  text: 'Send Verification Code',
                  onPressed: _handlePhoneAuth,
                  isLoading: _isLoading,
                  icon: const Icon(
                    Icons.sms_outlined,
                    color: AppColors.surface,
                  ),
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

// Simple phone verification screen
class PhoneVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
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

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      _showErrorSnackBar('Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.verifyPhoneCode(
      verificationId: widget.verificationId,
      smsCode: _codeController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigation will be handled by auth state changes
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Verification failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.safeAreaPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Header
              Text(
                'Enter Verification Code',
                style: AppTypography.displayLargeStyle.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'We sent a code to ${widget.phoneNumber}',
                style: AppTypography.bodyLargeStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Code Input
              AppInputField(
                controller: _codeController,
                hintText: '000000',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter the 6-digit code';
                  }
                  return null;
                },
                onSubmitted: (_) => _verifyCode(),
              ),

              const Spacer(),

              // Verify Button
              PrimaryButton(
                text: 'Verify Code',
                onPressed: _verifyCode,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
