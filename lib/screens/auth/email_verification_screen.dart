import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import 'profile_setup_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isCheckingVerification = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVerified = await authProvider.checkEmailVerification();

    setState(() {
      _isCheckingVerification = false;
    });

    if (isVerified) {
      _timer?.cancel();
      _navigateToProfileSetup();
    }
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendEmailVerification();

    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });

    // Start cooldown timer
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email sent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.firebaseUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: AppLayout.safeAreaPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: AppColors.accentBlue,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Header
              Text(
                'Check Your Email',
                style: AppTypography.displayLargeStyle.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We sent a verification link to\n',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: email,
                      style: AppTypography.bodyLargeStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.semibold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Click the link in your email to verify your account. This page will automatically update once verified.',
                style: AppTypography.bodyStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Verification Status
              if (_isCheckingVerification) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Checking verification status...',
                      style: AppTypography.bodyStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
              ],

              const Spacer(),

              // Resend Button
              if (_canResend)
                SecondaryButton(
                  text: 'Resend Verification Email',
                  onPressed: _resendVerificationEmail,
                  icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                )
              else
                Container(
                  height: AppSizes.secondaryButtonHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.mutedSurface.withOpacity(0.5),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: AppColors.uiStroke.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Resend in ${_resendCooldown}s',
                      style: AppTypography.buttonStyle.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Back to Login',
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
