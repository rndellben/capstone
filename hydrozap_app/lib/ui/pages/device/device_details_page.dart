import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/device_model.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/metric_card.dart'; // Import the new custom widget
import '../../components/dosing_recommendation_card.dart'; // Import the dosing recommendation widget
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../routes/app_routes.dart';
import '../../pages/device/edit_device_page.dart';
import '../../pages/data/data_monitoring_page.dart';
import 'water_volume_setup_page.dart';

class DeviceDetailsPage extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailsPage({super.key, required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  bool _isUpdating = false;
  DeviceModel? _currentDevice;
  Timer? _refreshTimer;
  bool _isWebSocketConnected = false;

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.device;
    
    // Set up timer to refresh device data every 10 seconds as backup
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshDeviceData();
    });
    
    // Initial check of connection and data refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      setState(() {
        _isWebSocketConnected = deviceProvider.isWebSocketConnected;
      });
      _refreshDeviceData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDeviceData() async {
    if (!mounted) return;
    
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    // Update WebSocket connection status
    setState(() {
      _isWebSocketConnected = deviceProvider.isWebSocketConnected;
    });
    
    try {
      // Get latest device data
      final updatedDevice = await deviceProvider.getDeviceById(widget.device.id);
      
      if (updatedDevice != null && mounted) {
        setState(() {
          _currentDevice = updatedDevice;
        });
      }
    } catch (e) {
      print("Error refreshing device data: $e");
    }
  }

  Future<void> _navigateToEditDevice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDevicePage(device: _currentDevice ?? widget.device),
      ),
    );

    // If the device was updated, refresh the device provider
    if (result == true) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.refreshDevices();
      _refreshDeviceData();
    }
  }

  Future<void> _toggleEmergencyStop() async {
    setState(() => _isUpdating = true);
    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final device = _currentDevice ?? widget.device;
      final success = await deviceProvider.updateDevice(
        device.id,
        {"emergency_stop": !device.emergencyStop}
      );

      if (!success) {
        // Show error message if update fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update device status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Refresh device data after successful update
        _refreshDeviceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateWaterVolume() async {
    final device = _currentDevice ?? widget.device;
    
    // Navigate to water volume setup page
    final waterVolume = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => WaterVolumeSetupPage(
          onVolumeSelected: (volume) {
            Navigator.pop(context, volume);
          },
          initialVolume: device.waterVolumeInLiters,
        ),
      ),
    );
    
    // If user canceled or no change, do nothing
    if (waterVolume == null || waterVolume == device.waterVolumeInLiters) {
      return;
    }
    
    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      
      // Update just the water volume
      final updateData = {
        "water_volume_liters": waterVolume,
      };
      
      final success = await deviceProvider.updateDevice(
        device.id,
        updateData,
      );
      
      if (success) {
        // Refresh device data
        _refreshDeviceData();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tank volume updated to ${waterVolume.toStringAsFixed(1)} liters'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update tank volume'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    // Use StreamBuilder to automatically update when the device data changes
    return StreamBuilder<List<DeviceModel>>(
      stream: deviceProvider.devicesStream,
      builder: (context, snapshot) {
        // Always use the latest device from the stream if available
        DeviceModel? latestDevice;
        
        if (snapshot.hasData) {
          final devices = snapshot.data!;
          // Find our device in the stream data
          latestDevice = devices.firstWhere(
            (d) => d.id == widget.device.id,
            orElse: () => _currentDevice ?? widget.device
          );
          
          // Update our current device with the latest data
          if (mounted) {
            _currentDevice = latestDevice;
          }
        }
        
        // Use the latest available device data
        final device = _currentDevice ?? widget.device;
        
        // Extract all sensor values at once for better performance
        final latestReadings = device.getLatestSensorReadings();
        
        // Extract individual sensor values from the map
        final double waterTemperature = (latestReadings['temperature'] as num?)?.toDouble() ?? 0.0;
        final double pHLevel = (latestReadings['ph'] as num?)?.toDouble() ?? 0.0;
        final double ecLevel = (latestReadings['ec'] as num?)?.toDouble() ?? 0.0;
        final double tdsLevel = (latestReadings['tds'] as num?)?.toDouble() ?? 0.0;
        final String waterLevel = latestReadings['waterLevel']?.toString() ?? "Unknown";
        final double humidity = (latestReadings['humidity'] as num?)?.toDouble() ?? 0.0;
        final double ambientTemperature = (latestReadings['ambientTemperature'] as num?)?.toDouble() ?? 0.0;
        
        // Get the reading timestamp if available
        final DateTime readingTimestamp = latestReadings['_timestamp'] as DateTime? ?? device.lastUpdated;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              device.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // WebSocket connection indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  _isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isWebSocketConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              // Data monitoring button
              IconButton(
                icon: const Icon(Icons.analytics),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.dataMonitoring,
                    arguments: device,
                  );
                },
                tooltip: 'Data Monitoring',
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshDeviceData,
                tooltip: 'Refresh Data',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _navigateToEditDevice,
                tooltip: 'Edit Device',
              ),
            ],
          ),
          backgroundColor: AppColors.normal,
          body: RefreshIndicator(
            onRefresh: _refreshDeviceData,
            child: Column(
              children: [
                // Last updated timestamp banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  color: _isWebSocketConnected ? Colors.green.withAlpha((0.1 * 255).round()) : Colors.amber.withAlpha((0.1 * 255).round()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isWebSocketConnected ? Icons.update : Icons.sync_problem,
                        size: 14,
                        color: _isWebSocketConnected ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${_getLastUpdatedText(readingTimestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isWebSocketConnected ? Colors.green.shade700 : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: ResponsiveWidget(
                    mobile: _buildMobileLayout(
                      context,
                      waterTemperature,
                      pHLevel,
                      ecLevel,
                      tdsLevel,
                      waterLevel,
                      humidity,
                      ambientTemperature,
                    ),
                    tablet: _buildTabletLayout(
                      context,
                      waterTemperature,
                      pHLevel,
                      ecLevel,
                      tdsLevel,
                      waterLevel,
                      humidity,
                      ambientTemperature,
                    ),
                    desktop: _buildDesktopLayout(
                      context,
                      waterTemperature,
                      pHLevel,
                      ecLevel,
                      tdsLevel,
                      waterLevel,
                      humidity,
                      ambientTemperature,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Format the last updated time
  String _getLastUpdatedText(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double waterTemperature,
    double pHLevel,
    double ecLevel,
    double tdsLevel,
    String waterLevel,
    double humidity,
    double ambientTemperature,
  ) {
    final device = _currentDevice ?? widget.device;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfoCard(context),
            const SizedBox(height: 16),
            _buildSectionTitle("Sensor Data"),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _buildSensorCards(
                context,
                waterTemperature,
                pHLevel,
                ecLevel,
                tdsLevel,
                waterLevel,
                humidity,
                ambientTemperature,
              ).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildSensorCards(
                context,
                waterTemperature,
                pHLevel,
                ecLevel,
                tdsLevel,
                waterLevel,
                humidity,
                ambientTemperature,
              )[index],
            ),
            const SizedBox(height: 24),
            // Add dosing recommendation card
            DosingRecommendationCard(
              waterVolumeInLiters: device.waterVolumeInLiters,
              currentPh: pHLevel,
              currentEc: ecLevel,
              onRefresh: _navigateToEditDevice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    double waterTemperature,
    double pHLevel,
    double ecLevel,
    double tdsLevel,
    String waterLevel,
    double humidity,
    double ambientTemperature,
  ) {
    final device = _currentDevice ?? widget.device;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfoCard(context),
            const SizedBox(height: 24),
            _buildSectionTitle("Sensor Data"),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildSensorCards(
                context,
                waterTemperature,
                pHLevel,
                ecLevel,
                tdsLevel,
                waterLevel,
                humidity,
                ambientTemperature,
              ),
            ),
            const SizedBox(height: 24),
            // Add dosing recommendation card
            DosingRecommendationCard(
              waterVolumeInLiters: device.waterVolumeInLiters,
              currentPh: pHLevel,
              currentEc: ecLevel,
              onRefresh: _navigateToEditDevice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double waterTemperature,
    double pHLevel,
    double ecLevel,
    double tdsLevel,
    String waterLevel,
    double humidity,
    double ambientTemperature,
  ) {
    final device = _currentDevice ?? widget.device;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildDeviceInfoCard(context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Environmental Monitoring"), 
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              title: "Water Temperature",
                              value: "${waterTemperature.toStringAsFixed(1)}°C / ${(waterTemperature * 9 / 5 + 32).toStringAsFixed(1)}°F",
                              icon: Icons.thermostat,
                              iconColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MetricCard(
                              title: "Humidity & Temperature",
                              value: "${humidity.toStringAsFixed(1)}% RH / ${ambientTemperature.toStringAsFixed(1)}°C",
                              icon: Icons.water_drop_outlined,
                              iconColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("Sensor Data"),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  title: "pH Level",
                  value: pHLevel.toStringAsFixed(2),
                  icon: Icons.science_outlined,
                  iconColor: AppColors.secondary,
                ),
                MetricCard(
                  title: "EC Level",
                  value: "${ecLevel.toStringAsFixed(2)} mS/cm",
                  icon: Icons.bolt_outlined,
                  iconColor: AppColors.primary,
                ),
                MetricCard(
                  title: "TDS Level",
                  value: "${tdsLevel.toStringAsFixed(1)} ppm",
                  icon: Icons.opacity_outlined,
                  iconColor: AppColors.accent,
                ),
                MetricCard(
                  title: "Water Level",
                  value: waterLevel,
                  icon: Icons.water_outlined,
                  iconColor: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Add dosing recommendation card
            DosingRecommendationCard(
              waterVolumeInLiters: device.waterVolumeInLiters,
              currentPh: pHLevel,
              currentEc: ecLevel,
              onRefresh: _navigateToEditDevice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context) {
    final device = _currentDevice ?? widget.device;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Device Information"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: device.emergencyStop ? Colors.red : 
                               device.status == "on" ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        device.status == "on" ? "Online" : "Offline",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: device.emergencyStop ? Colors.red : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emergency,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Emergency Stop",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 20,
                            child: Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: device.emergencyStop,
                                onChanged: _isUpdating ? null : (value) => _toggleEmergencyStop(),
                                activeColor: Colors.white,
                                activeTrackColor: Colors.red.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Device Name", device.deviceName),
            const Divider(height: 24),
            _buildInfoRow("Device Type", device.type),
            const Divider(height: 24),
            _buildInfoRow("Kit", device.kit),
            const Divider(height: 24),
            // Add Water Volume row with update button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: Text(
                    "Tank Volume",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${device.waterVolumeInLiters.toStringAsFixed(1)} L",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _updateWaterVolume,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataSection(
    BuildContext context,
    double waterTemperature,
    double pHLevel,
    double ecLevel,
    double tdsLevel,
    String waterLevel,
    double humidity,
    double ambientTemperature,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Sensor Data"),
        const SizedBox(height: 16),
        ..._buildSensorCards(
          context,
          waterTemperature,
          pHLevel,
          ecLevel,
          tdsLevel,
          waterLevel,
          humidity,
          ambientTemperature,
        ),
      ],
    );
  }

  List<Widget> _buildSensorCards(
    BuildContext context,
    double waterTemperature,
    double pHLevel,
    double ecLevel,
    double tdsLevel,
    String waterLevel,
    double humidity,
    double ambientTemperature,
  ) {
    return [
      MetricCard(
        title: "Water Temperature",
        value: "${waterTemperature.toStringAsFixed(1)}°C / ${(waterTemperature * 9 / 5 + 32).toStringAsFixed(1)}°F",
        icon: Icons.thermostat,
        iconColor: AppColors.primary,
      ),
      MetricCard(
        title: "pH Level",
        value: pHLevel.toStringAsFixed(2),
        icon: Icons.science_outlined,
        iconColor: AppColors.secondary,
      ),
      MetricCard(
        title: "EC Level",
        value: "${ecLevel.toStringAsFixed(2)} mS/cm",
        icon: Icons.bolt_outlined,
        iconColor: AppColors.primary,
      ),
      MetricCard(
        title: "TDS Level",
        value: "${tdsLevel.toStringAsFixed(1)} ppm",
        icon: Icons.opacity_outlined,
        iconColor: AppColors.accent,
      ),
      MetricCard(
        title: "Water Level",
        value: waterLevel,
        icon: Icons.water_outlined,
        iconColor: AppColors.secondary,
      ),
      MetricCard(
        title: "Humidity & Temperature",
        value: "${humidity.toStringAsFixed(1)}% RH / ${ambientTemperature.toStringAsFixed(1)}°C",
        icon: Icons.water_drop_outlined,
        iconColor: AppColors.accent,
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}