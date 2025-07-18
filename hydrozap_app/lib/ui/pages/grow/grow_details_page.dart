import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../core/models/grow_model.dart';
import '../../../core/constants/app_colors.dart';
import '../harvest/harvest_log_page.dart';
import '../../components/metric_card.dart';
import '../../widgets/responsive_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_service.dart';
import '../../../core/models/grow_profile_model.dart';
import '../../../providers/grow_profile_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/api/endpoints.dart';
import 'dart:async';
import '../../../core/models/device_model.dart';
import '../../../providers/device_provider.dart';

class GrowDetailsPage extends StatefulWidget {
  final Grow grow;
  final String deviceName;
  final String profileName;
  final int growDuration;
  final bool showHarvestOnLoad;

  const GrowDetailsPage({
    super.key,
    required this.grow,
    required this.deviceName,
    required this.profileName,
    this.growDuration = 60,
    this.showHarvestOnLoad = false,
  });

  @override
  State<GrowDetailsPage> createState() => _GrowDetailsPageState();
}

class _GrowDetailsPageState extends State<GrowDetailsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHarvestReady = false;
  bool _isCheckingHarvest = false;
  String? _harvestMessage;
  Map<String, dynamic>? _currentMetrics;
  GrowProfile? _growProfile;
  bool _isLoadingMetrics = true;
  Timer? _metricsTimer;
  Timer? _progressTimer;
  double _currentProgress = 0.0;
  DeviceModel? _device;
  double? _backendProgress;
  int? _backendDaysSinceStart;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _checkHarvestReadiness();
    _loadGrowProfile();
    _loadDeviceAndMetrics();
    
    // Set up periodic metrics refresh
    _metricsTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadDeviceAndMetrics();
    });

    // Set up periodic progress update (every minute)
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateProgress();
    });

    // If showHarvestOnLoad is true, trigger the harvest dialog after build
    if (widget.showHarvestOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHarvestLog();
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _metricsTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkHarvestReadiness() async {
    setState(() {
      _isCheckingHarvest = true;
    });

    try {
      final apiService = ApiService();
      if (widget.grow.growId == null) {
        setState(() {
          _isHarvestReady = false;
          _harvestMessage = 'Invalid grow ID';
        });
        return;
      }
      final result = await apiService.checkHarvestReadiness(widget.grow.growId!);
      
      // Store backend progress and days_since_start if available
      setState(() {
        _backendProgress = (result['progress'] as num?)?.toDouble();
        _backendDaysSinceStart = (result['days_since_start'] as num?)?.toInt();
      });
      
      if (result.containsKey('error')) {
        setState(() {
          _isHarvestReady = false;
          _harvestMessage = result['message'] ?? 'Failed to check harvest readiness';
        });
      } else {
        setState(() {
          _isHarvestReady = result['ready'] ?? false;
          _harvestMessage = result['message'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _isHarvestReady = false;
        _harvestMessage = 'Error checking harvest readiness';
      });
    } finally {
      setState(() {
        _isCheckingHarvest = false;
      });
    }
  }

  Future<void> _loadGrowProfile() async {
    try {
      final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
      await growProfileProvider.fetchGrowProfiles(widget.grow.userId);
      
      if (mounted) {
        setState(() {
          _growProfile = growProfileProvider.growProfiles.firstWhere(
            (profile) => profile.id == widget.grow.profileId,
            orElse: () => GrowProfile(
              id: widget.grow.profileId,
              userId: widget.grow.userId,
              name: '',
              plantProfileId: '',
              growDurationDays: 0,
              isActive: false,
              optimalConditions: StageConditions(
                transplanting: OptimalConditions(
                  temperature: Range(min: 18.0, max: 22.0),
                  humidity: Range(min: 60.0, max: 75.0),
                  phRange: Range(min: 5.5, max: 6.5),
                  ecRange: Range(min: 1.2, max: 1.8),
                  tdsRange: Range(min: 600, max: 900),
                ),
                vegetative: OptimalConditions(
                  temperature: Range(min: 20.0, max: 25.0),
                  humidity: Range(min: 50.0, max: 70.0),
                  phRange: Range(min: 5.8, max: 6.2),
                  ecRange: Range(min: 1.5, max: 2.0),
                  tdsRange: Range(min: 800, max: 1200),
                ),
                maturation: OptimalConditions(
                  temperature: Range(min: 22.0, max: 26.0),
                  humidity: Range(min: 45.0, max: 65.0),
                  phRange: Range(min: 6.0, max: 6.5),
                  ecRange: Range(min: 1.8, max: 2.2),
                  tdsRange: Range(min: 1000, max: 1500),
                ),
              ),
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadDeviceAndMetrics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.fetchDevices(widget.grow.userId);
      
      if (mounted) {
        setState(() {
          _device = deviceProvider.devices.firstWhere(
            (device) => device.id == widget.grow.deviceId,
            orElse: () => DeviceModel(
              id: widget.grow.deviceId ?? '',
              userId: widget.grow.userId,
              deviceName: widget.deviceName,
              type: '',
              kit: '',
              status: 'off',
              emergencyStop: false,
              sensors: {},
              actuators: {},
              lastUpdated: DateTime.now(),
            ),
          );
          _currentMetrics = _device?.getLatestSensorReadings();
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMetrics = false;
        });
      }
    }
  }

  void _updateProgress() {
    if (!mounted) return;

    final startDateTime = DateTime.tryParse(widget.grow.startDate);
    if (startDateTime == null) return;

    final now = DateTime.now();
    final totalDuration = Duration(days: widget.growDuration);
    final elapsedDuration = now.difference(startDateTime);
    
    // Calculate current day (1-based)
    final currentDay = elapsedDuration.inDays + 1;
    
    // Calculate progress using days for more accurate representation
    final progress = (currentDay / widget.growDuration).clamp(0.0, 1.0);
    
    setState(() {
      _currentProgress = progress;
    });
  }

  String _getCurrentStage() {
    final startDateTime = DateTime.tryParse(widget.grow.startDate);
    if (startDateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final daysElapsed = now.difference(startDateTime).inDays;
    final progress = (daysElapsed / widget.growDuration).clamp(0.0, 1.0);
    
    if (progress < 0.25) {
      return 'Transplanting';
    } else if (progress < 0.75) {
      return 'Vegetative';
    } else {
      return 'Maturation';
    }
  }

  bool _isStageCompleted(String stage) {
    final startDateTime = DateTime.tryParse(widget.grow.startDate);
    if (startDateTime == null) return false;
    
    final now = DateTime.now();
    final daysElapsed = now.difference(startDateTime).inDays;
    final progress = (daysElapsed / widget.growDuration).clamp(0.0, 1.0);
    
    switch (stage) {
      case 'Transplanting':
        return progress >= 0.25;
      case 'Vegetative':
        return progress >= 0.75;
      case 'Maturation':
        return progress >= 1.0;
      default:
        return false;
    }
  }

  void _navigateToHarvestLog({bool force = false}) {
    if (!force && !_isHarvestReady) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Ready for Harvest'),
          content: Text(_harvestMessage ?? 'Grow is not ready for harvest'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HarvestLogPage(
          deviceId: widget.grow.deviceId ?? '',
          growId: widget.grow.growId ?? '',
          showDialogOnLoad: true,
          cropName: widget.profileName,
          isForcedHarvest: force,
        ),
      ),
    ).then((_) async {
      // After returning from harvest log, update grow status and navigate back
      if (widget.grow.growId != null) {
        try {
          final apiService = ApiService();
          final updatedGrow = widget.grow.copyWith(
            status: 'harvested',
            harvestDate: DateTime.now().toIso8601String(),
          );
          
          await apiService.updateGrow(updatedGrow);
          
          // Navigate back to grow list
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating grow status: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'Invalid date';
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Grow Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.primary.withAlpha((0.7 * 255).round()),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
            ),
          ),
          
          // Animated leaf patterns in background
          ...List.generate(5, (index) {
            return Positioned(
              left: MediaQuery.of(context).size.width * (index * 0.2),
              top: MediaQuery.of(context).size.height * (index * 0.15 % 1),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: math.sin(_controller.value * math.pi * 2 + index) * 0.05,
                    child: Opacity(
                      opacity: 0.07 + (index * 0.01),
                      child: Icon(
                        Icons.eco,
                        size: 100 + (index * 30),
                        color: AppColors.accent,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Main content
          ResponsiveWidget(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 24),
                _buildMetricsGrid(context),
                const SizedBox(height: 24),
                _buildTimelineCard(context),
                const SizedBox(height: 24),
                _buildActionsCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: _buildMetricsGrid(context),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: _buildTimelineCard(context),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: _buildActionsCard(context),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 50),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: _buildMetricsGrid(context),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: _buildTimelineCard(context),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: _buildActionsCard(context),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((0.3 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Leaf decoration
          Positioned(
            right: -20,
            top: -30,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                Icons.spa,
                size: 150,
                color: Colors.white,
              ),
            ),
          ),
          
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profileName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round()), width: 1),
                    ),
                    child: Text(
                      'Started: ${_formatDate(widget.grow.startDate)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    // Use backend values if available, else fallback to local calculation
    double progress = _backendProgress != null ? _backendProgress! / 100.0 : _currentProgress;
    int currentDay = _backendDaysSinceStart != null ? _backendDaysSinceStart! + 1 : (() {
      final startDateTime = DateTime.tryParse(widget.grow.startDate);
      final now = DateTime.now();
      return startDateTime != null ? now.difference(startDateTime).inDays + 1 : 1;
    })();
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (widget.grow.status == 'harvested' || widget.grow.harvestDate != null) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Harvested';
    } else if (progress >= 1.0) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
      statusText = 'Ready for Harvest';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.spa;
      statusText = 'In Progress';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              statusColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profileName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: statusColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Day $currentDay of ${widget.growDuration}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final currentStage = _getCurrentStage();
    final stageConditions = _growProfile?.optimalConditions;
    
    OptimalConditions? currentConditions;
    if (stageConditions != null) {
      switch (currentStage) {
        case 'Transplanting':
          currentConditions = stageConditions.transplanting;
          break;
        case 'Vegetative':
          currentConditions = stageConditions.vegetative;
          break;
        case 'Maturation':
          currentConditions = stageConditions.maturation;
          break;
      }
    }

    if (currentConditions == null) {
      return const Center(
        child: Text('No target parameters available for this stage.'),
      );
    }

    String formatRange(Range range, {String? unit}) {
      if (unit != null) {
        return '${range.min.toStringAsFixed(1)} - ${range.max.toStringAsFixed(1)}$unit';
      } else {
        return '${range.min.toStringAsFixed(1)} - ${range.max.toStringAsFixed(1)}';
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          title: 'Temperature',
          value: formatRange(currentConditions.temperature, unit: '°C'),
          icon: Icons.thermostat,
          iconColor: Colors.orange,
        ),
        MetricCard(
          title: 'Humidity',
          value: formatRange(currentConditions.humidity, unit: '%'),
          icon: Icons.water_drop,
          iconColor: Colors.blue,
        ),
        MetricCard(
          title: 'pH Level',
          value: formatRange(currentConditions.phRange),
          icon: Icons.science,
          iconColor: Colors.purple,
        ),
        MetricCard(
          title: 'EC',
          value: formatRange(currentConditions.ecRange),
          icon: Icons.electric_bolt,
          iconColor: Colors.yellow,
        ),
      ],
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    final currentStage = _getCurrentStage();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                Icon(
                  Icons.history,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Grow Timeline',
              style: TextStyle(
                    fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimelineItem(
              icon: Icons.play_circle,
              title: 'Started',
              date: _formatDate(widget.grow.startDate),
              isCompleted: true,
            ),
            _buildTimelineItem(
              icon: Icons.grass,
              title: 'Transplanting Stage',
              date: 'Day 1-${(widget.growDuration * 0.25).round()}',
              isCompleted: _isStageCompleted('Transplanting'),
              isCurrent: currentStage == 'Transplanting',
            ),
            _buildTimelineItem(
              icon: Icons.eco,
              title: 'Vegetative Stage',
              date: 'Day ${(widget.growDuration * 0.25).round()}-${(widget.growDuration * 0.75).round()}',
              isCompleted: _isStageCompleted('Vegetative'),
              isCurrent: currentStage == 'Vegetative',
            ),
            _buildTimelineItem(
              icon: Icons.spa,
              title: 'Maturation Stage',
              date: 'Day ${(widget.growDuration * 0.75).round()}-${widget.growDuration}',
              isCompleted: _isStageCompleted('Maturation'),
              isCurrent: currentStage == 'Maturation',
            ),
            _buildTimelineItem(
              icon: Icons.check_circle,
              title: 'Harvest',
              date: widget.grow.harvestDate != null ? _formatDate(widget.grow.harvestDate!) : 'Pending',
              isCompleted: widget.grow.status == 'harvested' || widget.grow.harvestDate != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String date,
    required bool isCompleted,
    bool isCurrent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
      children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? AppColors.accent 
                  : isCompleted 
                      ? AppColors.primary 
                      : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCurrent || isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
            style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isCurrent 
                        ? AppColors.accent 
                        : isCompleted 
                            ? AppColors.textPrimary 
                            : Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                    style: TextStyle(
                      fontSize: 14,
                    color: isCurrent 
                        ? AppColors.accent 
                        : isCompleted 
                            ? AppColors.textSecondary 
                            : Colors.grey[500],
                  ),
                ),
                ],
              ),
            ),
          
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
            const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
            const SizedBox(height: 20),
            if (widget.grow.status != 'harvested' && widget.grow.harvestDate == null)
              ElevatedButton.icon(
                onPressed: () => _navigateToHarvestLog(),
                icon: const Icon(Icons.grass),
                label: const Text('Start Harvest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Force Harvest?'),
                    content: const Text('Are you sure you want to harvest? The grow is not ready yet.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                );
                if (proceed == true) {
                  _navigateToHarvestLog(force: true);
                }
              },
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Force Harvest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
