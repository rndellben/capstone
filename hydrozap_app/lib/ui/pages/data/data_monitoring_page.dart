import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/providers/device_provider.dart';
import 'package:hydrozap_app/ui/pages/data/live_data_screen.dart';
import 'package:hydrozap_app/ui/pages/data/historical_data_screen.dart';
import 'package:hydrozap_app/core/constants/app_colors.dart';
import 'package:hydrozap_app/ui/widgets/responsive_widget.dart';
import 'package:hydrozap_app/data/local/shared_prefs.dart';

class DataMonitoringPage extends StatefulWidget {
  const DataMonitoringPage({super.key});

  @override
  State<DataMonitoringPage> createState() => _DataMonitoringPageState();
}

class _DataMonitoringPageState extends State<DataMonitoringPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DeviceModel? _currentDevice;
  List<DeviceModel> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch devices on initialization to prevent loading delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDevices();
    });
  }

  Future<void> _fetchDevices() async {
    try {
      // Get user ID from SharedPrefs
      final userId = await SharedPrefs.getUserId();
      
      if (userId != null) {
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        // Connect WebSocket and fetch devices
        deviceProvider.connectWebSocket(userId);
        await deviceProvider.fetchDevices(userId);
      }
    } catch (e) {
      print('Error fetching devices: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDeviceChanged(DeviceModel? device) {
    if (device != null && device.id != _currentDevice?.id) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.selectDevice(device);
      
      setState(() {
        _currentDevice = device;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    
    // Get available devices
    _availableDevices = deviceProvider.devices;
    
    return StreamBuilder<List<DeviceModel>>(
      stream: deviceProvider.devicesStream,
      builder: (context, snapshot) {
        // Always use the latest device from the stream if available
        DeviceModel? latestDevice;
        
        if (snapshot.hasData) {
          final devices = snapshot.data!;
          // Update available devices
          _availableDevices = devices;
          
          // If we have a current device, find it in the stream data
          if (_currentDevice != null) {
            latestDevice = devices.firstWhere(
              (d) => d.id == _currentDevice!.id,
              orElse: () => _currentDevice!
            );
          } else if (devices.isNotEmpty) {
            // If no current device but devices are available, use the first one
            latestDevice = devices.first;
            _currentDevice = latestDevice;
            
            // Select the first device in the provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              deviceProvider.selectDevice(latestDevice!);
            });
          }
          
          // Update our current device with the latest data
          if (mounted && latestDevice != null) {
            _currentDevice = latestDevice;
          }
        }
        
        // Use the latest available device data
        final device = _currentDevice;
        
        // If no device is available, show a message
        if (device == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Data Monitoring',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textOnDark),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withBlue(AppColors.background.blue + 5)
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Devices Available',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please add a device to view data monitoring.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Data Monitoring',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textOnDark),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.leaf, AppColors.forest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.forest,
              indicatorWeight: 3,
              labelColor: AppColors.textOnDark,
              unselectedLabelColor: AppColors.textOnDark.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.timeline),
                  text: 'Live Data',
                ),
                Tab(
                  icon: Icon(Icons.history),
                  text: 'Historical Data',
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.background.withBlue(AppColors.background.blue + 5)
                ],
              ),
            ),
            child: Column(
              children: [
                // Device selector
                _buildDeviceSelector(device),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LiveDataScreen(device: device),
                      HistoricalDataScreen(device: device),
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
  
  Widget _buildDeviceSelector(DeviceModel currentDevice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.devices, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selected Device:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _availableDevices.isEmpty 
              ? Text(
                  currentDevice.deviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                )
              : DropdownButtonFormField<DeviceModel>(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  value: currentDevice,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: _availableDevices.map((device) {
                    return DropdownMenuItem<DeviceModel>(
                      value: device,
                      child: Text(
                        device.deviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onDeviceChanged,
                ),
          ),
        ],
      ),
    );
  }
} 