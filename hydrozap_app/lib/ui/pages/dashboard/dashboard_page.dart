import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/device/add_device_page.dart';
import '../dashboard/device_list_page.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/notification_dropdown.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/metric_card.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/device_model.dart';
import '../device/edit_device_page.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/grow_provider.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/models/grow_profile_model.dart';
import 'dart:convert';
import '../../../core/utils/logger.dart';
import 'actuator_flush_dialog.dart';

// Alert thresholds class becomes a helper class with factory methods
class AlertThresholds {
  // Default values as fallback
  final double maxWaterTemp;
  final double minPhLevel;
  final double maxPhLevel;
  final double minEcLevel;
  final double maxEcLevel;
  final double minTdsLevel;
  final double maxTdsLevel;
  final double minHumidity;
  final double maxHumidity;
  final double lowWaterLevelPercentage;
  final String currentStage; // Add current stage tracking

  // Private constructor with default values
  AlertThresholds._({
    this.maxWaterTemp = 28.0,
    this.minPhLevel = 5.5,
    this.maxPhLevel = 6.5,
    this.minEcLevel = 1.0,
    this.maxEcLevel = 3.0,
    this.minTdsLevel = 500.0,
    this.maxTdsLevel = 1500.0,
    this.minHumidity = 40.0,
    this.maxHumidity = 80.0,
    this.lowWaterLevelPercentage = 20.0,
    this.currentStage = 'vegetative', // Default stage
  });

  // Get the appropriate stage conditions based on grow stage
  static OptimalConditions _getCurrentStageConditions(StageConditions conditions, String? growStage) {
    // Normalize the stage name to handle variations
    final normalizedStage = growStage?.toLowerCase().trim() ?? 'vegetative';
    
    switch (normalizedStage) {
      case 'transplanting':
      case 'transplant':
        return conditions.transplanting;
      case 'maturation':
      case 'flowering':
      case 'bloom':
        return conditions.maturation;
      case 'vegetative':
      case 'veg':
      default:
        return conditions.vegetative;
    }
  }

  // Determine the current stage based on grow progress
  static String _determineCurrentStage(DateTime startDate, int totalDuration, DateTime currentDate) {
    // Ensure we're working with UTC dates to avoid timezone issues
    final utcStartDate = startDate.toUtc();
    final utcCurrentDate = currentDate.toUtc();
    
    final daysSinceStart = utcCurrentDate.difference(utcStartDate).inDays;
    final progress = (daysSinceStart / totalDuration).clamp(0.0, 1.0);
    
    // Use more precise stage boundaries
    if (progress < 0.25) {
      return 'transplanting';
    } else if (progress < 0.75) {
      return 'vegetative';
    } else {
      return 'maturation';
    }
  }

  // Factory method to create thresholds from grow profile
  factory AlertThresholds.fromGrowProfile(GrowProfile? profile, {String? growStage, DateTime? startDate, int? totalDuration}) {
    if (profile == null || profile.optimalConditions == null) {
      return AlertThresholds._(); // Use defaults
    }

    // Safely create thresholds with null checks to avoid casting errors
    try {
      final conditions = profile.optimalConditions!;
      
      // Determine the current stage if not explicitly provided
      String currentStage = growStage ?? 'vegetative';
      
      // Only recalculate stage if we have both startDate and totalDuration
      if (startDate != null && totalDuration != null) {
        // Use a fixed reference time for consistent stage calculation
        final referenceTime = DateTime.now();
        currentStage = _determineCurrentStage(startDate, totalDuration, referenceTime);
      }
      
      final stageConditions = AlertThresholds._getCurrentStageConditions(conditions, currentStage);
      
      // Safely access Range properties with null checks
      return AlertThresholds._(
        maxWaterTemp: stageConditions.temperature.max ?? 28.0,
        minPhLevel: stageConditions.phRange.min ?? 5.5,
        maxPhLevel: stageConditions.phRange.max ?? 6.5,
        minEcLevel: stageConditions.ecRange.min ?? 1.0,
        maxEcLevel: stageConditions.ecRange.max ?? 3.0,
        minTdsLevel: stageConditions.tdsRange.min ?? 500.0,
        maxTdsLevel: stageConditions.tdsRange.max ?? 1500.0,
        minHumidity: stageConditions.humidity.min ?? 40.0,
        maxHumidity: stageConditions.humidity.max ?? 80.0,
        currentStage: currentStage,
      );
    } catch (e) {
      logger.e('Error creating thresholds from profile (ID: ${profile.id}): $e');
      return AlertThresholds._(); // Use defaults on error
    }
  }

