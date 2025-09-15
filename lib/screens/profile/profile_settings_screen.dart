import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portcare/design/colors.dart';
import 'package:portcare/design/typography.dart';
import 'package:portcare/services/auth_service.dart';
import 'package:portcare/screens/auth/login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),

            const SizedBox(height: 24),

            // Account Settings
            _buildSectionTitle('Account Settings'),
            const SizedBox(height: 12),
            _buildAccountSettings(),

            const SizedBox(height: 24),

            // App Preferences
            _buildSectionTitle('App Preferences'),
            const SizedBox(height: 12),
            _buildAppPreferences(),

            const SizedBox(height: 24),

            // Privacy & Security
            _buildSectionTitle('Privacy & Security'),
            const SizedBox(height: 12),
            _buildPrivacySettings(),

            const SizedBox(height: 24),

            // Support & About
            _buildSectionTitle('Support & About'),
            const SizedBox(height: 12),
            _buildSupportSection(),

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: _currentUser?.photoURL != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      _currentUser!.photoURL!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.displayName ?? 'User',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.email ?? '',
            style: AppTypography.bodyMediumStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _editProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Edit Profile',
              style: AppTypography.buttonStyle.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h2Style.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Update your personal details',
            onTap: _editPersonalInfo,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _changePassword,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email Preferences',
            subtitle: 'Manage email notifications',
            onTap: _manageEmailPreferences,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive app notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'Allow location access for features',
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face ID',
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() {
                _biometricEnabled = value;
              });
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: _viewPrivacyPolicy,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Data & Privacy',
            subtitle: 'Manage your data preferences',
            onTap: _manageDataPrivacy,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with using the app',
            onTap: _getHelp,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: _sendFeedback,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About PortCare',
            subtitle: 'Version 1.0.0',
            onTap: _viewAbout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyLargeStyle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyLargeStyle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.borderDefault.withOpacity(0.5),
      indent: 56,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Sign Out', style: AppTypography.buttonStyle),
      ),
    );
  }

  // Action methods
  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon')),
    );
  }

  void _editPersonalInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal info edit coming soon')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change feature coming soon')),
    );
  }

  void _manageEmailPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email preferences coming soon')),
    );
  }

  void _viewPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy feature coming soon')),
    );
  }

  void _manageDataPrivacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data privacy settings coming soon')),
    );
  }

  void _getHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support feature coming soon')),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback feature coming soon')),
    );
  }

  void _viewAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About PortCare',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PortCare - Your Healthcare Companion',
              style: AppTypography.bodyLargeStyle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: 1.0.0',
              style: AppTypography.bodyMediumStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A comprehensive healthcare management app designed to help you track your health, manage appointments, and access medical services.',
              style: AppTypography.bodyMediumStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTypography.buttonStyle.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
