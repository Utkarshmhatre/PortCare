import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/booth.dart';
import '../../repositories/booth_repository.dart';
import '../../services/location_service.dart';
import 'booth_details_screen.dart';
import '../qr/qr_scanner_screen.dart';

class BoothsScreen extends StatefulWidget {
  const BoothsScreen({super.key});

  @override
  State<BoothsScreen> createState() => _BoothsScreenState();
}

class _BoothsScreenState extends State<BoothsScreen> {
  final BoothRepository _boothRepository = BoothRepository();
  final LocationService _locationService = LocationService();
  List<Booth> _booths = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showMapView = false;
  BoothStatus? _selectedStatusFilter;
  StreamSubscription<List<Booth>>? _boothsSubscription;
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _sortByDistance = false;

  @override
  void initState() {
    super.initState();
    _subscribeToBooths();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _boothsSubscription?.cancel();
    super.dispose();
  }

  void _scanBoothQR() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          title: 'Scan Booth QR',
          subtitle: 'Scan the QR code to check into a booth',
          onCodeScanned: (code) {
            _handleQRCodeScanned(code);
          },
        ),
      ),
    );
  }

  void _handleQRCodeScanned(String code) {
    try {
      // Find booth by ID from QR code
      final booth = _booths.firstWhere(
        (b) => b.id == code,
        orElse: () => throw Exception('Booth not found'),
      );

      // Navigate to booth details
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BoothDetailsScreen(booth: booth),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found booth: ${booth.name}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid QR code or booth not found'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _subscribeToBooths() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Cancel existing subscription
    _boothsSubscription?.cancel();

    // Subscribe to real-time booth updates
    _boothsSubscription =
        (_selectedStatusFilter != null
                ? _boothRepository.watchByStatus(_selectedStatusFilter!)
                : _boothRepository.watchAllBooths())
            .listen(
              (booths) {
                if (mounted) {
                  List<Booth> processedBooths = List.from(booths);

                  // Sort by distance if enabled and location is available
                  if (_sortByDistance && _currentPosition != null) {
                    processedBooths.sort((a, b) {
                      final distanceA = _locationService.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        a.location.latitude,
                        a.location.longitude,
                      );
                      final distanceB = _locationService.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        b.location.latitude,
                        b.location.longitude,
                      );
                      return distanceA.compareTo(distanceB);
                    });
                  }

                  setState(() {
                    _booths = processedBooths;
                    _isLoading = false;
                  });
                }
              },
              onError: (error) {
                if (mounted) {
                  setState(() {
                    _errorMessage =
                        'Failed to load booths: ${error.toString()}';
                    _isLoading = false;
                  });
                }
              },
            );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final position = await _locationService
          .getCurrentPositionWithPermission();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _toggleSortByDistance() {
    setState(() {
      _sortByDistance = !_sortByDistance;
    });
    _subscribeToBooths();
  }

  void _updateFilter(BoothStatus? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
    _subscribeToBooths();
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  double? _calculateDistanceToBooth(Booth booth) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      booth.location.latitude,
      booth.location.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Booths',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: _scanBoothQR,
            tooltip: 'Scan QR Code',
          ),
          IconButton(
            icon: Icon(
              _showMapView ? Icons.list : Icons.map,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _showMapView = !_showMapView;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isLocationLoading
                  ? Icons.location_searching
                  : _currentPosition != null
                  ? Icons.location_on
                  : Icons.location_off,
              color: _currentPosition != null
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
            onPressed: _getCurrentLocation,
            tooltip: _currentPosition != null
                ? 'Location enabled'
                : 'Enable location for distance',
          ),
          IconButton(
            icon: Icon(
              _sortByDistance ? Icons.sort : Icons.sort_by_alpha,
              color: _sortByDistance
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
            onPressed: _currentPosition != null ? _toggleSortByDistance : null,
            tooltip: _sortByDistance
                ? 'Sorted by distance'
                : 'Sort by distance',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status filter chips
            Container(
              height: 50,
              padding: AppSpacing.mdHorizontal,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', null, _selectedStatusFilter == null),
                  _buildFilterChip(
                    'Available',
                    BoothStatus.available,
                    _selectedStatusFilter == BoothStatus.available,
                  ),
                  _buildFilterChip(
                    'Occupied',
                    BoothStatus.occupied,
                    _selectedStatusFilter == BoothStatus.occupied,
                  ),
                  _buildFilterChip(
                    'Maintenance',
                    BoothStatus.maintenance,
                    _selectedStatusFilter == BoothStatus.maintenance,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage != null
                  ? _buildErrorView()
                  : _showMapView
                  ? _buildMapView()
                  : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BoothStatus? status, bool isSelected) {
    return Container(
      margin: AppSpacing.xsHorizontal,
      child: FilterChip(
        label: Text(
          label,
          style: AppTypography.bodySmallStyle.copyWith(
            color: isSelected ? AppColors.surface : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          _updateFilter(selected ? status : null);
        },
        backgroundColor: AppColors.mutedSurface,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.surface,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading booths...',
            style: AppTypography.bodyLargeStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load booths',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Unknown error',
            style: AppTypography.bodyLargeStyle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _subscribeToBooths(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: Text(
              'Try Again',
              style: AppTypography.buttonStyle.copyWith(
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_booths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No booths available',
              style: AppTypography.h2Style.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check back later for available booths',
              style: AppTypography.bodyLargeStyle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _subscribeToBooths(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: AppLayout.safeAreaPadding,
        itemCount: _booths.length,
        itemBuilder: (context, index) {
          final booth = _booths[index];
          return _buildBoothCard(booth);
        },
      ),
    );
  }

  Widget _buildMapView() {
    return Center(
      child: Text(
        'Map view coming soon...',
        style: AppTypography.bodyLargeStyle.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBoothCard(Booth booth) {
    return Container(
      margin: AppSpacing.smVertical,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.uiStroke, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BoothDetailsScreen(booth: booth),
            ),
          );
        },
        borderRadius: AppRadius.mdRadius,
        child: Padding(
          padding: AppSpacing.mdAll,
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(booth.status),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Booth info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booth.name,
                      style: AppTypography.h2Style.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      booth.location.address,
                      style: AppTypography.bodySmallStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (booth.availableServices.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Services: ${booth.availableServices.join(', ')}',
                        style: AppTypography.captionStyle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (_calculateDistanceToBooth(booth) != null) ...[
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _formatDistance(_calculateDistanceToBooth(booth)!),
                            style: AppTypography.captionStyle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Container(
                          padding: AppSpacing.xsHorizontal,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booth.status,
                            ).withOpacity(0.1),
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: Text(
                            booth.status.displayName,
                            style: AppTypography.captionStyle.copyWith(
                              color: _getStatusColor(booth.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                onPressed: () {
                  // TODO: Navigate to booth details
                },
              ),
            ],
          ),
        ),
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
}
