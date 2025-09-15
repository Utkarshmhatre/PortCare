import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../appointments/appointments_screen.dart';
import '../appointments/appointment_booking_screen.dart';
import '../booths/booths_screen.dart';
import '../documents/documents_screen.dart';
import '../health/health_screen.dart';
import '../doctors/doctors_screen.dart';
import '../profile/profile_screen.dart';
import '../../repositories/appointment_repository.dart';
import '../../models/appointment.dart';
import '../../repositories/document_repository.dart';
import '../../models/document.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboardScreen(),
    const AppointmentsScreen(),
    const BoothsScreen(),
    const DocumentsScreen(),
    const HealthScreen(),
    const DoctorsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'PortCare',
    'Appointments',
    'Booths',
    'Documents',
    'Health',
    'Doctors',
    'Profile',
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.calendar_today,
    Icons.location_on,
    Icons.folder,
    Icons.favorite,
    Icons.person_search,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: Text(
              _titles[_currentIndex],
              style: AppTypography.h1Style.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            actions: _currentIndex == 0
                ? [
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ]
                : null,
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            height: 80,
            margin: AppSpacing.mdAll,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.pillRadius,
              boxShadow: AppElevation.medium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (index) {
                return _buildNavItem(
                  _icons[index],
                  _titles[index],
                  index == _currentIndex,
                  index,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.surface
                : AppColors.surface.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.captionStyle.copyWith(
              color: isActive
                  ? AppColors.surface
                  : AppColors.surface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final DocumentRepository _documentRepository = DocumentRepository();
  Appointment? _nextAppointment;
  bool _isLoadingAppointment = true;
  List<Document> _recentDocuments = [];
  bool _isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
    _loadRecentDocuments();
  }

  Future<void> _loadNextAppointment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid != null) {
      try {
        final appointments = await _appointmentRepository.getByPatientId(
          authProvider.user!.uid,
          limit: 10,
        );
        final now = DateTime.now();
        final upcomingAppointments =
            appointments
                .where(
                  (appt) =>
                      appt.scheduledDateTime.isAfter(now) &&
                      appt.status != AppointmentStatus.cancelled,
                )
                .toList()
              ..sort(
                (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
              );

        setState(() {
          _nextAppointment = upcomingAppointments.isNotEmpty
              ? upcomingAppointments.first
              : null;
          _isLoadingAppointment = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingAppointment = false;
        });
        // Handle error silently for now
      }
    } else {
      setState(() {
        _isLoadingAppointment = false;
      });
    }
  }

  Future<void> _loadRecentDocuments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid != null) {
      try {
        final documents = await _documentRepository.getByUserId(
          authProvider.user!.uid,
          limit: 3,
        );
        setState(() {
          _recentDocuments = documents;
          _isLoadingDocuments = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingDocuments = false;
        });
        // Handle error silently for now
      }
    } else {
      setState(() {
        _isLoadingDocuments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SafeArea(
          child: Padding(
            padding: AppLayout.safeAreaPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Welcome Message
                Text(
                  'Welcome, ${authProvider.user?.name ?? 'User'}!',
                  style: AppTypography.h1Style.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your health dashboard',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Next Appointment Card
                if (_isLoadingAppointment)
                  _buildSkeletonCard()
                else if (_nextAppointment != null)
                  _buildNextAppointmentCard(_nextAppointment!)
                else
                  _buildNoAppointmentCard(),
                const SizedBox(height: AppSpacing.lg),
                // Recent Documents Card
                if (_isLoadingDocuments)
                  _buildSkeletonCard()
                else if (_recentDocuments.isNotEmpty)
                  _buildRecentDocumentsCard(_recentDocuments)
                else
                  _buildNoDocumentsCard(),
                const SizedBox(height: AppSpacing.lg),
                // Quick Stats Cards (Placeholder)
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    children: [
                      _buildStatCard(
                        'Appointments',
                        '3',
                        Icons.calendar_today,
                        AppColors.accentBlue,
                      ),
                      _buildStatCard(
                        'Documents',
                        '12',
                        Icons.folder,
                        AppColors.accentGreen,
                      ),
                      _buildStatCard(
                        'Health Metrics',
                        '7,429',
                        Icons.favorite,
                        AppColors.accentYellow,
                      ),
                      _buildStatCard(
                        'Nearby Booths',
                        '4',
                        Icons.location_on,
                        AppColors.accentPurple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Quick Actions
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
                        'Quick Actions',
                        style: AppTypography.h2Style.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            'Book Appointment',
                            Icons.calendar_today,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AppointmentBookingScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            'Find Booth',
                            Icons.location_on,
                            () {
                              // TODO: Navigate to booth finder
                            },
                          ),
                          _buildActionButton(
                            'Upload Document',
                            Icons.upload_file,
                            () {
                              // TODO: Navigate to document upload
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mutedSurface,
              borderRadius: AppRadius.smRadius,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  color: AppColors.mutedSurface,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 14, width: 80, color: AppColors.mutedSurface),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(Appointment appointment) {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Appointment',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${appointment.scheduledDateTime.day}/${appointment.scheduledDateTime.month} at ${appointment.scheduledDateTime.hour}:${appointment.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Dr. ${appointment.doctorId}', // TODO: Fetch doctor name
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onPressed: () {
              // TODO: Navigate to appointment details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoAppointmentCard() {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mutedSurface,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming appointments',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Book your next appointment',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppointmentBookingScreen(),
                ),
              );
            },
            child: Text(
              'Book Now',
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDocumentsCard(List<Document> documents) {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Documents',
                style: AppTypography.bodyLargeStyle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to documents screen
                },
                child: Text(
                  'View All',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...documents
              .take(3)
              .map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.1),
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Icon(
                          _getDocumentIcon(doc.type),
                          color: AppColors.accentGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              style: AppTypography.bodySmallStyle.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${doc.type.displayName} • ${_formatDate(doc.createdAt)}',
                              style: AppTypography.captionStyle.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        onPressed: () {
                          // TODO: Show document actions
                        },
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNoDocumentsCard() {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mutedSurface,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(Icons.folder, color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No documents uploaded',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Upload your medical documents',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to document upload
            },
            child: Text(
              'Upload',
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return Icons.receipt;
      case DocumentType.labReport:
        return Icons.science;
      case DocumentType.xray:
      case DocumentType.mri:
      case DocumentType.ct:
        return Icons.medical_services;
      case DocumentType.insurance:
        return Icons.shield;
      case DocumentType.vaccination:
        return Icons.vaccines;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: AppSpacing.mdAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h1Style.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.bodySmallStyle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mutedSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.captionStyle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