  // Default thresholds when no profile is available
  factory AlertThresholds.defaults() {
    return AlertThresholds._();
  }
}

class DashboardPage extends StatefulWidget {
  final String userId;
  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late ApiService _apiService;
  bool _showDeviceDetails = false;
  Map<String, GrowProfile?> _deviceGrowProfiles = {};
  // Initialize button position to bottom right
  Offset _buttonPosition = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      // Set initial button position after layout
      _setInitialButtonPosition();
      // Start real-time dashboard updates
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.startRealtime(widget.userId);
    });
  }
  
  void _setInitialButtonPosition() {
    if (mounted) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        // Position button in bottom right with padding
        _buttonPosition = Offset(
          screenSize.width - 180, // Width of button + padding
          screenSize.height - 100, // Height from bottom
        );
      });
    }
  }
  
  // Initialize all data with error handling
  Future<void> _initializeData() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final growProvider = Provider.of<GrowProvider>(context, listen: false);
    final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
    
    // Load device data
    deviceProvider.connectWebSocket(widget.userId);
    await deviceProvider.fetchDevices(widget.userId);
    
    // Initialize grow-related data
    try {
      await growProvider.fetchGrows(widget.userId);
      await growProfileProvider.fetchGrowProfiles(widget.userId);
    } catch (e) {
      logger.e('Error loading grow data: $e');
      
      // Clear cached data
      _deviceGrowProfiles = {};
      
      // Show message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using default alert thresholds')),
        );
      }
    }
    
    // Set up device alert listener
    deviceProvider.addListener(() {
      _handleDeviceAlerts(deviceProvider, notificationProvider, growProvider, growProfileProvider);
    });
  }

  // Get active grow profile for device
  GrowProfile? _getActiveGrowProfileForDevice(String deviceId, GrowProvider growProvider, GrowProfileProvider profileProvider) {
    try {
      // Find active grow for this device
      final activeGrow = growProvider.grows.where((grow) => 
        grow.deviceId == deviceId && grow.status == 'active'
      ).toList();
      
      if (activeGrow.isEmpty) {
        return null;
      }
      
      // Get associated profile
      final profileId = activeGrow.first.profileId;
      if (profileId.isEmpty) {
        return null;
      }
      
      final profiles = profileProvider.growProfiles;
      if (profiles.isEmpty) {
        return null;
      }
      
      try {
        final profile = profiles.firstWhere((profile) => profile.id == profileId);
        return profile;
      } catch (e) {
        return null;
      }
    } catch (e) {
      logger.e('Error getting active grow profile for device $deviceId: $e');
      return null;
    }
  }

  void _handleDeviceAlerts(
    DeviceProvider deviceProvider, 
    NotificationProvider notificationProvider,
    GrowProvider growProvider,
    GrowProfileProvider growProfileProvider
  ) {
    try {
      for (final device in deviceProvider.devices) {
        try {
          // First check if device has an active grow
          final activeGrow = growProvider.grows.where((grow) => 
            grow.deviceId == device.id && grow.status == 'active'
          ).toList();
          
          // Skip alert generation if no active grow is found
          if (activeGrow.isEmpty) {
            continue;
          }
          
          // Get grow profile for this device for optimal thresholds
          GrowProfile? growProfile;
          try {
            growProfile = _deviceGrowProfiles[device.id] ?? 
              _getActiveGrowProfileForDevice(device.id, growProvider, growProfileProvider);
            
            // Cache the profile to avoid frequent lookups
            _deviceGrowProfiles[device.id] = growProfile;
          } catch (e) {
            logger.e('Error getting grow profile for device ${device.id}: $e');
          }
          
          // Get the active grow for this device
          final grow = activeGrow.first;
          
          // Get dynamic thresholds based on grow profile and current stage
          final thresholds = AlertThresholds.fromGrowProfile(
            growProfile,
            startDate: DateTime.tryParse(grow.startDate),
            totalDuration: growProfile?.growDurationDays ?? 60, // Default to 60 days if not specified
          );
          
          // Log the current stage for debugging
          logger.d('Current grow stage for device ${device.id}: ${thresholds.currentStage}');
          
          final latestReadings = device.getLatestSensorReadings();
          if (latestReadings.isEmpty) {
            continue;
          }
          
          // Water Temperature Check
          final dynamic tempValue = latestReadings['temperature'];
          final waterTemp = tempValue is num ? tempValue.toDouble() : null;
          if (waterTemp != null && waterTemp > thresholds.maxWaterTemp) {
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'temperature',
              'High Water Temperature Alert',
              'Water temperature in ${device.deviceName} is ${waterTemp.toStringAsFixed(1)}°C (${thresholds.currentStage} stage)',
              NotificationType.alert,
              {
                'temperature': waterTemp,
                'stage': thresholds.currentStage,
                'threshold': thresholds.maxWaterTemp,
              },
            );
          }

          // pH Level Check
          final dynamic phValue = latestReadings['ph'];
          final phLevel = phValue is num ? phValue.toDouble() : null;
          if (phLevel != null && (phLevel < thresholds.minPhLevel || phLevel > thresholds.maxPhLevel)) {
            final condition = phLevel < thresholds.minPhLevel ? 'low' : 'high';
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'ph_$condition',
              '${condition.toUpperCase()} pH Level Alert',
              'pH level in ${device.deviceName} is ${phLevel.toStringAsFixed(2)} (${thresholds.currentStage} stage)',
              NotificationType.warning,
              {
                'ph': phLevel,
                'stage': thresholds.currentStage,
                'min_threshold': thresholds.minPhLevel,
                'max_threshold': thresholds.maxPhLevel,
              },
            );
          }

          // EC Level Check
          final dynamic ecValue = latestReadings['ec'];
          final ecLevel = ecValue is num ? ecValue.toDouble() : null;
          if (ecLevel != null && (ecLevel < thresholds.minEcLevel || ecLevel > thresholds.maxEcLevel)) {
            final condition = ecLevel < thresholds.minEcLevel ? 'low' : 'high';
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'ec_$condition',
              '${condition.toUpperCase()} EC Level Alert',
              'EC level in ${device.deviceName} is ${ecLevel.toStringAsFixed(2)} mS/cm (${thresholds.currentStage} stage)',
              NotificationType.warning,
              {
                'ec': ecLevel,
                'stage': thresholds.currentStage,
                'min_threshold': thresholds.minEcLevel,
                'max_threshold': thresholds.maxEcLevel,
              },
            );
          }

          // TDS Level Check
          final dynamic tdsValue = latestReadings['tds'];
          final tdsLevel = tdsValue is num ? tdsValue.toDouble() : null;
          if (tdsLevel != null && (tdsLevel < thresholds.minTdsLevel || tdsLevel > thresholds.maxTdsLevel)) {
            final condition = tdsLevel < thresholds.minTdsLevel ? 'low' : 'high';
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'tds_$condition',
              '${condition.toUpperCase()} TDS Level Alert',
              'TDS level in ${device.deviceName} is ${tdsLevel.toStringAsFixed(0)} ppm (${thresholds.currentStage} stage)',
              NotificationType.warning,
              {
                'tds': tdsLevel,
                'stage': thresholds.currentStage,
                'min_threshold': thresholds.minTdsLevel,
                'max_threshold': thresholds.maxTdsLevel,
              },
            );
          }

          // Water Level Check
          final dynamic waterLevelValue = latestReadings['waterLevel'];
          final waterLevel = waterLevelValue?.toString();
          if (waterLevel != null) {
            bool isLow = waterLevel == 'Low';
            if (!isLow && waterLevel.endsWith('%')) {
              final percentage = double.tryParse(waterLevel.replaceAll('%', ''));
              isLow = percentage != null && percentage < thresholds.lowWaterLevelPercentage;
            }
            if (isLow) {
              _addAlert(
                notificationProvider,
                device.id,
                device.deviceName,
                'water_level',
                'Low Water Level Alert',
                'Water level in ${device.deviceName} is $waterLevel (${thresholds.currentStage} stage)',
                NotificationType.alert,
                {
                  'water_level': waterLevel,
                  'stage': thresholds.currentStage,
                  'threshold': thresholds.lowWaterLevelPercentage,
                },
              );
            }
          }

          // Humidity Check
          final dynamic humidityValue = latestReadings['humidity'];
          final humidity = humidityValue is num ? humidityValue.toDouble() : null;
          if (humidity != null && (humidity < thresholds.minHumidity || humidity > thresholds.maxHumidity)) {
            final condition = humidity < thresholds.minHumidity ? 'low' : 'high';
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'humidity_$condition',
              '${condition.toUpperCase()} Humidity Alert',
              'Humidity in ${device.deviceName} is ${humidity.toStringAsFixed(1)}% (${thresholds.currentStage} stage)',
              NotificationType.warning,
              {
                'humidity': humidity,
                'stage': thresholds.currentStage,
                'min_threshold': thresholds.minHumidity,
                'max_threshold': thresholds.maxHumidity,
              },
            );
          }

          // Crop Readiness Check
          final cropReady = latestReadings['cropReady'] == true;
          if (cropReady) {
            _addAlert(
              notificationProvider,
              device.id,
              device.deviceName,
              'crop_ready',
              'Crop Ready',
              'Your crop in ${device.deviceName} is ready for the next stage!',
              NotificationType.info,
              {
                'crop_ready': true,
                'stage': thresholds.currentStage,
              },
            );
          }
        } catch (deviceError) {
          // Catch any errors for a single device but allow other devices to be processed
        }
      }
    } catch (e) {
    }
  }

  void _addAlert(
    NotificationProvider provider,
    String deviceId,
    String deviceName,
    String alertType,
    String title,
    String message,
    NotificationType type,
    Map<String, dynamic> data,
  ) {
    provider.addNotification(
      AppNotification(
        id: '${alertType}_${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        deviceId: deviceId,
        alertType: alertType,
        data: {
          ...data,
          'user_id': widget.userId,
        },
      ),
    );
  }

  @override
  void dispose() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.disconnectWebSocket();
    // Stop real-time dashboard updates
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.stopRealtime();
    // Clear cached grow profiles
    _deviceGrowProfiles.clear();
    super.dispose();
  }

  void _toggleDeviceDetails() {
    setState(() {
      _showDeviceDetails = !_showDeviceDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    // Ensure we have required providers
    Provider.of<GrowProvider>(context, listen: false);
    Provider.of<GrowProfileProvider>(context, listen: false);

    return Scaffold(
      appBar: ResponsiveWidget.isDesktop(context) 
          ? null 
          : _buildAppBar(context, deviceProvider),
      drawer: ResponsiveWidget.isDesktop(context) ? null : AppDrawer(userId: widget.userId),
      body: ResponsiveWidget(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DeviceProvider deviceProvider) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.forest,
      leading: ResponsiveWidget.isMobile(context) && _showDeviceDetails
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _toggleDeviceDetails,
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, color: AppColors.secondary),
          const SizedBox(width: 8),
          Flexible(
            child: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_showDeviceDetails) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${dashboardProvider.deviceCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                provider.isWebSocketConnected 
                    ? Icons.wifi : Icons.wifi_off,
                color: provider.isWebSocketConnected 
                    ? Colors.green : Colors.red,
                size: 20,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () => deviceProvider.refreshDevices(),
        ),
        if (!_showDeviceDetails)
          Container(
            alignment: Alignment.center,
            child: const NotificationDropdown(),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (_showDeviceDetails && deviceProvider.selectedDevice != null) {
          return _buildInfoPanel(context);
        }
        final dashboardProvider = Provider.of<DashboardProvider>(context);
        return Column(
          children: [
            if (!_showDeviceDetails)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.water_drop,
                        dashboardProvider.deviceCount.toString(),
                        'Devices',
                        Colors.blue.shade400, Colors.blue.shade700, Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        Icons.grain_rounded,
                        dashboardProvider.growCount.toString(),
                        'Grows',
                        Colors.green.shade400, Colors.green.shade700, Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        Icons.notifications_active,
                        dashboardProvider.alertCount.toString(),
                        'Alerts',
                        Colors.red.shade400, Colors.red.shade700, Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: !_showDeviceDetails
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildYourDevicesSection(context),
                      ),
                    )
                  : DeviceListPage(
                userId: widget.userId,
                onDeviceSelected: () {
                  _toggleDeviceDetails();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.water_drop,
                          dashboardProvider.deviceCount.toString(),
                          'Devices',
                          Colors.blue.shade400, Colors.blue.shade700, Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.grain_rounded,
                          dashboardProvider.growCount.toString(),
                          'Grows',
                          Colors.green.shade400, Colors.green.shade700, Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.notifications_active,
                          dashboardProvider.alertCount.toString(),
                          'Alerts',
                          Colors.red.shade400, Colors.red.shade700, Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildYourDevicesSection(context),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Device Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Consumer<DeviceProvider>(
                          builder: (context, provider, _) {
                            final selectedDevice = provider.selectedDevice;
                            return selectedDevice == null
                                ? _buildNoDeviceSelected()
                                : _buildDeviceDetails(selectedDevice);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppDrawer(userId: widget.userId),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          _buildRefreshButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.water_drop,
                              dashboardProvider.deviceCount.toString(),
                              'Devices',
                              Colors.blue.shade400, Colors.blue.shade700, Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              Icons.grain_rounded,
                              dashboardProvider.growCount.toString(),
                              'Grows',
                              Colors.green.shade400, Colors.green.shade700, Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              Icons.notifications_active,
                              dashboardProvider.alertCount.toString(),
                              'Alerts',
                              Colors.red.shade400, Colors.red.shade700, Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Devices and Details Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Devices List Section (Redesigned)
                    Expanded(
                      flex: 3,
                      child: _buildYourDevicesSection(context),
                    ),
                    const SizedBox(width: 24),
                    // Device Details Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Device Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Consumer<DeviceProvider>(
                              builder: (context, provider, _) {
                                final selectedDevice = provider.selectedDevice;
                                return selectedDevice == null
                                    ? _buildNoDeviceSelected()
                                    : _buildDeviceDetails(selectedDevice);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
          deviceProvider.refreshDevices();
        },
        tooltip: 'Refresh',
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildNoDeviceSelected() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a device to view details',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDetails(DeviceModel device) {
    final latestReadings = device.getLatestSensorReadings();
    final isEmergency = device.emergencyStop; // Use the boolean property

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Indicator
          Row(
            children: [
              _buildDeviceStatusBox(device),
            ],
          ),
          const SizedBox(height: 16),
          // Auto Dose Toggle
          _buildAutoDoseToggle(device),
          const SizedBox(height: 16),
          // Flush Actuators Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.water_drop),
              label: const Text('Flush Actuators'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmergency ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isEmergency
                  ? null // Disable button if emergency stop is active
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => ActuatorFlushDialog(
                          device: device,
                          onFlushActuator: (actuatorId, duration) {
                            final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                            deviceProvider.flushActuator(device.id, actuatorId, duration: duration);
                          },
                        ),
                      );
                    },
            ),
          ),
          const SizedBox(height: 24),
          // Sensor Readings
          Text(
            'Sensor Readings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSensorGrid(latestReadings),
          const SizedBox(height: 20),
          // Connection Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connection Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, _) => Icon(
                    deviceProvider.isWebSocketConnected ? Icons.update : Icons.sync_problem,
                    size: 14,
                    color: deviceProvider.isWebSocketConnected ? Colors.green : Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Last updated: ${_getLastUpdatedText(device.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Flush Actuators Button for Mobile
          if (MediaQuery.of(context).size.width < 600)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isEmergency
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => ActuatorFlushDialog(
                              device: device,
                              onFlushActuator: (actuatorId, duration) {
                                final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                                deviceProvider.flushActuator(device.id, actuatorId, duration: duration);
                              },
                            ),
                          );
                        },
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Flush Actuators'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergency ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusBox(DeviceModel device) {
    final isEmergency = device.emergencyStop; // Use the boolean property
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEmergency ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isEmergency ? Icons.warning : Icons.check_circle,
            color: isEmergency ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isEmergency ? 'Emergency Stop Engaged' : 'Operational & Synced',
            style: TextStyle(
              color: isEmergency ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDoseToggle(DeviceModel device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_fix_high,
            color: device.autoDoseEnabled ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto Dose',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.autoDoseEnabled 
                    ? 'Automatically adjust nutrients based on sensor readings'
                    : 'Manual dosing only - no automatic adjustments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: device.autoDoseEnabled,
            onChanged: (bool value) async {
              final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
              final success = await deviceProvider.updateDevice(
                device.id,
                {"auto_dose_enabled": value}
              );
              
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update auto dose setting'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            activeColor: Colors.green,
            activeTrackColor: Colors.green.shade200,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(Map<String, dynamic> readings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the optimal aspect ratio based on available width
        final double tileWidth = (constraints.maxWidth - 16) / 2; // 2 columns with 16px spacing
        final double aspectRatio = tileWidth / 120; // Assuming 120px is a good height

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildSensorTile(
              'Temperature',
              '${(readings['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'}°C',
              Icons.thermostat,
              Colors.orange,
            ),
            _buildSensorTile(
              'pH Level',
              '${(readings['ph'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
              Icons.science,
              Colors.blue,
            ),
            _buildSensorTile(
              'EC Level',
              '${(readings['ec'] as num?)?.toStringAsFixed(2) ?? 'N/A'} mS/cm',
              Icons.bolt,
              Colors.purple,
            ),
            _buildSensorTile(
              'TDS Level',
              '${(readings['tds'] as num?)?.toStringAsFixed(0) ?? 'N/A'} ppm',
              Icons.opacity,
              Colors.green,
            ),
            _buildSensorTile(
              'Humidity',
              '${(readings['humidity'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
              Icons.water_drop,
              Colors.lightBlue,
            ),
            _buildSensorTile(
              'Water Level',
              readings['waterLevel']?.toString() ?? 'N/A',
              Icons.water,
              Colors.cyan,
            ),
          ],
        );
      }
    );
  }

  Widget _buildSensorTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYourDevicesSection(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final devices = deviceProvider.devices;
    final selectedFilter = ValueNotifier<String>('All');

    List<DeviceModel> filteredDevices(String filter) {
      if (filter == 'Online') {
        return devices.where((d) => d.status == 'on' || d.status == 'in_use' || d.status == 'available').toList();
      } else if (filter == 'Offline') {
        return devices.where((d) => !(d.status == 'on' || d.status == 'in_use' || d.status == 'available')).toList();
      }
      return devices;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Your Devices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter Bar
              Row(
                children: [
                  ...['All', 'Online', 'Offline'].map((filter) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ValueListenableBuilder<String>(
                      valueListenable: selectedFilter,
                      builder: (context, value, _) => ChoiceChip(
                        label: Text(filter),
                        selected: value == filter,
                        onSelected: (_) => setState(() => selectedFilter.value = filter),
                        selectedColor: AppColors.secondary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: value == filter ? AppColors.secondary : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              // Device Cards
              ValueListenableBuilder<String>(
                valueListenable: selectedFilter,
                builder: (context, value, _) {
                  final filtered = filteredDevices(value);
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No devices found.')),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final device = filtered[idx];
                      final isSelected = deviceProvider.selectedDevice?.id == device.id;
                      return InkWell(
                        onTap: () {
                          deviceProvider.selectDevice(device);
                          if (MediaQuery.of(context).size.width < 900) {
                            _toggleDeviceDetails();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.secondary.withOpacity(0.15)
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.secondary
                                  : AppColors.secondary.withOpacity(0.15),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.secondary
                                      : AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.devices, 
                                  color: isSelected ? Colors.white : AppColors.secondary, 
                                  size: 28
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.deviceName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      device.kit ?? '',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (device.status == 'on' || device.status == 'in_use' || device.status == 'available') ? Colors.green.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  (device.status == 'on' || device.status == 'in_use' || device.status == 'available') ? 'Active' : 'Offline',
                                  style: TextStyle(
                                    color: (device.status == 'on' || device.status == 'in_use' || device.status == 'available') ? Colors.green.shade900 : Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Edit Device',
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.black45, size: 20),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditDevicePage(device: device),
                                      ),
                                    );
                                    if (result == true) {
                                      deviceProvider.refreshDevices();
                                    }
                                  },
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              else
                                Icon(Icons.chevron_right, color: Colors.black26),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              // Add New Device Button (wide)
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddDevicePage(userId: widget.userId)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.leaf, AppColors.forest],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Add New Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    // Get the currently selected device from your provider
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final selectedDevice = deviceProvider.selectedDevice;
    
    // If no device is selected, show a placeholder
    if (selectedDevice == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.devices_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Select a device to view details',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Extract sensor values from the selected device
    final latestReadings = selectedDevice.getLatestSensorReadings();
    final isEmergency = selectedDevice.emergencyStop;
    // Get the last updated timestamp
    final DateTime lastUpdated = selectedDevice.lastUpdated;

    return Container(
      padding: EdgeInsets.zero,
      color: Colors.white.withOpacity(0.98), // light/transparent background
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Indicator (add here)
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
              child: _buildDeviceStatusBox(selectedDevice),
            ),
            // Auto Dose Toggle
            _buildAutoDoseToggle(selectedDevice),
            const SizedBox(height: 16),
            // Top Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (!isMobile) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Device Details:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppColors.primary,
                        tooltip: 'Edit Device',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDevicePage(device: selectedDevice),
                            ),
                          );
                          if (result == true) {
                            deviceProvider.refreshDevices();
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        tooltip: 'Delete Device',
                        onPressed: () => _showDeleteDeviceConfirmation(context, selectedDevice, deviceProvider),
                      ),
                    ],
                  );
                }
                // --- New Mobile Design (no image, light background) ---
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Container(
                      color: Colors.white.withOpacity(0.98),
                      padding: const EdgeInsets.only(top: 36, left: 8, right: 8, bottom: 12),
                      child: Row(
                        children: [
                          const Spacer(),
                          Text(
                            'Device Details',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(width: 40), // for symmetry
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDevice.deviceName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Model: ${selectedDevice.kit}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedDevice.status == 'on' || selectedDevice.status == 'in_use' || selectedDevice.status == 'available'
                                    ? Colors.green.shade50
                                    : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.wifi, color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      (selectedDevice.status == 'on' || selectedDevice.status == 'in_use' || selectedDevice.status == 'available') ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: (selectedDevice.status == 'on' || selectedDevice.status == 'in_use' || selectedDevice.status == 'available') ? Colors.green.shade900 : Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Water Volume',
                                style: const TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedDevice.waterVolumeInLiters.toStringAsFixed(0)} L',
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Text(
                'Sensor Readings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSensorGrid(latestReadings),
            ),
            const SizedBox(height: 20),
            // Connection Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Connection Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Consumer<DeviceProvider>(
                    builder: (context, deviceProvider, _) => Icon(
                      deviceProvider.isWebSocketConnected ? Icons.update : Icons.sync_problem,
                      size: 14,
                      color: deviceProvider.isWebSocketConnected ? Colors.green : Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last updated: ${_getLastUpdatedText(lastUpdated)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Flush Actuators Button for Mobile
            if (MediaQuery.of(context).size.width < 600)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isEmergency
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => ActuatorFlushDialog(
                                device: selectedDevice,
                                onFlushActuator: (actuatorId, duration) {
                                  final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                                  deviceProvider.flushActuator(selectedDevice.id, actuatorId, duration: duration);
                                },
                              ),
                            );
                          },
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Flush Actuators'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmergency ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _getLastUpdatedText(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  void _showDeleteDeviceConfirmation(BuildContext context, DeviceModel device, DeviceProvider deviceProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete device "${device.deviceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((value) async {
      if (value == true) {
        final success = await deviceProvider.deleteDevice(device.id, widget.userId);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Device deleted successfully'), backgroundColor: Colors.green),
            );
          }
          deviceProvider.refreshDevices();
          // Go back to device list view
          setState(() {
            _showDeviceDetails = false;
          });
        } else {
          if (mounted) {
            // Show appropriate error message in a dialog
            String errorMsg = deviceProvider.errorMessage ?? 'Failed to delete device';
            
            // Handle specific case of device being in use
            if (errorMsg.contains('assigned to') || errorMsg.contains('active grow')) {
              errorMsg = 'This device is currently assigned to one or more grows and cannot be deleted. Please harvest or deactivate the grows first.';
            }
            
            // Parse the active grows from the error message if available
            List<String> activeGrows = [];
            try {
              if (deviceProvider.errorMessage != null && deviceProvider.errorMessage!.contains('active_grows')) {
                // Try to extract the active_grows part
                final regex = RegExp(r'"active_grows":\[(.*?)\]');
                final match = regex.firstMatch(deviceProvider.errorMessage!);
                
                if (match != null && match.groupCount >= 1) {
                  final growsJson = '[${match.group(1)}]';
                  final growsList = jsonDecode(growsJson);
                  
                  activeGrows = growsList.map<String>((grow) => 
                    '• ${grow['grow_name']} (ID: ${grow['grow_id']})'
                  ).toList().cast<String>();
                }
              }
            } catch (e) {
              logger.e('Error parsing active grows: $e');
            }
            
            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cannot Delete Device', style: TextStyle(color: Colors.red)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMsg),
                    if (activeGrows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Active grows:'),
                      const SizedBox(height: 8),
                      ...activeGrows.map((grow) => Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(grow),
                      )),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    });
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color gradientStart, Color gradientEnd, Color fgColor) {
    return Card(
      elevation: 2,
      color: Colors.transparent, // Use transparent to allow gradient
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool useCompactLayout = constraints.maxWidth < 120;
              return useCompactLayout
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: fgColor, size: 22),
                      const SizedBox(height: 6),
                      Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fgColor), textAlign: TextAlign.center),
                      Text(label, style: TextStyle(fontSize: 12, color: fgColor), textAlign: TextAlign.center),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: fgColor, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fgColor), overflow: TextOverflow.ellipsis),
                            Text(label, style: TextStyle(fontSize: 12, color: fgColor), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  );
            },
          ),
        ),
      ),
    );
  }
}