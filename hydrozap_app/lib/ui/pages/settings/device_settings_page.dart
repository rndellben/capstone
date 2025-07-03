import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/device_config_service.dart';
import '../../../core/services/network_discovery_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/connectivity_status_bar.dart';
import '../../../core/utils/logger.dart';

class DeviceSettingsPage extends StatefulWidget {
  final String userId;
  
  const DeviceSettingsPage({super.key, required this.userId});

  @override
  _DeviceSettingsPageState createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  final DeviceConfigService _deviceConfigService = DeviceConfigService();
  final NetworkDiscoveryService _networkDiscoveryService = NetworkDiscoveryService();
  final TextEditingController _espIpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _showConnectivityBar = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    
    // Hide connectivity bar after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showConnectivityBar = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _espIpController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentIp = await _deviceConfigService.getEspIpAddress();
      _espIpController.text = currentIp;
    } catch (e) {
      logger.e('Error loading device settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ipAddress = _espIpController.text.trim();
      
      // Validate IP address format
      if (!_deviceConfigService.isValidIpAddress(ipAddress)) {
        throw Exception('Invalid IP address format');
      }

      final success = await _deviceConfigService.setEspIpAddress(ipAddress);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device settings saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('Failed to save settings');
      }
    } catch (e) {
      logger.e('Error saving device settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToDefault() {
    final defaultIp = _deviceConfigService.getDefaultEspIpAddress();
    _espIpController.text = defaultIp;
  }

  void _discoverDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      logger.i('Starting device discovery...');
      
      final discoveredDevices = await _networkDiscoveryService.discoverEspDevices();
      
      if (discoveredDevices.isNotEmpty) {
        // Show device selection dialog
        if (mounted) {
          _showDeviceSelectionDialog(discoveredDevices);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No ESP8266 devices found on the network'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Error during device discovery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error discovering devices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleDiscoverDevices() {
    _discoverDevices();
  }

  void _showDeviceSelectionDialog(List<DiscoveredDevice> devices) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select ESP8266 Device'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: const Icon(Icons.computer, color: AppColors.primary),
                  title: Text(device.displayName),
                  subtitle: Text(device.ipAddress),
                  onTap: () {
                    _espIpController.text = device.ipAddress;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected device: ${device.ipAddress}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: AppDrawer(userId: widget.userId),
      body: Column(
        children: [
          // Show connectivity status bar with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showConnectivityBar ? null : 0,
            child: AnimatedOpacity(
              opacity: _showConnectivityBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const ConnectivityStatusBar(),
            ),
          ),
          
          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withAlpha((0.1 * 255).round()),
                    Colors.white,
                  ],
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ESP8266 Configuration Section
                            _buildSectionHeader(
                              'ESP8266 Configuration',
                              Icons.wifi,
                              'Configure your ESP8266 device settings',
                            ),
                            const SizedBox(height: 16),
                            
                            // IP Address Input
                            _buildIpAddressInput(),
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Auto-Discover',
                                    onPressed: _isLoading ? () {} : _handleDiscoverDevices,
                                    variant: ButtonVariant.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Reset to Default',
                                    onPressed: _resetToDefault,
                                    variant: ButtonVariant.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: 'Save Settings',
                                onPressed: _saveSettings,
                                variant: ButtonVariant.primary,
                              ),
                            ),
                            
                            // Information Section
                            _buildInfoSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpAddressInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESP8266 IP Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _espIpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Icons.computer),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'IP address is required';
              }
              if (!_deviceConfigService.isValidIpAddress(value.trim())) {
                return 'Please enter a valid IP address (e.g., 192.168.1.100)';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'This IP address will be used to send Firebase credentials to your ESP8266 device.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Device Discovery & Configuration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Use "Auto-Discover" to automatically find ESP8266 devices on your network\n'
            '• Make sure your ESP8266 device is connected to the same network as this app\n'
            '• The ESP8266 device must be running the appropriate firmware to receive credentials\n'
            '• The IP address should be the static IP assigned to your ESP8266 device\n'
            '• If auto-discovery doesn\'t work, manually enter the IP address\n'
            '• Common ESP8266 IP addresses: 192.168.1.100, 192.168.4.1 (AP mode)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
} 