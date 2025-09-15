import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/input_fields.dart';
import 'signup_screen.dart';
import 'profile_setup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (authProvider.isAuthenticated) {
        // User is fully authenticated with profile
        _navigateToHome();
      } else if (authProvider.firebaseUser != null) {
        // User exists but needs profile setup
        _navigateToProfileSetup();
      }
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Login failed');
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignUpScreen()));
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (success) {
        if (authProvider.needsProfileSetup) {
          _navigateToProfileSetup();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showErrorSnackBar(
          authProvider.errorMessage ?? 'Google sign-in failed',
        );
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

                // App Logo and Branding
                Center(
                  child: Column(
                    children: [
                      // GIF Animation for Healthcare with fallback
                      SizedBox(
                        width: 200,
                        height: 200,
                        // child: Image.asset(
                        //   'assets/lotte_animations/start.gif',
                        //   width: 200,
                        //   height: 200,
                        //   fit: BoxFit.contain,
                        //   errorBuilder: (context, error, stackTrace) {
                        //     print('GIF loading error: $error');
                        //     // Fallback to a beautiful healthcare icon
                        //     return Container(
                        //       width: 200,
                        //       height: 200,
                        //       decoration: BoxDecoration(
                        //         gradient: LinearGradient(
                        //           colors: [
                        //             AppColors.primary.withOpacity(0.1),
                        //             AppColors.primary.withOpacity(0.3),
                        //           ],
                        //           begin: Alignment.topLeft,
                        //           end: Alignment.bottomRight,
                        //         ),
                        //         borderRadius: BorderRadius.circular(20),
                        //       ),
                        //       child: Icon(
                        //         Icons.health_and_safety,
                        //         size: 80,
                        //         color: AppColors.primary,
                        //       ),

                        //     );
                        //   },
                        // ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.health_and_safety,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'Welcome Back',
                        style: AppTypography.displayLargeStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        'Sign in to continue to PortCare',
                        style: AppTypography.bodyLargeStyle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email Input
                AppInputField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textTertiary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Input
                AppInputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textTertiary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login Button
                PrimaryButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.uiStroke)),
                    Padding(
                      padding: AppSpacing.mdHorizontal,
                      child: Text(
                        'OR',
                        style: AppTypography.bodySmallStyle.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.uiStroke)),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Google Sign-In Button
                SecondaryButton(
                  text: 'Continue with Google',
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Sign Up Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: AppTypography.bodyStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: _navigateToSignUp,
                            child: Text(
                              'Sign Up',
                              style: AppTypography.bodyStyle.copyWith(
                                color: AppColors.primary,
                                fontWeight: AppTypography.semibold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
